# Archive GTFS IDFM

## État du flux — 23 octobre 2026

- La [fiche officielle du jeu GTFS PRIM](https://prim.iledefrance-mobilites.fr/jeux-de-donnees/offre-horaires-tc-gtfs-idfm?staticdataslug=offre-horaires-tc-gtfs-idfm), relue le 23 octobre, indique un dernier traitement des données et métadonnées le 22 octobre 2026 à 17:00. Elle annonce une fenêtre glissante de 30 jours et trois publications quotidiennes prévues (08:00, 13:00 et 17:00).
- Le bouton **Exporter la donnée** de PRIM est désactivé et affiche « Connexion requise » pour exporter ou visualiser ce jeu soumis à la Licence Mobilité. Aucun compte PRIM authentifié n’est disponible dans cette session.
- La [fiche du Point d’Accès National transport.data.gouv.fr](https://transport.data.gouv.fr/datasets/reseau-urbain-et-interurbain-dile-de-france-mobilites) annonce un GTFS IDFM valable du 19 octobre au 20 novembre 2026, modifié le 22 octobre, et renvoie vers [l’archive publique IDFM](https://eu.ftp.opendatasoft.com/stif/GTFS/IDFM-gtfs.zip). L’archive a été récupérée le 23 octobre depuis le terminal macOS : 150 781 133 octets, SHA-256 `955f3b2cb3afe2e3226bf3b5cb8cb0646bd0768eecb5eb46893b2cec72748458` ; le contrôle ZIP ne signale aucune erreur. Elle contient 2 030 routes. La route 214 (`IDFM:C01228`) a 143 courses au total, mais son calendrier ne les active que du 22 au 31 octobre : 109 courses les jours de semaine et 34 le samedi. Elle n’a aucune course à partir du 1er novembre et la route 314 est absente. Malgré sa date de mise à jour, ce ZIP ne fournit donc pas les courses 214/314 attendues après réorganisation.
- Le ZIP du 22 octobre a été inspecté mais n’a pas remplacé la version livrée : il ne contient pas les services post-réorganisation à valider. L’archive locale et la version déjà importée dans le magasin restent celles du 20 octobre ci-dessous. Le fichier du 22 octobre a été gardé temporairement hors du dépôt ; aucune nouvelle archive GTFS n’est ajoutée à la publication. Ni le flux public vérifié ni la date de traitement PRIM ne prouvent un rattachement à un COB.

## Version du 20 octobre 2026

- Archive source : `idfm-gtfs-2026-10-20.zip` (149 753 099 octets, 143 Mio), présente localement.
- Les octets de cette archive sont suivis dans le dépôt en 18 fragments contigus de 8 Mio maximum (`idfm-gtfs-2026-10-20-part-00.bin` à `idfm-gtfs-2026-10-20-part-17.bin`). L’application les reconstitue en flux dans son dossier temporaire au premier démarrage avant l’import GTFS ; elle importe l’archive originale byte pour byte.
- Jeu de données de référence : [Offre horaires TC GTFS IDFM](https://prim.iledefrance-mobilites.fr/jeux-de-donnees/offre-horaires-tc-gtfs-idfm).
- Plage combinée déclarée par `calendar.txt` : du 17 octobre au 18 novembre 2026. `calendar_dates.txt` porte des exceptions du 20 octobre au 18 novembre.
- SHA-256 de l’archive reconstituée : `3c3fe0eb7e165dde283ff87489339b48b4c3dcf69be011cc7ae2bc78d1764500`.
- Licence annoncée pour le jeu : Licence Mobilité IDFM ; [conditions PRIM](https://prim.iledefrance-mobilites.fr/fr/licences).
- Les agences et attributions de l’archive identifient IDFM et les réseaux/opérateurs franciliens.

L’archive conserve une source régionale datée pour l’import et l’audit. Elle ne prouve pas à elle seule les rattachements des lignes aux centres opérationnels bus (COB). Le fichier ne contient ni `frequencies.txt` ni `feed_info.txt` ; les fréquences GTFS ne sont donc pas développées par l’importeur actuel.