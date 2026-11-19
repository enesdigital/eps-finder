#!/usr/bin/env python3
"""Usage: build.py [OUTPUT_DIRECTORY] [UNIVERSAL_ENGINE_DIRECTORY]."""
import argparse
import pathlib
import plistlib
import shutil
import subprocess
import sys
from localization import LANGUAGES, load_catalogs, write_bundle

source = pathlib.Path(__file__).resolve().parent
catalogs = load_catalogs(source)
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("output", nargs="?", type=pathlib.Path, default=source / "build/app")
parser.add_argument("engine", nargs="?", type=pathlib.Path, default=source / "build/engine")
args = parser.parse_args()
destination = args.output.resolve()
app = destination / "EPS Finder.app"
contents = app / "Contents"
engine = args.engine.resolve()
headers = engine / "arm64/ghostscript-10.08.0"
library = engine / "libgs.dylib"
license_file = headers / "LICENSE"
if not library.is_file() or not license_file.is_file():
    sys.exit("Run build-engine.py to build the universal Ghostscript library first.")
assert set(subprocess.check_output(["lipo", "-archs", str(library)], text=True).split()) == {"arm64", "x86_64"}
prepared_library = destination / "engine/libgs.dylib"
prepared_library.parent.mkdir(parents=True, exist_ok=True)
shutil.copyfile(library, prepared_library)
subprocess.run(["install_name_tool", "-id", "@rpath/libgs.dylib", str(prepared_library)], check=True)
subprocess.run(["codesign", "--force", "--sign", "-", str(prepared_library)], check=True)

