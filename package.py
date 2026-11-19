#!/usr/bin/env python3
"""Create and verify an unsigned universal macOS installer and its source archive."""
import argparse
import hashlib
from datetime import datetime, timezone
from email.utils import format_datetime
import pathlib
import plistlib
import shutil
import subprocess
import tempfile
import xml.etree.ElementTree as ET
import zipfile
from sparkle import prepare, PUBLIC_KEY, KEYCHAIN_ACCOUNT, VERSION as SPARKLE_VERSION
from localization import LANGUAGES, load_catalogs, verify_resources, write_installer

ROOT = pathlib.Path(__file__).resolve().parent
ARCHITECTURES = ("arm64", "x86_64")
IDENTIFIER = "local.epsfinder.pkg"


def package(app, output, archive, sparkle):
    prepare(sparkle, with_source=True)
    catalogs = load_catalogs(ROOT)
    app_info = plistlib.loads((app / "Contents/Info.plist").read_bytes())
    assert app_info["SUPublicEDKey"] == PUBLIC_KEY
    assert app_info["SURequireSignedFeed"] and app_info["SUVerifyUpdateBeforeExtraction"]
    public_key = subprocess.check_output([str(sparkle / "bin/generate_keys"), "--account", KEYCHAIN_ACCOUNT, "-p"], text=True).strip()
    assert public_key == PUBLIC_KEY, "Release key differs from the public key embedded in the app"
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
        document.find("choice[@id='default']").set("title", "installer.component.title")
        ET.SubElement(document, "welcome", file="Welcome.html")
        ET.SubElement(document, "readme", file="ReadMe.html")
        ET.SubElement(document, "conclusion", file="Conclusion.html")
        tree.write(distribution, encoding="utf-8", xml_declaration=True)
        resources = work / "resources"
        resources.mkdir()
        write_installer(resources, catalogs)
        verify_resources(app, resources, catalogs)
        subprocess.run(["productbuild", "--distribution", str(distribution), "--resources", str(resources),
                        "--package-path", str(work), str(installer)], check=True)
        expanded = work / "expanded"
        subprocess.run(["pkgutil", "--expand-full", str(installer), str(expanded)], check=True)
        installed = list(expanded.glob("*/Payload/Applications/EPS Finder.app"))
        assert len(installed) == 1, "Installer must contain exactly one app at /Applications"
        payload = installed[0]
        verify_resources(payload, expanded / "Resources", catalogs)
        assert app_info["CFBundleIconFile"] == "EPSFinder.icns"
        icon = payload / "Contents/Resources/EPSFinder.icns"
        assert icon.read_bytes().startswith(b"icns")
        assert icon.read_bytes() == (app / "Contents/Resources/EPSFinder.icns").read_bytes()
        subprocess.run(["codesign", "--verify", "--deep", "--strict", str(payload)], check=True)
        binaries = [payload / "Contents/MacOS/EPSFinder",
                    *payload.glob("Contents/PlugIns/*.appex/Contents/MacOS/*"),
                    *payload.glob("Contents/PlugIns/*.appex/Contents/Frameworks/*.dylib")]
        assert len(binaries) == 5, "Expected host, two extensions, and two bundled libraries"
        for binary in binaries:
            actual = subprocess.check_output(["lipo", "-archs", str(binary)], text=True).split()
            assert set(actual) == set(ARCHITECTURES), "Missing architecture in " + str(binary)
        framework = payload / "Contents/Frameworks/Sparkle.framework/Versions/B"
        for relative in ("Sparkle", "Autoupdate", "Updater.app/Contents/MacOS/Updater",
                         "XPCServices/Installer.xpc/Contents/MacOS/Installer", "XPCServices/Downloader.xpc/Contents/MacOS/Downloader"):
            assert set(subprocess.check_output(["lipo", "-archs", str(framework / relative)], text=True).split()) == set(ARCHITECTURES)
        assert (payload / "Contents/Resources/Sparkle-LICENSE.txt").read_bytes() == (sparkle / "LICENSE").read_bytes()
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
        for relative in ("installer/postinstall", "tests/EPS-Test.eps", "assets/EPSFinder.png", "assets/ICON.md"):
            file.write(ROOT / relative, prefix + "-source/" + relative)
        for language in LANGUAGES:
            relative = "localizations/" + language + ".json"
            file.write(ROOT / relative, prefix + "-source/" + relative)
        file.write(archive, prefix + "-source/vendor/ghostscript-10.08.0.tar.gz", compress_type=zipfile.ZIP_STORED)
        for name in ("Sparkle-" + SPARKLE_VERSION + ".tar.xz", "Sparkle-" + SPARKLE_VERSION + "-source.tar.gz"):
            file.write(sparkle / name, prefix + "-source/build/sparkle/" + name, compress_type=zipfile.ZIP_STORED)
    with zipfile.ZipFile(sources) as file:
        assert file.testzip() is None, "Source ZIP is corrupt"
    signing_tool = str(sparkle / "bin/sign_update")
    signature = subprocess.check_output([signing_tool, "--account", KEYCHAIN_ACCOUNT, "-p", str(installer)], text=True).strip()
    subprocess.run([signing_tool, "--account", KEYCHAIN_ACCOUNT, "--verify", str(installer), signature], check=True)
    namespace = "http://www.andymatuschak.org/xml-namespaces/sparkle"
    ET.register_namespace("sparkle", namespace)
    document = ET.Element("rss", version="2.0")
    channel = ET.SubElement(document, "channel")
    ET.SubElement(channel, "title").text = "EPS Finder"
    ET.SubElement(channel, "link").text = "https://github.com/enesdigital/eps-finder"
    item = ET.SubElement(channel, "item")
    ET.SubElement(item, "title").text = "EPS Finder " + version
    ET.SubElement(item, "{" + namespace + "}version").text = app_info["CFBundleVersion"]
    ET.SubElement(item, "{" + namespace + "}shortVersionString").text = version
    ET.SubElement(item, "{" + namespace + "}minimumSystemVersion").text = minimum_os
    ET.SubElement(item, "pubDate").text = format_datetime(datetime.now(timezone.utc))
    ET.SubElement(item, "link").text = "https://github.com/enesdigital/eps-finder/releases/tag/v" + version
    for language in LANGUAGES:
        ET.SubElement(item, "description", {"{http://www.w3.org/XML/1998/namespace}lang": language}).text = catalogs[language]["update.releaseNotes"]
    ET.SubElement(item, "enclosure", {
        "url": "https://github.com/enesdigital/eps-finder/releases/download/v" + version + "/" + installer.name,
        "length": str(installer.stat().st_size), "type": "application/octet-stream",
        "{" + namespace + "}edSignature": signature,
        "{" + namespace + "}installationType": "package"})
    appcast = output / "appcast.xml"
    ET.ElementTree(document).write(appcast, encoding="utf-8", xml_declaration=True)
    subprocess.run([signing_tool, "--account", KEYCHAIN_ACCOUNT, str(appcast)], check=True)
    subprocess.run([signing_tool, "--account", KEYCHAIN_ACCOUNT, "--verify", str(appcast)], check=True)
    with tempfile.TemporaryDirectory(prefix="eps-finder-signature-test-") as temporary:
        changed = pathlib.Path(temporary) / "changed.xml"
        changed.write_bytes(appcast.read_bytes().replace(b"EPS Finder", b"Evil Finder", 1))
        result = subprocess.run([signing_tool, "--account", KEYCHAIN_ACCOUNT, "--verify", str(changed)], capture_output=True)
        assert result.returncode != 0, "Modified feed signature was accepted"
        changed = pathlib.Path(temporary) / "changed.pkg"
        shutil.copyfile(installer, changed)
        with changed.open("r+b") as file:
            byte = file.read(1)
            file.seek(0)
            file.write(bytes([byte[0] ^ 1]))
        result = subprocess.run([signing_tool, "--account", KEYCHAIN_ACCOUNT, "--verify", str(changed), signature], capture_output=True)
        assert result.returncode != 0, "Modified package signature was accepted"
    sums = output / (prefix + "-SHA256SUMS.txt")
    sums.write_text("".join(hashlib.sha256(path.read_bytes()).hexdigest() + "  " + path.name + "\n"
                            for path in (installer, sources, appcast)))
    print("PASS: installer payload, signatures, both architectures, five-language app/installer resources, scripts, OS requirement, source archive, signed feed/package and tamper rejection")
    print(installer)
    print(sources)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("app", nargs="?", type=pathlib.Path, default=ROOT / "build/app/EPS Finder.app")
    parser.add_argument("--output", type=pathlib.Path, default=ROOT / "dist")
    parser.add_argument("--source-archive", type=pathlib.Path,
                        default=ROOT / "build/cache/ghostscript-10.08.0.tar.gz")
    parser.add_argument("--sparkle", type=pathlib.Path, default=ROOT / "build/sparkle")
    args = parser.parse_args()
    package(args.app.resolve(), args.output.resolve(), args.source_archive.resolve(), args.sparkle.resolve())
