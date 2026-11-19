# EPS Finder

[English](README.md) · [Türkçe](README.tr.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md)

EPS thumbnails and Space-bar Quick Look previews in macOS Finder.

**Universal 2:** Intel (`x86_64`) and Apple Silicon (`arm64`). **macOS 13 or later.** Ghostscript is bundled; users do not need Homebrew, Python, Illustrator or Rosetta to run the app.

The app interface, error messages and installer pages are available in Turkish, English, German, French and Spanish. macOS selects the best match for your language preferences automatically, with English as the fallback.

Release 1.3.1 adds the approved EPS app icon, recognizes legacy `1.0` copies during cleanup, and refreshes the thumbnail worker after upgrades so Finder stops using an old extension path. The [icon source and generation prompt](assets/ICON.md) are included.

## Install

1. Download `EPS-Finder-1.3.1-universal-unsigned.pkg` from [Releases](https://github.com/enesdigital/eps-finder/releases/latest). The same package supports Intel and Apple Silicon.
2. Open the `.pkg` and follow the installer. It installs `/Applications/EPS Finder.app` and requires administrator approval.
3. Open EPS Finder once. Click **Show sample file** to reveal the bundled sample EPS in Finder.

The installer registers the Quick Look extensions for the signed-in user. Other user accounts may need to open the app once as well.

This release is **not Developer ID signed or notarized by Apple**. macOS may request user approval before opening the package. Signing and notarization remain a separate distribution step.

## Use

Select an `.eps` file in Finder and press **Space** to preview it. Finder also generates thumbnails in icon view. Enable **Show icon preview** in Finder’s view options to display them.

## Updates

EPS Finder checks GitHub for a newer stable release whenever you open the app. You can turn off **Automatically check for updates when EPS Finder opens**, or use **Check for Updates** at any time while the app is open.

When an update is available, choose **Download and Install…**. The app downloads the universal package from this repository, checks its size and GitHub-provided SHA-256 digest, then opens the macOS installer. EPS Finder quits when the installer opens so its old process does not remain running. Complete the installation with administrator approval and reopen EPS Finder. **Release Notes** opens the release page if you prefer to download manually.

Version 1.2.0 and earlier do not have an updater: install 1.3.1 once from Releases to get this feature. After installation, EPS Finder registers itself as a macOS login item, so it opens and checks for updates at each login. You can turn off **Start EPS Finder when I log in** or manage it in System Settings → General → Login Items. A setting disabled in macOS is respected. No separate background service is installed. Only the app contacts GitHub and its download servers. EPS files are never uploaded, and Quick Look extensions have no network entitlement.

The package remains unsigned and unnotarized. SHA-256 verifies download integrity; it does not replace a Developer ID signature or macOS security approval. Incomplete or mismatched downloads are discarded. GitHub rate limits and network errors can be retried later.

The installer replaces the app in `/Applications/EPS Finder.app` for both manual installs and in-app updates. Older copies with the same bundle identifier in `/Applications` or the signed-in user’s `~/Applications` are moved to Trash. Other users’ copies are checked when they next open the new app. Equal/newer versions, unrelated apps, symbolic links and EPS documents are left alone. Copies outside these standard Applications folders are not scanned. If a copy cannot be moved, the app reports that manual cleanup is needed.

## If previews do not appear

1. Make sure the file is downloaded to your Mac rather than available only as a cloud placeholder.
2. Open EPS Finder once. Search System Settings for **Extensions / Quick Look** and enable **EPS Finder — Preview** and **EPS Finder — Thumbnails**. The setting’s location varies by macOS version.
3. Check Finder’s icon-preview option. Damaged EPS files or files requiring external resources may not render.

## Processing and limits

The Quick Look extension converts EPS to a temporary PDF inside its sandbox using Ghostscript’s `SAFER` mode. Processing is local. The original EPS is not modified, and temporary files are cleaned up. The Quick Look extensions have no network entitlement or broad file-access permissions. The host app uses the network only for update checks and downloads.

- Input limit: 256 MB. Generated PDF limit: 64 MB.
- Processing timeout: 8 seconds for thumbnails, 15 seconds for previews.
- Fonts that are not embedded may change the appearance; external resources may prevent rendering.
- Previews are not a substitute for print or colour-proof approval.

To uninstall, move `/Applications/EPS Finder.app` to the Trash. Remove any older copy in your user’s Applications folder too.

## Build

Building the universal release requires an **Apple Silicon Mac, Rosetta 2, Apple Command Line Tools and Python 3.9+**. These are developer requirements, not requirements for people installing the package.

```sh
python3 build-engine.py
python3 build.py
python3 package.py
```

The first command downloads the official Ghostscript 10.08.0 archive, verifies its pinned SHA-256, builds each architecture separately, then joins them with `lipo`. The second builds the app, applies local ad-hoc signatures and runs renderer checks for both architectures. The last creates the installer, full source ZIP and checksum file in `dist/`, then expands and validates the installer.

`build/` and `dist/` are ignored by Git. The full Ghostscript archive is included in the release source ZIP rather than Git history.

For another build location:

```sh
python3 build-engine.py /private/tmp/eps-finder/engine --source-archive /path/to/ghostscript-10.08.0.tar.gz
python3 build.py /private/tmp/eps-finder/app /private/tmp/eps-finder/engine
python3 package.py '/private/tmp/eps-finder/app/EPS Finder.app' --source-archive /path/to/ghostscript-10.08.0.tar.gz
```

When building from the release source ZIP, use `--source-archive vendor/ghostscript-10.08.0.tar.gz` to use the included archive.

## Validation

The build also tests native macOS localization on both architectures: all five languages, localized app and extension strings, error messages, regional language codes, ordered preferences and English fallback. Translations are maintained in `localizations/*.json` and compiled into standard `.lproj` resources. The installer uses localized welcome, readme and conclusion pages.

The renderer checks cover ASCII and DOS binary EPS, bounding-box cropping, Unicode and percent signs in paths, unchanged originals, invalid input, blocked unrelated file reads, timeout and recovery. Both arm64 and x86_64 checks passed; the Intel code was executed through Rosetta on Apple Silicon.

The updater self-check covers numeric version ordering, downgrade prevention, malformed metadata, trusted repository URLs, package size/type, SHA-256 corruption and safe selection of older app copies. Run a live check and download (without installing) with:

```sh
build/app/update-self-check --live 1.0.0 --download
```

Publish stable releases as `vMAJOR.MINOR.PATCH` with `EPS-Finder-MAJOR.MINOR.PATCH-universal-unsigned.pkg`. The updater requires GitHub’s `sha256:` asset digest and ignores drafts, prereleases and downgrades. If package signing or naming changes, update this convention in `Update.m` too.

After installation, test actual Retina thumbnail generation with:

```sh
build/app/check-finder "$PWD/tests/EPS-Test.eps" /private/tmp/eps-finder-thumbnail.png
```

This checks the size and alignment of the included dark-background sample. Physical Intel hardware, the oldest supported macOS and the complete interactive Installer flow still require testing.

## License and release files

AGPL-3.0-or-later; see [LICENSE](LICENSE) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). Share the generated source ZIP alongside the binary package.

[Releases](https://github.com/enesdigital/eps-finder/releases/latest) contains the installer, `EPS-Finder-1.3.1-source.zip` and a `SHA256SUMS` file. Use this explicit source ZIP for the complete Ghostscript sources; GitHub’s automatically generated “Source code” archives do not include the bundled upstream archive.
