"""Generate native macOS bundle and Installer resources from one set of translations."""
import html
import json
import plistlib
import re

LANGUAGES = ("en", "tr", "de", "fr", "es")
PAGES = {
    "Welcome.html": ("installer.welcome.title", ("installer.welcome.description", "installer.requirements")),
    "ReadMe.html": ("installer.readme.title", ("installer.location", "installer.dependencies", "installer.firstUse",
                    "installer.extensions", "installer.unsigned", "installer.privacy", "installer.license")),
    "Conclusion.html": ("installer.conclusion.title", ("installer.conclusion.body", "installer.privacy")),
}


def load_catalogs(root):
    catalogs = {language: json.loads((root / "localizations" / (language + ".json")).read_text())
                for language in LANGUAGES}
    keys = set(catalogs["en"])
    for language, strings in catalogs.items():
        assert set(strings) == keys, "Incomplete localization: " + language
        assert all(isinstance(value, str) and value.strip() for value in strings.values()), language
    code = "\n".join((root / name).read_text() for name in ("App.m", "Render.m"))
    used = set(re.findall(r'(?:NSLocalizedString|EPSFailure)\(@"([^"]+)"', code))
    assert used <= keys, "Missing runtime strings: " + str(used - keys)
    return catalogs


def write_strings(path, values):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(plistlib.dumps(values, fmt=plistlib.FMT_BINARY))


def write_bundle(contents, catalogs, display_name_key=None):
    for language, strings in catalogs.items():
        directory = contents / "Resources" / (language + ".lproj")
        write_strings(directory / "Localizable.strings", strings)
        if display_name_key:
            write_strings(directory / "InfoPlist.strings", {"CFBundleDisplayName": strings[display_name_key]})


def write_installer(resources, catalogs):
    for language, strings in catalogs.items():
        directory = resources / (language + ".lproj")
        write_strings(directory / "Localizable.strings", {"installer.component.title": strings["installer.component.title"]})
        for filename, (title, paragraphs) in PAGES.items():
            page = ('<!doctype html><html lang="' + language + '"><head><meta charset="utf-8">'
                    '<title>EPS Finder</title><style>body{font-family:-apple-system,sans-serif;'
                    'font-size:13px;line-height:1.45}h1{font-size:22px}</style></head><body><h1>'
                    + html.escape(strings[title]) + '</h1>'
                    + ''.join('<p>' + html.escape(strings[key]) + '</p>' for key in paragraphs)
                    + '</body></html>')
            (directory / filename).write_text(page, encoding="utf-8")


def verify_resources(app, resources, catalogs):
    bundles = [(app, None), (app / "Contents/PlugIns/Preview.appex", "extension.preview.name"),
               (app / "Contents/PlugIns/Thumbnail.appex", "extension.thumbnail.name")]
    for bundle, display_key in bundles:
        contents = bundle / "Contents"
        info = plistlib.loads((contents / "Info.plist").read_bytes())
        assert info["CFBundleDevelopmentRegion"] == "en"
        assert set(info["CFBundleLocalizations"]) == set(LANGUAGES)
        for language, strings in catalogs.items():
            directory = contents / "Resources" / (language + ".lproj")
            assert plistlib.loads((directory / "Localizable.strings").read_bytes()) == strings
            if display_key:
                info_strings = plistlib.loads((directory / "InfoPlist.strings").read_bytes())
                assert info_strings["CFBundleDisplayName"] == strings[display_key]
    for language, strings in catalogs.items():
        directory = resources / (language + ".lproj")
        for filename, (title, paragraphs) in PAGES.items():
            page = (directory / filename).read_text()
            assert 'lang="' + language + '"' in page
            assert all(html.escape(strings[key]) in page for key in (title, *paragraphs))
        assert plistlib.loads((directory / "Localizable.strings").read_bytes())["installer.component.title"] == strings["installer.component.title"]
    assert not any((resources / filename).exists() for filename in PAGES), "Unlocalized pages would shadow translations"
