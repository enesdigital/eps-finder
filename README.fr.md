# EPS Finder

[English](README.md) · [Türkçe](README.tr.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md)

Miniatures EPS et aperçus Coup d’œil avec la barre d’espace dans le Finder de macOS.

**Universal 2 :** Intel (`x86_64`) et Apple Silicon (`arm64`). **macOS 13 ou version ultérieure.** Ghostscript est inclus. L’utilisation de l’application ne nécessite ni Homebrew, ni Python, ni Illustrator, ni Rosetta.

L’interface, les messages d’erreur et les pages d’installation sont disponibles en turc, anglais, allemand, français et espagnol. macOS choisit automatiquement la langue adaptée à vos préférences ; l’anglais est utilisé si aucune langue prise en charge ne correspond.

La version 1.3.1 ajoute la nouvelle icône EPS, reconnaît les anciennes copies numérotées `1.0` et relance le service de miniatures après une mise à jour pour que le Finder n’utilise plus un ancien chemin d’extension. [La source de l’icône et son prompt](assets/ICON.md) sont inclus.

## Installation

1. Téléchargez `EPS-Finder-1.3.1-universal-unsigned.pkg` depuis la page [Releases](https://github.com/enesdigital/eps-finder/releases/latest). Le même paquet convient aux Mac Intel et Apple Silicon.
2. Ouvrez le fichier `.pkg` et suivez l’assistant. L’application est installée dans `/Applications/EPS Finder.app` ; une autorisation d’administrateur est nécessaire.
3. Ouvrez EPS Finder une fois. Cliquez sur **Afficher le fichier d’exemple** pour sélectionner l’exemple EPS fourni dans le Finder.

Le programme d’installation enregistre les extensions Coup d’œil pour l’utilisateur connecté. Les autres comptes peuvent également devoir ouvrir l’application une première fois.

Cette version **n’est pas signée avec un certificat Developer ID et n’est pas notariée par Apple**. macOS peut demander votre approbation avant d’ouvrir le paquet. La signature et la notarisation constituent une étape distincte de la distribution.

## Utilisation

Sélectionnez un fichier `.eps` dans le Finder et appuyez sur la **barre d’espace** pour afficher son aperçu. Le Finder génère aussi des miniatures dans la présentation par icônes. Activez l’aperçu des icônes dans les options de présentation du Finder pour les afficher.

## Mises à jour

EPS Finder recherche une nouvelle version stable sur GitHub à chaque ouverture. Vous pouvez désactiver **Rechercher automatiquement les mises à jour à l’ouverture d’EPS Finder** ou utiliser **Rechercher les mises à jour**.

Lorsqu’une mise à jour est disponible, cliquez sur **Télécharger et installer…**. L’application télécharge le paquet universel de ce dépôt, vérifie sa taille et la somme SHA-256 fournie par GitHub, puis ouvre le programme d’installation de macOS. EPS Finder se ferme à l’ouverture du programme d’installation pour arrêter l’ancien processus. Terminez avec une autorisation d’administrateur et rouvrez EPS Finder. **Notes de version** ouvre la page pour un téléchargement manuel.

Les versions 1.2.0 et antérieures n’ont pas cette fonction : installez d’abord la version 1.3.1 depuis Releases. Après l’installation, EPS Finder est enregistré comme élément d’ouverture de session et recherche les mises à jour à chaque connexion. Vous pouvez désactiver **Ouvrir EPS Finder à l’ouverture de session** ou utiliser Réglages Système → Général → Ouverture de session. Un réglage désactivé dans macOS est respecté. Aucun service distinct en arrière-plan n’est installé. Seule l’application contacte GitHub et ses serveurs de téléchargement. Les fichiers EPS ne sont jamais envoyés et les extensions Coup d’œil n’ont pas d’autorisation réseau.

Le paquet reste non signé et non notarié. SHA-256 vérifie l’intégrité du téléchargement et ne remplace ni une signature Developer ID ni une autorisation de sécurité de macOS. Les téléchargements incomplets ou incorrects sont supprimés. En cas d’erreur réseau ou de limite de requêtes GitHub, réessayez plus tard.

L’installation manuelle et la mise à jour remplacent `/Applications/EPS Finder.app`. Les anciennes copies ayant le même identifiant dans `/Applications` et dans `~/Applications` de l’utilisateur connecté sont placées dans la Corbeille. Les copies des autres utilisateurs sont vérifiées à la prochaine ouverture de la nouvelle application. Les versions identiques ou plus récentes, les autres applications, les liens symboliques et les documents EPS sont conservés. Les autres dossiers ne sont pas analysés. Si une copie ne peut pas être déplacée, l’application demande un nettoyage manuel.

## Si aucun aperçu ne s’affiche

1. Vérifiez que le fichier est téléchargé sur le Mac et qu’il ne s’agit pas seulement d’un élément disponible dans le cloud.
2. Ouvrez EPS Finder une fois. Recherchez **Extensions / Coup d’œil (Quick Look)** dans les Réglages Système, puis activez **EPS Finder — Aperçu** et **EPS Finder — Miniatures**. L’emplacement exact varie selon la version de macOS.
3. Vérifiez l’option d’aperçu des icônes dans le Finder. Les fichiers EPS endommagés ou nécessitant des ressources externes peuvent ne pas s’afficher.

## Traitement et limites

L’extension Coup d’œil convertit l’EPS en PDF temporaire dans son environnement isolé, avec le mode `SAFER` de Ghostscript. Le traitement est local. Le fichier EPS d’origine n’est pas modifié et les fichiers temporaires sont supprimés. Les extensions Coup d’œil n’ont ni autorisation réseau ni accès étendu aux fichiers. L’application principale utilise le réseau uniquement pour rechercher et télécharger les mises à jour.

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

Les scripts vérifient le SHA-256 de l’archive officielle de Ghostscript, compilent les deux architectures, exécutent les tests du moteur et écrivent le paquet d’installation, l’archive complète des sources et les sommes de contrôle dans `dist/`. Consultez le [guide en anglais](README.md#build) pour les détails.

Les tests arm64 et x86_64 ont réussi ; le code Intel a été exécuté avec Rosetta sur Apple Silicon. Les tests sur un Mac Intel physique, sur la plus ancienne version de macOS prise en charge et l’installation complète avec autorisation d’administrateur restent à effectuer.

## Licence et téléchargements

AGPL-3.0-or-later ; voir [LICENSE](LICENSE) et [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). Distribuez l’archive des sources générée avec le paquet binaire.

La page [Releases](https://github.com/enesdigital/eps-finder/releases/latest) propose le programme d’installation, `EPS-Finder-1.3.1-source.zip` et un fichier `SHA256SUMS`. L’archive des sources portant ce nom contient également les sources complètes de Ghostscript. Les archives « Source code » générées automatiquement par GitHub ne contiennent pas cette archive supplémentaire.
