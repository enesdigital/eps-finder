"""Pinned Sparkle SDK and release signing settings. Private keys stay in Keychain."""
import hashlib
import pathlib
import shutil
import subprocess
import urllib.request

VERSION = "2.10.1"
PUBLIC_KEY = "KBOWf1RZA52ziFSF6y5MXmqES4V3pg0OEA3E5RLzt1Q="
KEYCHAIN_ACCOUNT = "eps-finder"
FEED_URL = "https://github.com/enesdigital/eps-finder/releases/latest/download/appcast.xml"
SDK_SHA256 = "1a856d2a9edb8e628de88121d7be04cf0e2167f8641650b78fca00b14244cf27"
SOURCE_SHA256 = "cd6f47568af791c2d2bb49da6a55519b1726ecaad7dad032c9f86590953ff3a9"


def download(path, url, digest):
    if not path.exists():
        path.parent.mkdir(parents=True, exist_ok=True)
        partial = path.with_suffix(".download")
        try:
            with urllib.request.urlopen(url, timeout=60) as response, partial.open("wb") as file:
                shutil.copyfileobj(response, file)
            assert hashlib.sha256(partial.read_bytes()).hexdigest() == digest, "Sparkle download checksum mismatch"
            partial.replace(path)
        finally:
            partial.unlink(missing_ok=True)
    assert hashlib.sha256(path.read_bytes()).hexdigest() == digest, "Sparkle archive checksum mismatch"
    return path


def prepare(directory, with_source=False):
    archive = download(directory / ("Sparkle-" + VERSION + ".tar.xz"),
                       "https://github.com/sparkle-project/Sparkle/releases/download/" + VERSION + "/Sparkle-" + VERSION + ".tar.xz", SDK_SHA256)
    if not (directory / "Sparkle.framework").exists():
        subprocess.run(["/usr/bin/tar", "-xf", str(archive), "-C", str(directory)], check=True)
    subprocess.run(["codesign", "--verify", "--deep", "--strict", str(directory / "Sparkle.framework")], check=True)
    if with_source:
        download(directory / ("Sparkle-" + VERSION + "-source.tar.gz"),
                 "https://github.com/sparkle-project/Sparkle/archive/refs/tags/" + VERSION + ".tar.gz", SOURCE_SHA256)
    return directory