def write_plist(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(plistlib.dumps(value))

def info(identifier, executable, kind):
    return {
        "CFBundleIdentifier": identifier,
        "CFBundleExecutable": executable,
        "CFBundleName": "EPS Finder",
        "CFBundleDisplayName": "EPS Finder",
        "CFBundlePackageType": kind,
        "CFBundleInfoDictionaryVersion": "6.0",
        "CFBundleShortVersionString": "1.3.1",
        "CFBundleVersion": "7",
        "CFBundleDevelopmentRegion": "en",
        "CFBundleLocalizations": list(LANGUAGES),
        "LSMinimumSystemVersion": "13.0",
    }

def compile_file(filename, output, frameworks, common=False, rpath="@loader_path/../Frameworks", extra=()):
    output.parent.mkdir(parents=True, exist_ok=True)
    command = ["xcrun", "clang", "-arch", "arm64", "-arch", "x86_64",
               "-fobjc-arc", "-fblocks", "-O2", "-Wall", "-Wextra",
               "-Wno-unused-parameter", "-mmacosx-version-min=13.0", str(source / filename)]
    command += [str(source / name) for name in extra]
    if common:
        command += [str(source / "Render.m"), "-I", str(headers / "psi"), "-I", str(headers / "base"),
                    str(prepared_library), "-Wl,-rpath," + rpath]
    for framework in frameworks:
        command += ["-framework", framework]
    subprocess.run(command + ["-o", str(output)], check=True)

entitlements = destination / "build-entitlements"
entitlements.mkdir(parents=True, exist_ok=True)
sandbox = {"com.apple.security.app-sandbox": True,
           "com.apple.security.files.user-selected.read-only": True}
write_plist(entitlements / "extension.plist", sandbox)

app_info = info("local.epsfinder", "EPSFinder", "APPL")
app_info.update({"NSPrincipalClass": "NSApplication", "LSApplicationCategoryType": "public.app-category.graphics-design",
                 "LSFileQuarantineEnabled": True, "CFBundleIconFile": "EPSFinder.icns"})
write_plist(contents / "Info.plist", app_info)
compile_file("App.m", contents / "MacOS/EPSFinder", ["AppKit", "CoreServices", "ServiceManagement"], extra=("Update.m", "Maintenance.m"))

resources = contents / "Resources"
resources.mkdir(parents=True, exist_ok=True)
iconset = destination / "EPSFinder.iconset"
iconset.mkdir(parents=True, exist_ok=True)
for size in (16, 32, 128, 256, 512):
    for scale in (1, 2):
        name = "icon_" + str(size) + "x" + str(size) + ("@2x" if scale == 2 else "") + ".png"
        subprocess.run(["sips", "-z", str(size * scale), str(size * scale), str(source / "assets/EPSFinder.png"),
                        "--out", str(iconset / name)], check=True, stdout=subprocess.DEVNULL)
subprocess.run(["iconutil", "-c", "icns", str(iconset), "-o", str(resources / "EPSFinder.icns")], check=True)
write_bundle(contents, catalogs)
shutil.copyfile(license_file, resources / "Ghostscript-COPYING.txt")
shutil.copyfile(source / "tests/EPS-Test.eps", resources / "EPS-Test.eps")
(resources / "Ghostscript.txt").write_text(
    "Ghostscript 10.08.0 by Artifex Software, Inc.; upstream gp_mspol.c enables polling on macOS.\n"
    "Built with CHECK_INTERRUPTS, compiled-in resources, PDF/PostScript output, and no CUPS/X11/fontconfig.\n"
    "License: GNU AGPL version 3 (see Ghostscript-COPYING.txt).\n"
    "Upstream source: https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/tag/gs10080\n"
    "Universal arm64 + x86_64 build. Corresponding source is included in the release source archive.\n")
for name, point, principal, filename in [
    ("Preview", "preview", "EPSPreviewProvider", "Preview.m"),
    ("Thumbnail", "thumbnail", "EPSThumbnailProvider", "Thumbnail.m"),
]:
    extension = contents / "PlugIns" / (name + ".appex")
    extension_info = info("local.epsfinder." + name.lower(), name, "XPC!")
    display_key = "extension." + name.lower() + ".name"
    extension_info["CFBundleDisplayName"] = catalogs["en"][display_key]
    attributes = {"QLSupportedContentTypes": ["com.adobe.encapsulated-postscript"]}
    if name == "Preview":
        attributes["QLIsDataBasedPreview"] = True
    else:
        attributes["QLThumbnailMinimumDimension"] = 0
    extension_info["NSExtension"] = {
        "NSExtensionPointIdentifier": "com.apple.quicklook." + point,
        "NSExtensionPrincipalClass": principal,
        "NSExtensionAttributes": attributes,
    }
    write_plist(extension / "Contents/Info.plist", extension_info)
    write_bundle(extension / "Contents", catalogs, display_key)
    compile_file(filename, extension / "Contents/MacOS" / name,
                 ["AppKit", "QuickLookUI", "QuickLookThumbnailing", "PDFKit", "UniformTypeIdentifiers"], True)
    bundled_library = extension / "Contents/Frameworks/libgs.dylib"
    bundled_library.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(prepared_library, bundled_library)
    subprocess.run(["codesign", "--force", "--sign", "-", "--entitlements",
                    str(entitlements / "extension.plist"), str(extension)], check=True)

subprocess.run(["codesign", "--force", "--sign", "-", str(app)], check=True)
subprocess.run(["codesign", "--verify", "--deep", "--strict", str(app)], check=True)
for binary in [contents / "MacOS/EPSFinder", *contents.glob("PlugIns/*.appex/Contents/MacOS/*"),
               *contents.glob("PlugIns/*.appex/Contents/Frameworks/*.dylib")]:
    assert set(subprocess.check_output(["lipo", "-archs", str(binary)], text=True).split()) == {"arm64", "x86_64"}, str(binary)
compile_file("Test.m", destination / "render-self-check", ["Foundation", "CoreGraphics", "PDFKit"], True,
             str(prepared_library.parent))
for architecture in ("arm64", "x86_64"):
    print("Running renderer self-check: " + architecture, flush=True)
    subprocess.run(["arch", "-" + architecture, str(destination / "render-self-check")], check=True, timeout=40)
compile_file("CheckFinder.m", destination / "check-finder",
             ["Foundation", "QuickLookThumbnailing", "ImageIO", "UniformTypeIdentifiers", "CoreGraphics"])
test_contents = destination / "LocalizationTests.app/Contents"
write_plist(test_contents / "Info.plist", info("local.epsfinder.localization-tests", "LocalizationTests", "APPL"))
write_bundle(test_contents, catalogs)
test_binary = test_contents / "MacOS/LocalizationTests"
compile_file("LocalizationTest.m", test_binary, ["Foundation", "CoreGraphics"], True, str(prepared_library.parent))
cases = [(language, [language]) for language in LANGUAGES]
cases += [("tr", ["tr-TR"]), ("en", ["en-GB"]), ("de", ["de-CH"]), ("fr", ["fr-CA"]),
          ("es", ["es-MX"]), ("en", ["ja"]), ("de", ["ja", "de-DE"])]
for architecture in ("arm64", "x86_64"):
    for language, preferences in cases:
        apple_languages = "(" + ",".join('"' + value + '"' for value in preferences) + ")"
        subprocess.run(["arch", "-" + architecture, str(test_binary), language,
                        catalogs[language]["app.showSample"], catalogs[language]["error.invalidInput"],
                        str(app), catalogs[language]["update.check"], catalogs[language]["startup.automatic"],
                        "-AppleLanguages", apple_languages], check=True, timeout=10)
print("PASS: five languages, regional variants, ordered preferences and English fallback on both architectures")
compile_file("UpdateTest.m", destination / "update-self-check", ["Foundation", "CoreServices", "ServiceManagement"], extra=("Update.m", "Maintenance.m"))
for architecture in ("arm64", "x86_64"):
    subprocess.run(["arch", "-" + architecture, str(destination / "update-self-check")], check=True, timeout=15)
print(app)
