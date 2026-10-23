# Archive GTFS IDFM

## État du flux — 23 octobre 2026

- La [fiche officielle du jeu GTFS PRIM](https://prim.iledefrance-mobilites.fr/jeux-de-donnees/offre-horaires-tc-gtfs-idfm?staticdataslug=offre-horaires-tc-gtfs-idfm), relue le 23 octobre à 11:40 CEST, indique un dernier traitement des données et métadonnées le 22 octobre 2026 à 17:00. À cette heure, la publication prévue de 13:00 n’a pas encore eu lieu. La fiche annonce une fenêtre glissante de 30 jours et trois publications quotidiennes prévues (08:00, 13:00 et 17:00).
- Le bouton **Exporter la donnée** de PRIM est désactivé et affiche « Connexion requise » pour exporter ou visualiser ce jeu soumis à la Licence Mobilité. Aucun compte PRIM authentifié n’est disponible dans cette session.
- La [fiche du Point d’Accès National transport.data.gouv.fr](https://transport.data.gouv.fr/datasets/reseau-urbain-et-interurbain-dile-de-france-mobilites) annonce maintenant un GTFS IDFM valable du 20 octobre au 21 novembre 2026, modifié le 23 octobre, et renvoie vers [l’archive publique IDFM](https://eu.ftp.opendatasoft.com/stif/GTFS/IDFM-gtfs.zip). La fiche indique la Licence Mobilité et trois mises à jour quotidiennes prévues. Le téléchargement contrôlé plus tôt le 23 octobre (150 781 133 octets, SHA-256 `955f3b2cb3afe2e3226bf3b5cb8cb0646bd0768eecb5eb46893b2cec72748458`) a depuis été remplacé au même URL.
- Nouveau téléchargement du 23 octobre à 11:32 CEST : l’en-tête HTTP `Last-Modified` date le contenu du 23 octobre à 07:24:04 CEST. Le ZIP contient 149 919 300 octets (SHA-256 `48d957cd07fb60b19f330267e07ae39da38bfe076567816218729083ddf9786d`) et son contrôle d’intégrité réussit. Il contient 2 030 routes. La route 214 (`IDFM:C01228`) a 143 courses : 109 les jours de semaine du 22 au 30 octobre et 34 le samedi jusqu’au 31 octobre. Elle n’a aucune course à partir du 1er novembre et la route 314 est absente. La version plus récente du miroir ne fournit donc toujours pas les courses 214/314 annoncées après réorganisation.
- Le ZIP du 23 octobre a été inspecté mais n’a pas remplacé la version livrée : il ne contient pas les services post-réorganisation à valider. L’archive locale et la version déjà importée dans le magasin restent celles du 20 octobre ci-dessous. Le nouveau fichier a été gardé temporairement hors du dépôt ; aucune nouvelle archive GTFS n’est ajoutée à la publication. Ni le flux public vérifié ni la date de traitement PRIM ne prouvent un rattachement à un COB.

## Provenance des importations GTFS — 23 octobre 2026

- La version intégrée au premier lancement est attribuée explicitement au jeu PRIM dont elle provient.
- Pour un ZIP choisi manuellement, l’interface permet de déclarer un export PRIM, le miroir public transport.data.gouv.fr ou une autre archive dont la provenance reste inconnue. Les imports génériques utilisent par défaut « source à vérifier » et ne déclarent aucune licence tant que l’utilisateur n’a pas choisi une source.
- Le miroir public conserve son identifiant de jeu, sa page de référence et la Licence Mobilité affichée par le Point d’Accès National. La source déclarée est une indication de l’utilisateur; l’application ne peut pas authentifier l’origine des octets du fichier sélectionné.
- Les catalogues sauvegardés avant cette correction ne sont pas réattribués automatiquement. Sans ZIP original ou preuve d’export, l’application ne peut pas distinguer une ancienne importation PRIM d’un autre fichier.

## Version du 20 octobre 2026

- Archive source : `idfm-gtfs-2026-10-20.zip` (149 753 099 octets, 143 Mio), présente localement.
- Les octets de cette archive sont suivis dans le dépôt en 18 fragments contigus de 8 Mio maximum (`idfm-gtfs-2026-10-20-part-00.bin` à `idfm-gtfs-2026-10-20-part-17.bin`). L’application les reconstitue en flux dans son dossier temporaire au premier démarrage avant l’import GTFS ; elle importe l’archive originale byte pour byte.
- Jeu de données de référence : [Offre horaires TC GTFS IDFM](https://prim.iledefrance-mobilites.fr/jeux-de-donnees/offre-horaires-tc-gtfs-idfm).
- Plage combinée déclarée par `calendar.txt` : du 17 octobre au 18 novembre 2026. `calendar_dates.txt` porte des exceptions du 20 octobre au 18 novembre.
- SHA-256 de l’archive reconstituée : `3c3fe0eb7e165dde283ff87489339b48b4c3dcf69be011cc7ae2bc78d1764500`.
- Licence annoncée pour le jeu : Licence Mobilité IDFM ; [conditions PRIM](https://prim.iledefrance-mobilites.fr/fr/licences).
- Les agences et attributions de l’archive identifient IDFM et les réseaux/opérateurs franciliens.

L’archive conserve une source régionale datée pour l’import et l’audit. Elle ne prouve pas à elle seule les rattachements des lignes aux centres opérationnels bus (COB). Le fichier ne contient ni `frequencies.txt` ni `feed_info.txt` ; les fréquences GTFS ne sont donc pas développées par l’importeur actuel.