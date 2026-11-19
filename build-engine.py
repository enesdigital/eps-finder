#!/usr/bin/env python3
"""Build the bundled Ghostscript library for Intel and Apple Silicon."""
import argparse
import hashlib
import os
import pathlib
import platform
import shutil
import subprocess
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parent
VERSION = "10.08.0"
SHA256 = "caf199e3f233f1290b27d0972d636f66c303355f2353309b7bfddf1edda06b3d"
URL = "https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs10080/ghostscript-10.08.0.tar.gz"
ARCHITECTURES = ("arm64", "x86_64")


def build(output, archive):
    if platform.machine() != "arm64":
        raise SystemExit("The universal release build requires an Apple Silicon Mac with Rosetta 2.")
    subprocess.run(["arch", "-x86_64", "/usr/bin/true"], check=True)
    if not archive.exists():
        archive.parent.mkdir(parents=True, exist_ok=True)
        partial = archive.with_suffix(".download")
        try:
            with urllib.request.urlopen(URL, timeout=60) as response, partial.open("wb") as file:
                shutil.copyfileobj(response, file)
            if hashlib.sha256(partial.read_bytes()).hexdigest() != SHA256:
                raise RuntimeError("Ghostscript download checksum does not match.")
            partial.replace(archive)
        finally:
            partial.unlink(missing_ok=True)
    if hashlib.sha256(archive.read_bytes()).hexdigest() != SHA256:
        raise SystemExit("Ghostscript archive checksum does not match the pinned release.")
    output.mkdir(parents=True, exist_ok=True)
    environment = dict(os.environ, PATH="/usr/bin:/bin:/usr/sbin:/sbin")
    libraries = []
    for architecture in ARCHITECTURES:
        directory = output / architecture
        engine = directory / ("ghostscript-" + VERSION)
        if not engine.exists():
            directory.mkdir(parents=True, exist_ok=True)
            # Only the exact archive verified above is extracted.
            subprocess.run(["/usr/bin/tar", "-xzf", str(archive), "-C", str(directory)], check=True)
        source = engine / "base/gp_unix.c"
        text = source.read_text()
        include = '#include "gp_mspol.c"'
        if include not in text:
            source.write_text(text + '\n/* Enable upstream interruption polling on macOS. */\n' + include + '\n')
        host = ("aarch64" if architecture == "arm64" else "x86_64") + "-apple-darwin"
        flags = "-O2 -DCHECK_INTERRUPTS -mmacosx-version-min=13.0"
        commands = [[
            "./configure", "--build=" + host, "--host=" + host,
            "--disable-cups", "--without-x", "--without-tesseract", "--disable-gtk",
            "--disable-dbus", "--disable-fontconfig", "--without-libidn", "--without-libpaper",
            "--without-ijs", "--disable-contrib", "--with-drivers=PS", "--enable-mkromfs-quiet",
            "CC=clang -arch " + architecture, "CXX=clang++ -arch " + architecture,
            "CFLAGS=" + flags, "CXXFLAGS=" + flags, "LDFLAGS=-mmacosx-version-min=13.0",
        ], ["make", "-j6", "so"]]
        log = directory / "build.log"
        print("Building Ghostscript for " + architecture + "; log: " + str(log), flush=True)
        with log.open("w") as file:
            for command in commands:
                try:
                    subprocess.run(command, cwd=engine, env=environment, stdout=file,
                                   stderr=subprocess.STDOUT, check=True)
                except subprocess.CalledProcessError:
                    file.flush()
                    print("\n".join(log.read_text(errors="replace").splitlines()[-25:]))
                    raise
        library = engine / "sobin/libgs.dylib"
        subprocess.run(["lipo", "-verify_arch", architecture, str(library)], check=True)
        dependencies = subprocess.check_output(["otool", "-L", str(library)], text=True)
        for line in dependencies.splitlines()[2:]:
            assert line.strip().startswith("/usr/lib/"), "Unexpected external library: " + line
        libraries.append(library)
    universal = output / "libgs.dylib"
    subprocess.run(["lipo", "-create", *map(str, libraries), "-output", str(universal)], check=True)
    subprocess.run(["install_name_tool", "-id", "@rpath/libgs.dylib", str(universal)], check=True)
    actual = subprocess.check_output(["lipo", "-archs", str(universal)], text=True).split()
    assert set(actual) == set(ARCHITECTURES), "Universal library is missing an architecture"
    print(universal)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", nargs="?", type=pathlib.Path, default=ROOT / "build/engine")
    parser.add_argument("--source-archive", type=pathlib.Path,
                        default=ROOT / "build/cache/ghostscript-10.08.0.tar.gz")
    args = parser.parse_args()
    build(args.output.resolve(), args.source_archive.resolve())
