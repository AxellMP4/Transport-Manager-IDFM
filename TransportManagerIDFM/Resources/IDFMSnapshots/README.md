# Exports IDFM — import local du 20 octobre 2026

Ces trois exports ont été copiés tels que fournis dans ce dossier le **20 octobre 2026**. Cette date est la date d’import local, distincte des dates de traitement publiées par Île-de-France Mobilités (IDFM). Les dates de traitement ci-dessous sont celles affichées sur les fiches officielles PRIM consultées le 20 octobre 2026 ; elles ne sont pas toutes inscrites dans les fichiers exportés.

## Fichiers et provenance

### `idfm-lines-2026-10-20.csv`

- Contenu : référentiel régional des lignes IDFM (2 127 enregistrements).
- Jeu de données : [Référentiel des lignes de transport en commun d’Île-de-France](https://prim.iledefrance-mobilites.fr/fr/jeux-de-donnees/referentiel-des-lignes).
- Export CSV officiel : [API du catalogue IDFM](https://data.iledefrance-mobilites.fr/api/explore/v2.1/catalog/datasets/referentiel-des-lignes/exports/csv?lang=fr&timezone=Europe%2FParis).
- Date source : PRIM indiquait un dernier traitement des données le **17 octobre 2026 à 12:21** ; le dernier traitement des métadonnées était également le 17 octobre à 12:21. Le jeu est annoncé comme mis à jour quotidiennement. Le CSV contient des dates de validité propres à chaque ligne (`valid_fromdate`, `valid_todate`) ; elles varient et ne définissent pas une date d’effet unique pour tout le fichier.
- Licence : **Licence ODbL, version française**. Attribution : **Île-de-France Mobilités**. Voir [les licences PRIM](https://prim.iledefrance-mobilites.fr/fr/licences).
- SHA-256 : `aaa19c09fed4dd5cbd146d39e6dd9f2fd375842bc76dfc5842323c69ea668249`.

### `idfm-line-documents-2026-10-20.csv`

- Contenu : liens IDFM vers les plans et fiches horaires (4 128 enregistrements).
- Jeu de données : [Liens fiches horaires et plans des lignes](https://data.iledefrance-mobilites.fr/explore/dataset/fiches-horaires-et-plans/) ([fiche PRIM](https://prim.iledefrance-mobilites.fr/jeux-de-donnees/fiches-horaires-et-plans)).
- Export CSV officiel : [API du catalogue IDFM](https://data.iledefrance-mobilites.fr/api/explore/v2.1/catalog/datasets/fiches-horaires-et-plans/exports/csv?lang=fr&timezone=Europe%2FParis).
- Date source : PRIM indiquait un dernier traitement des données et des métadonnées le **20 octobre 2026 à 09:35** ; le jeu est annoncé comme mis à jour quotidiennement. Les documents référencés ont leurs propres périodes de validité, variables selon la ligne et le document ; le catalogue n’a donc pas de période de validité unique.
- Licence : **Licence Ouverte v2.0 (Etalab)**. Attribution : **Île-de-France Mobilités**. Voir [la Licence Ouverte](https://www.etalab.gouv.fr/licence-ouverte-open-licence) et [les licences PRIM](https://prim.iledefrance-mobilites.fr/fr/licences).
- SHA-256 : `0507f0f739ae94458dc073d17425ec482c8168ce8144f3642b695435b0e4f29c`.

### `idfm-contract-contours-2026-10-20.geojson`

- Contenu : contours géographiques des contrats d’exploitation bus (66 entités GeoJSON).
- Jeu de données : [Contours des contrats d’exploitation bus](https://prim.iledefrance-mobilites.fr/fr/jeux-de-donnees/contours-des-contrats).
- Export GeoJSON officiel : [API du catalogue IDFM](https://data.iledefrance-mobilites.fr/api/explore/v2.1/catalog/datasets/contours-des-contrats/exports/geojson?lang=fr&timezone=Europe%2FParis).
- Dates source : PRIM indiquait un dernier traitement des données le **1er juillet 2026 à 10:36** et un dernier traitement des métadonnées le **24 juillet 2026 à 15:57**. La mise à jour est annoncée comme mensuelle, hors vacances d’été. Les objets GeoJSON ne portent pas de date de validité ; aucune date plus précise n’est déduite de ce fichier.
- Licence : **Licence Ouverte v2.0 (Etalab)**. Attribution : **Île-de-France Mobilités — contours établis à partir de la BD TOPO IGN**. Voir [la Licence Ouverte](https://www.etalab.gouv.fr/licence-ouverte-open-licence) et [les licences PRIM](https://prim.iledefrance-mobilites.fr/fr/licences).
- SHA-256 : `2f28d954f6fd9ca0d7c02ed1fa586ed7b44e483ebe7a82ae4368a563015b184a`.

## Vérification d’intégrité

Les empreintes SHA-256 ci-dessus portent sur les octets exacts des fichiers conservés dans ce dossier. Les exports source dans `/tmp` n’ont pas été modifiés.
