# Matrice régionale de couverture des lignes IDFM

Le fichier `idfm-regional-coverage-2026-11-02.json` relie, pour le service du 2 novembre 2026, les enregistrements actifs ou annoncés actifs du référentiel bus IDFM aux routes et courses GTFS, aux formes de course, aux tracés commerciaux et aux liens de plans/horaires. Il est généré localement par `sh Scripts/audit-regional-line-coverage.sh`; le script vérifie les empreintes SHA-256 et l’intégrité des deux archives avant l’audit.

## Résultat de l’audit

- Le référentiel contient 2 065 enregistrements bus au statut actif ou annoncé actif; 2 060 sont valides le 2 novembre et cinq sont hors période de validité. Parmi les 2 060 références éligibles, 1 970 se rapprochent d’une route GTFS unique et 90 n’ont pas de route; aucune n’a plusieurs variantes portant le même `ID_Line`.
- Le ZIP contient 1 970 routes bus, 414 215 courses et horaires, 53 457 fiches d’arrêt (dont 33 578 arrêts de bus géolocalisés) et 895 calendriers. Sa validité couvre le 29 octobre au 30 novembre 2026. Le 2 novembre, 123 817 modèles de course ont un service actif et 123 812 ont une ligne de départ; cinq modèles sans départ se répartissent sur deux lignes de transport à la demande.
- Parmi les 123 817 modèles actifs, 123 756 ont une forme GTFS disponible, 52 référencent une forme rejetée comme invalide et neuf n’ont pas de référence de forme. Les cas sans forme disponible sont identifiés par course dans `tripShapeIssues`.
- Parmi les 2 060 références éligibles, la couverture des tracés commerciaux est exacte par `ID_Line` pour 1 939, rapprochée par nom unique pour une, ambiguë pour 65 et absente pour 55. Le catalogue documentaire relie 1 948 lignes à au moins un plan et 1 971 à une fiche horaire; 112 lignes n’ont pas de plan et 89 n’ont pas de fiche horaire. Aucun enregistrement documentaire n’a été rejeté pour URL mal formée. Les compteurs `summary` couvrent les 2 065 références au statut actif ou annoncé actif, en conservant séparément les cinq références hors période.
- Pour la 214, les 79 départs actifs ont tous une forme GTFS disponible, avec un plan et deux liens d’horaires (un lien daté du 1er novembre, l’autre à période inconnue). Pour la 314, les 23 départs ont tous une forme disponible; un horaire daté du 1er novembre est présent, le plan et le tracé commercial manquent dans les instantanés. Le rapport conserve explicitement `no_plan_link` et `no_commercial_geometry_match`.

Le contrôle des documents vérifie les liens HTTP(S) et ne télécharge pas les PDF. Une période n’est datée que si elle est publiée au format `AAAA-MM-JJ/AAAA-MM-JJ`; les formats non reconnus restent à `unknown`.

## Lire les statuts

- `dateStatus` précise si la référence IDFM est valide à la date choisie. Une date de validité inconnue reste dans le rapport.
- `routeMatchStatus` distingue le référentiel ou GTFS indisponible, l’absence de route, une route et plusieurs variantes GTFS portant le même `ID_Line`.
- Les métadonnées `gtfs` donnent aussi les dénominateurs globaux du ZIP (routes, courses, horaires, arrêts, calendriers et formes). Chaque `routeVariant` indique les modèles de course actifs, les départs observés et les modèles actifs sans ligne de départ; un écart partiel est signalé séparément.
- Si `frequencies.txt` est présent, les comptes exacts de départs restent `null`, car les fréquences ne sont pas développées.
- `shapeCoverage` mesure les références des formes GTFS course par course : forme disponible, référence invalide ou indisponible, ou aucune référence. `tripShapeIssues` identifie individuellement toutes les courses qui n’ont pas de forme disponible.
- `commercialGeometry` mesure la présence d’un tracé de ligne IDFM. Ce tracé commercial est distinct d’une forme GTFS de course et ne prouve pas la chaussée empruntée.
- `plans`, `timetables` et `otherDocuments` listent les liens HTTP(S) reliés par `ID_Line`. La validité d’un document n’est évaluée que si sa période est lisible au format `AAAA-MM-JJ/AAAA-MM-JJ`; sinon le statut reste `unknown`. Les deux horaires 214/314 ajoutés au catalogue de l’application sont marqués avec leurs dates et leur provenance dans chaque lien.
- `reasons` conserve les causes de couverture manquante ou non évaluable. Les enregistrements source mal formés du catalogue documentaire sont comptés et leurs motifs sont regroupés dans `malformedDocumentReasons`.

## Provenance et limites

Les noms, dates de capture, dates de traitement, URL et empreintes des sources sont embarqués dans le JSON. Le GTFS du 31 octobre provient du miroir public lié à la ressource PAN 80921; ce n’est pas un export PRIM authentifié. Le référentiel des lignes conservé le 20 octobre affichait un traitement au 17 octobre, et le catalogue documentaire ainsi que les tracés commerciaux sont des instantanés du 20 octobre.

Le rapport ne contient pas de preuve de rattachement d’une ligne à un centre opérationnel bus (COB). Il ne déduit pas non plus les voies réellement empruntées depuis les tracés commerciaux. Ces preuves et un compte PRIM restent des dépendances externes, distinctes des lacunes mesurées dans les sources locales.

## Reproduire

```sh
sh Scripts/audit-regional-line-coverage.sh
```

Une autre date de service peut être passée en argument si elle appartient à la période du ZIP audité, par exemple `sh Scripts/audit-regional-line-coverage.sh 2026-11-03`. Le rapport produit porte cette date dans son nom et ses métadonnées.
