# Archive GTFS IDFM

## État du flux — 22 octobre 2026

- La [fiche officielle du jeu GTFS PRIM](https://prim.iledefrance-mobilites.fr/fr/jeux-de-donnees/offre-horaires-tc-gtfs-idfm), relue le 22 octobre, indique un dernier traitement des données et métadonnées le 21 octobre 2026 à 17:00. Aucun traitement du 22 octobre n’y est encore affiché. La fiche annonce une fenêtre glissante de 30 jours et trois publications quotidiennes prévues (08:00, 13:00 et 17:00).
- Le [catalogue PRIM](https://prim.iledefrance-mobilites.fr/fr/catalogue-data) marque le téléchargement de ce jeu « Connexion requise ». Le nouvel export du 21 octobre n’a donc pas été récupéré ni importé ici : ses métadonnées publiques ne révèlent ni le contenu exact du ZIP ni les courses 214/314.
- L’archive locale et la version importée dans le magasin restent celles du 20 octobre ci-dessous. Il faut télécharger un ZIP avec un compte autorisé, le conserver avec sa date et son empreinte, puis l’importer depuis **Sources** avant de valider les courses du 2 novembre. Une annonce de mise à jour ne prouve ni le contenu du ZIP ni un rattachement à un COB.

## Version du 20 octobre 2026

- Archive source : `idfm-gtfs-2026-10-20.zip` (149 753 099 octets, 143 Mio), présente localement.
- Les octets de cette archive sont suivis dans le dépôt en 18 fragments contigus de 8 Mio maximum (`idfm-gtfs-2026-10-20-part-00.bin` à `idfm-gtfs-2026-10-20-part-17.bin`). L’application les reconstitue en flux dans son dossier temporaire au premier démarrage avant l’import GTFS ; elle importe l’archive originale byte pour byte.
- Jeu de données de référence : [Offre horaires TC GTFS IDFM](https://prim.iledefrance-mobilites.fr/jeux-de-donnees/offre-horaires-tc-gtfs-idfm).
- Plage combinée déclarée par `calendar.txt` : du 17 octobre au 18 novembre 2026. `calendar_dates.txt` porte des exceptions du 20 octobre au 18 novembre.
- SHA-256 de l’archive reconstituée : `3c3fe0eb7e165dde283ff87489339b48b4c3dcf69be011cc7ae2bc78d1764500`.
- Licence annoncée pour le jeu : Licence Mobilité IDFM ; [conditions PRIM](https://prim.iledefrance-mobilites.fr/fr/licences).
- Les agences et attributions de l’archive identifient IDFM et les réseaux/opérateurs franciliens.

L’archive conserve une source régionale datée pour l’import et l’audit. Elle ne prouve pas à elle seule les rattachements des lignes aux centres opérationnels bus (COB). Le fichier ne contient ni `frequencies.txt` ni `feed_info.txt` ; les fréquences GTFS ne sont donc pas développées par l’importeur actuel.
