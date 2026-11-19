#!/usr/bin/env python3
"""Create and verify an unsigned universal macOS installer and its source archive."""
import argparse
import hashlib
import pathlib
import plistlib
import shutil
import subprocess
import tempfile
import xml.etree.ElementTree as ET
import zipfile

ROOT = pathlib.Path(__file__).resolve().parent
ARCHITECTURES = ("arm64", "x86_64")
IDENTIFIER = "local.epsfinder.pkg"


def package(app, output, archive):
    app_info = plistlib.loads((app / "Contents/Info.plist").read_bytes())
    assert app_info["CFBundleIdentifier"] == "local.epsfinder", "Unexpected application"
    version = app_info["CFBundleShortVersionString"]
    minimum_os = app_info["LSMinimumSystemVersion"]
    subprocess.run(["codesign", "--verify", "--deep", "--strict", str(app)], check=True)
    assert archive.is_file(), "Pass the original Ghostscript source archive with --source-archive"
    assert hashlib.sha256(archive.read_bytes()).hexdigest() == \
        "caf199e3f233f1290b27d0972d636f66c303355f2353309b7bfddf1edda06b3d", "Unexpected Ghostscript source archive"
    output.mkdir(parents=True, exist_ok=True)
    prefix = "EPS-Finder-" + version
    installer = output / (prefix + "-universal-unsigned.pkg")
    sources = output / (prefix + "-source.zip")
    with tempfile.TemporaryDirectory(prefix="eps-finder-package-") as temporary:
        work = pathlib.Path(temporary)
        staged = work / "root/Applications/EPS Finder.app"
        staged.parent.mkdir(parents=True)
        subprocess.run(["ditto", "--norsrc", str(app), str(staged)], check=True)
        scripts = work / "scripts"
        scripts.mkdir()
        shutil.copyfile(ROOT / "installer/postinstall", scripts / "postinstall")
        (scripts / "postinstall").chmod(0o755)
        subprocess.run(["/bin/sh", "-n", str(scripts / "postinstall")], check=True)
        components = work / "components.plist"
        subprocess.run(["pkgbuild", "--analyze", "--root", str(work / "root"), str(components)], check=True)
        settings = plistlib.loads(components.read_bytes())
        for bundle in settings:
            bundle.update(BundleIsRelocatable=False, BundleIsVersionChecked=True,
                          BundleHasStrictIdentifier=True, BundleOverwriteAction="upgrade")
        components.write_bytes(plistlib.dumps(settings))
        component = work / "EPSFinder-component.pkg"
        subprocess.run(["pkgbuild", "--root", str(work / "root"), "--install-location", "/",
                        "--component-plist", str(components), "--scripts", str(scripts),
                        "--identifier", IDENTIFIER, "--version", version, "--ownership", "recommended",
                        "--compression", "legacy", str(component)], check=True)
        requirements = work / "requirements.plist"
        requirements.write_bytes(plistlib.dumps({"arch": list(ARCHITECTURES), "os": [minimum_os]}))
        distribution = work / "Distribution.xml"
        subprocess.run(["productbuild", "--synthesize", "--product", str(requirements),
                        "--package", str(component), str(distribution)], check=True)
        tree = ET.parse(distribution)
        document = tree.getroot()
        ET.SubElement(document, "title").text = "EPS Finder"
        ET.SubElement(document, "domains", enable_anywhere="false", enable_currentUserHome="false",
                      enable_localSystem="true")
        ET.SubElement(document, "readme", file="ReadMe.html")
        tree.write(distribution, encoding="utf-8", xml_declaration=True)
        resources = work / "resources"
        resources.mkdir()
        (resources / "ReadMe.html").write_text(
            '<!doctype html><html lang="tr"><meta charset="utf-8"><body>'
            '<h1>EPS Finder</h1><p>Intel ve Apple Silicon · macOS 13 veya sonrası</p>'
            '<p>Finder’da EPS küçük resimleri ve boşluk tuşuyla önizleme.</p>'
            '<p>Kurulum konumu: <b>/Applications/EPS Finder.app</b>. '
            'Ghostscript uygulamaya dahildir; ayrıca bir araç kurmanız gerekmez.</p>'
            '<p>Kurulumdan sonra EPS Finder uygulamasını açıp “Örnek dosyayı göster” '
            'düğmesiyle deneyebilirsiniz. Gerekirse Sistem Ayarları’ndan EPS Finder '
            'Hızlı Bakış uzantılarını etkinleştirin.</p>'
            '<p>Bu paket Developer ID imzası ve Apple notarizasyonu içermez. '
            'macOS kuruluma izin vermek için kullanıcı onayı isteyebilir.</p>'
            '<p>Dosyalar yerel işlenir. Kaynak EPS değiştirilmez. '
            'Ghostscript ve bu uygulama AGPLv3 kapsamındadır; kaynak arşivi paketle birlikte sağlanır.</p>'
            '</body></html>', encoding="utf-8")
        subprocess.run(["productbuild", "--distribution", str(distribution), "--resources", str(resources),
                        "--package-path", str(work), str(installer)], check=True)
        expanded = work / "expanded"
        subprocess.run(["pkgutil", "--expand-full", str(installer), str(expanded)], check=True)
        installed = list(expanded.glob("*/Payload/Applications/EPS Finder.app"))
        assert len(installed) == 1, "Installer must contain exactly one app at /Applications"
        payload = installed[0]
        subprocess.run(["codesign", "--verify", "--deep", "--strict", str(payload)], check=True)
        binaries = [payload / "Contents/MacOS/EPSFinder",
                    *payload.glob("Contents/PlugIns/*.appex/Contents/MacOS/*"),
                    *payload.glob("Contents/PlugIns/*.appex/Contents/Frameworks/*.dylib")]
        assert len(binaries) == 5, "Expected host, two extensions, and two bundled libraries"
        for binary in binaries:
            actual = subprocess.check_output(["lipo", "-archs", str(binary)], text=True).split()
            assert set(actual) == set(ARCHITECTURES), "Missing architecture in " + str(binary)
        packaged_distribution = ET.parse(expanded / "Distribution").getroot()
        host_architectures = packaged_distribution.find("options").get("hostArchitectures")
        assert set(host_architectures.split(",")) == set(ARCHITECTURES)
        assert b"13.0" in (expanded / "Distribution").read_bytes(), "Missing minimum OS requirement"
        packaged_scripts = list(expanded.glob("*/Scripts/postinstall"))
        assert len(packaged_scripts) == 1 and packaged_scripts[0].stat().st_mode & 0o111
        assert packaged_scripts[0].read_bytes() == (ROOT / "installer/postinstall").read_bytes()
    with zipfile.ZipFile(sources, "w", compression=zipfile.ZIP_DEFLATED) as file:
        for source in sorted(ROOT.iterdir()):
            if source.is_file() and (source.suffix in (".m", ".h", ".py", ".md") or
                                     source.name in ("LICENSE", ".gitignore")):
                file.write(source, prefix + "-source/" + source.name)
        for relative in ("installer/postinstall", "tests/EPS-Test.eps"):
            file.write(ROOT / relative, prefix + "-source/" + relative)
        file.write(archive, prefix + "-source/vendor/ghostscript-10.08.0.tar.gz",
                   compress_type=zipfile.ZIP_STORED)
    with zipfile.ZipFile(sources) as file:
        assert file.testzip() is None, "Source ZIP is corrupt"
    sums = output / (prefix + "-SHA256SUMS.txt")
    sums.write_text("".join(hashlib.sha256(path.read_bytes()).hexdigest() + "  " + path.name + "\n"
                            for path in (installer, sources)))
    print("PASS: installer payload, signatures, both architectures, scripts, OS requirement, source archive")
    print(installer)
    print(sources)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("app", nargs="?", type=pathlib.Path, default=ROOT / "build/app/EPS Finder.app")
    parser.add_argument("--output", type=pathlib.Path, default=ROOT / "dist")
    parser.add_argument("--source-archive", type=pathlib.Path,
                        default=ROOT / "build/cache/ghostscript-10.08.0.tar.gz")
    args = parser.parse_args()
    package(args.app.resolve(), args.output.resolve(), args.source_archive.resolve())
