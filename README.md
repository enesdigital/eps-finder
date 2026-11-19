# EPS Finder

[English](README.md) · [Türkçe](README.tr.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md)

EPS thumbnails and Space-bar Quick Look previews in macOS Finder.

**Universal 2:** Intel (`x86_64`) and Apple Silicon (`arm64`). **macOS 13 or later.** Ghostscript is bundled; users do not need Homebrew, Python, Illustrator or Rosetta to run the app.

The app interface, error messages and installer pages are available in Turkish, English, German, French and Spanish. macOS selects the best match for your language preferences automatically, with English as the fallback.

Release 1.4.0 adds verified in-app updates with Sparkle. [EPS icon](assets/ICON.md).

## Install

1. Download `EPS-Finder-1.4.1-universal-unsigned.pkg` from [Releases](https://github.com/enesdigital/eps-finder/releases/latest). The same package supports Intel and Apple Silicon.
2. Open the `.pkg` and follow the installer. It installs `/Applications/EPS Finder.app` and requires administrator approval.
3. Open EPS Finder once. Click **Show sample file** to reveal the bundled sample EPS in Finder.

The installer registers the Quick Look extensions for the signed-in user. Other user accounts may need to open the app once as well.

This release is **not Developer ID signed or notarized by Apple**. macOS may request user approval before opening the package. Signing and notarization remain a separate distribution step.

## Use

Select an `.eps` file in Finder and press **Space** to preview it. Finder also generates thumbnails in icon view. Enable **Show icon preview** in Finder’s view options to display them.

## Updates

EPS Finder uses Sparkle 2.10.1 to download, verify and install updates inside the app. Choose **Check for Updates**, **Install Update**, then **Install and Relaunch**. macOS may ask for administrator approval; EPS Finder restarts automatically after installation. There is no need to open a downloaded package yourself. **Release Notes** opens GitHub for manual downloads.

Both the update feed and package must have valid Ed25519 signatures matching the public key embedded in the app. Invalid or modified updates are rejected. The publishing private key stays in the maintainer’s macOS Keychain. These update signatures are separate from Apple Developer ID signing: the first-install package is still unsigned and unnotarized.

**Upgrading from 1.3.1 or earlier:** download and install 1.4.0 once from Releases. The old updater cannot be repaired remotely. Subsequent updates use the new in-app installer.

Automatic checks run at every app launch and periodically while the app remains open. Disable **Automatically check for updates** to stop them; manual checks remain available. After installation the app is registered to start at login. You can change this in EPS Finder or System Settings → General → Login Items. Existing choices are preserved.

Only the app contacts GitHub and its download servers. EPS documents are never uploaded. Quick Look extensions have no network entitlement. No permanent privileged helper is installed; Sparkle requests administrator authorization when installing an update.

The installer replaces `/Applications/EPS Finder.app`. Older copies with the same bundle identifier in `/Applications` and the signed-in user’s `~/Applications` move to Trash. Equal/newer copies, unrelated apps, symbolic links and EPS files are preserved. Copies elsewhere are not scanned. If cleanup fails, the app asks you to remove the old copy manually.

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

The first command downloads the official Ghostscript 10.08.0 archive, verifies its pinned SHA-256, builds each architecture separately, then joins them with `lipo`. The second downloads the pinned Sparkle SDK, builds the app, applies local ad-hoc signatures and runs renderer checks for both architectures. The last downloads the pinned Sparkle source archive, creates the installer, signed update feed, full source ZIP and checksum file in `dist/`, then expands and validates the installer.

`build/` and `dist/` are ignored by Git. The full Ghostscript and Sparkle archives are included in the release source ZIP rather than Git history.

For another build location:

```sh
python3 build-engine.py /private/tmp/eps-finder/engine --source-archive /path/to/ghostscript-10.08.0.tar.gz
python3 build.py /private/tmp/eps-finder/app /private/tmp/eps-finder/engine
python3 package.py '/private/tmp/eps-finder/app/EPS Finder.app' --source-archive /path/to/ghostscript-10.08.0.tar.gz
```

When building from the release source ZIP, use `--source-archive vendor/ghostscript-10.08.0.tar.gz` for Ghostscript. The included `build/sparkle/` archives are used automatically without downloading Sparkle again. `build.py` and `package.py` accept `--sparkle /path/to/sdk` for another SDK/cache location.

## Validation

The build also tests native macOS localization on both architectures: all five languages, localized app and extension strings, error messages, regional language codes, ordered preferences and English fallback. Translations are maintained in `localizations/*.json` and compiled into standard `.lproj` resources. The installer uses localized welcome, readme and conclusion pages.

The renderer checks cover ASCII and DOS binary EPS, bounding-box cropping, Unicode and percent signs in paths, unchanged originals, invalid input, blocked unrelated file reads, timeout and recovery. Both arm64 and x86_64 checks passed; the Intel code was executed through Rosetta on Apple Silicon.

The maintenance self-check covers numeric and legacy versions and safe selection of older app copies. Packaging verifies both architectures in Sparkle’s helpers, embedded notices, the package signature and the signed update feed. It also modifies copies of the package and feed and confirms that both signatures are rejected.

Release signing requires the matching private key in the macOS login Keychain under account `eps-finder`. A new maintainer must generate their own key with Sparkle’s `bin/generate_keys --account eps-finder` and update `PUBLIC_KEY` in `sparkle.py` before distributing their first build. Existing installations only trust the embedded public key. Never commit or include a private key in release archives.

Publish stable releases as `vMAJOR.MINOR.PATCH`, increasing both the display version and `CFBundleVersion` in `build.py`. Upload all generated `dist/` assets, including `appcast.xml`, together. The feed URL follows GitHub’s latest stable release. `package.py` signs the package and feed using Sparkle’s official tool; modifying either afterward requires re-signing. Verify uploaded SHA-256 values before publishing the release.

After installation, test actual Retina thumbnail generation with:

```sh
build/app/check-finder "$PWD/tests/EPS-Test.eps" /private/tmp/eps-finder-thumbnail.png
```

This checks the size and alignment of the included dark-background sample. A package-installed 1.3.2 test build successfully checked a signed local feed, downloaded and verified the 1.4.0 package, installed it in-app and relaunched as 1.4.0. Login/update preferences were preserved and the real Retina thumbnail check passed after the upgrade. The shipping build uses the GitHub HTTPS feed; the local test feed is not included. Physical Intel hardware, macOS 13 and a real logout/reboot still require testing. Intel checks run through Rosetta on Apple Silicon.

## License and release files

AGPL-3.0-or-later; see [LICENSE](LICENSE) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). Share the generated source ZIP alongside the binary package.

[Releases](https://github.com/enesdigital/eps-finder/releases/latest) contains the installer, `EPS-Finder-1.4.1-source.zip` and a `SHA256SUMS` file. Use this explicit source ZIP for the complete Ghostscript and Sparkle sources; GitHub’s automatically generated “Source code” archives do not include the bundled upstream archive.
