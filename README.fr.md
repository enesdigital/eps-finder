# EPS Finder

[Türkçe](README.md) · [English](README.en.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md)

Miniatures EPS et aperçus Coup d’œil avec la barre d’espace dans le Finder de macOS.

**Universal 2 :** Intel (`x86_64`) et Apple Silicon (`arm64`). **macOS 13 ou version ultérieure.** Ghostscript est inclus. L’utilisation de l’application ne nécessite ni Homebrew, ni Python, ni Illustrator, ni Rosetta.

## Installation

1. Téléchargez `EPS-Finder-1.1.0-universal-unsigned.pkg` depuis la page [Releases](https://github.com/enesdigital/eps-finder/releases/latest). Le même paquet convient aux Mac Intel et Apple Silicon.
2. Ouvrez le fichier `.pkg` et suivez l’assistant. L’application est installée dans `/Applications/EPS Finder.app` ; une autorisation d’administrateur est nécessaire.
3. Ouvrez EPS Finder une fois. Cliquez sur **Örnek dosyayı göster** (« Afficher le fichier d’exemple ») pour sélectionner l’exemple EPS fourni dans le Finder. La boîte de dialogue de l’application est actuellement en turc.

Le programme d’installation enregistre les extensions Coup d’œil pour l’utilisateur connecté. Les autres comptes peuvent également devoir ouvrir l’application une première fois.

Cette version **n’est pas signée avec un certificat Developer ID et n’est pas notariée par Apple**. macOS peut demander votre approbation avant d’ouvrir le paquet. La signature et la notarisation constituent une étape distincte de la distribution.

## Utilisation

Sélectionnez un fichier `.eps` dans le Finder et appuyez sur la **barre d’espace** pour afficher son aperçu. Le Finder génère aussi des miniatures dans la présentation par icônes. Activez l’aperçu des icônes dans les options de présentation du Finder pour les afficher.

## Si aucun aperçu ne s’affiche

1. Vérifiez que le fichier est téléchargé sur le Mac et qu’il ne s’agit pas seulement d’un élément disponible dans le cloud.
2. Ouvrez EPS Finder une fois. Recherchez **Extensions / Coup d’œil (Quick Look)** dans les Réglages Système, puis activez **EPS Finder — Preview** et **EPS Finder — Thumbnail**. L’emplacement exact varie selon la version de macOS.
3. Vérifiez l’option d’aperçu des icônes dans le Finder. Les fichiers EPS endommagés ou nécessitant des ressources externes peuvent ne pas s’afficher.

## Traitement et limites

L’extension Coup d’œil convertit l’EPS en PDF temporaire dans son environnement isolé, avec le mode `SAFER` de Ghostscript. Le traitement est local. Le fichier EPS d’origine n’est pas modifié et les fichiers temporaires sont supprimés. L’application ne demande ni accès réseau ni autorisation étendue d’accès aux fichiers.

- Taille maximale de l’entrée : 256 Mo. Taille maximale du PDF produit : 64 Mo.
- Délai maximal : 8 secondes pour les miniatures, 15 secondes pour les aperçus.
- Les polices non incorporées peuvent modifier le rendu ; des ressources externes peuvent empêcher l’affichage.
- L’aperçu ne remplace pas une validation d’impression ou une épreuve couleur.

Pour désinstaller l’application, placez `/Applications/EPS Finder.app` dans la Corbeille. Supprimez également toute ancienne copie présente dans le dossier Applications de votre compte.

## Compilation et tests

La compilation de la version Universal nécessite un **Mac Apple Silicon, Rosetta 2, les Apple Command Line Tools et Python 3.9+**. Ces prérequis concernent uniquement le développement.

```sh
python3 build-engine.py
python3 build.py
python3 package.py
```

Les scripts vérifient le SHA-256 de l’archive officielle de Ghostscript, compilent les deux architectures, exécutent les tests du moteur et écrivent le paquet d’installation, l’archive complète des sources et les sommes de contrôle dans `dist/`. Consultez le [guide en anglais](README.en.md#build) pour les détails.

Les tests arm64 et x86_64 ont réussi ; le code Intel a été exécuté avec Rosetta sur Apple Silicon. Les tests sur un Mac Intel physique, sur la plus ancienne version de macOS prise en charge et l’installation complète avec autorisation d’administrateur restent à effectuer.

## Licence et téléchargements

AGPL-3.0-or-later ; voir [LICENSE](LICENSE) et [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). Distribuez l’archive des sources générée avec le paquet binaire.

La page [Releases](https://github.com/enesdigital/eps-finder/releases/latest) propose le programme d’installation, `EPS-Finder-1.1.0-source.zip` et un fichier `SHA256SUMS`. L’archive des sources portant ce nom contient également les sources complètes de Ghostscript. Les archives « Source code » générées automatiquement par GitHub ne contiennent pas cette archive supplémentaire.
