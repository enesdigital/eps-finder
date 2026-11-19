# Third-party notices

## Ghostscript 10.08.0

Copyright Artifex Software, Inc. and the other copyright holders identified in the upstream source distribution. Distributed under GNU AGPL version 3; see [LICENSE](LICENSE) and the notices in the complete upstream archive.

- Release: https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/tag/gs10080
- Source: https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs10080/ghostscript-10.08.0.tar.gz
- SHA-256: `caf199e3f233f1290b27d0972d636f66c303355f2353309b7bfddf1edda06b3d`

`build-engine.py` includes upstream `base/gp_mspol.c` from `base/gp_unix.c` to enable the existing interruption polling callback on macOS. The rest of the upstream source is unchanged. Compiler options enable `CHECK_INTERRUPTS`, compile resources into the library, select PostScript/PDF output, target macOS 13, and disable CUPS, X11, OCR, fontconfig and unrelated printer drivers. Both CPU architectures are built independently and joined with `lipo`.

The complete upstream source archive, this adaptation script, application sources and tests are included in the generated release source ZIP. Bundled Ghostscript libraries link only to macOS system libraries; they do not require Homebrew or another Ghostscript installation.

## Sparkle 2.10.1

Sparkle is distributed under the MIT license and the additional third-party notices in its SDK `LICENSE` file. The unmodified full notice is bundled as `Contents/Resources/Sparkle-LICENSE.txt`. Its framework and all helper binaries support arm64 and x86_64.

- Project: https://sparkle-project.org/
- SDK: https://github.com/sparkle-project/Sparkle/releases/download/2.10.1/Sparkle-2.10.1.tar.xz
- SDK SHA-256: `1a856d2a9edb8e628de88121d7be04cf0e2167f8641650b78fca00b14244cf27`
- Source: https://github.com/sparkle-project/Sparkle/archive/refs/tags/2.10.1.tar.gz
- Source SHA-256: `cd6f47568af791c2d2bb49da6a55519b1726ecaad7dad032c9f86590953ff3a9`

The original SDK and complete corresponding Sparkle source archive are included in the full release source ZIP. `sparkle.py` verifies both archive hashes. Update signatures use a separate Ed25519 key; the private key is held in the maintainer’s login Keychain and is never distributed.
