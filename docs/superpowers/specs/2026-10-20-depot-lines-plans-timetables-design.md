# Catalogue d’exploitation par dépôt Bords de Marne

## Intention

Permettre de retrouver, pour chaque centre bus jouable du scénario Bords de Marne, l’inventaire daté de ses lignes et variantes, les plans officiels, les fiches horaires et une grille horaire consultable dans TransitCity. L’objectif est que le joueur puisse voir quelles lignes sont documentées pour Saint-Maur et Neuilly-Plaisance, vérifier leurs sources et comprendre immédiatement les éléments qui manquent.

## Pourquoi

Le projet sait déjà importer GTFS, le référentiel IDFM, les liens des plans/fiches horaires et les rattachements ligne–COB. Toutefois, aucun de ces jeux de données réels n’est présent dans le checkout et la répartition des lignes par centre reste incomplète. Il n’existe donc pas encore de liste exploitable des lignes de chaque dépôt ni de grille horaire complète par ligne.

## Résultat attendu

- La livraison couvre la recherche et l’intégration d’un jeu de données daté, pas seulement la création d’un importeur ou d’une vue vide.
- Une fiche pour chacun des deux COB jouables : Saint-Maur-des-Fossés et Neuilly-Plaisance.
- Une liste exhaustive, datée, des lignes et variantes du contrat DSP 45 actives dans la période réseau choisie, sans confondre nom commercial, identifiant IDFM et identifiant de route GTFS.
- Pour chaque ligne rapprochée sans ambiguïté : tous les plans et toutes les fiches horaires officiels trouvés dans le catalogue IDFM, avec dates de validité quand elles sont indiquées par la source.
- Une grille de courses fondée sur les départs et passages GTFS, filtrable par date de service, jour, direction et ligne/variante.
- Une vue de couverture qui montre aussi les routes actives non rapprochées, les lignes contractuelles sans route GTFS et les affectations de COB qui restent à confirmer.
- Des liens et preuves consultables, avec date, titre de source et URL ; les PDFs restent ouverts depuis leur source officielle.
- La couverture est dite complète seulement lorsque toutes les routes actives et variantes de la période choisie sont présentes dans le registre et que chaque rattachement de COB est établi par une preuve exploitable. Les données à confirmer restent visibles, mais ne comptent pas comme des lignes définitivement rattachées.

## Périmètre

- Ce travail porte sur les deux centres existants et jouables du scénario Bords de Marne : Saint-Maur-des-Fossés et Neuilly-Plaisance.
- Le troisième centre de Neuilly-sur-Marne reste un projet futur et n’est pas traité comme un dépôt opérationnel.
- Le catalogue doit respecter les versions de service avant et après la réorganisation annoncée au 1er novembre 2026. Les lignes et les horaires affichés proviennent de la version GTFS valide à la date choisie.
- Les lignes Noctilien sont comprises dans le périmètre contractuel ; elles ne sont rattachées à un COB que si une source datée l’établit. Une exploitation au pôle Gare de Lyon ou un partage de ligne ne signifie pas une affectation exclusive à l’un des deux dépôts.

## Sources et preuves

1. Le GTFS IDFM fournit les identifiants de routes, courses, calendriers, exceptions, horaires de passage, arrêts et tracés disponibles pour sa période de validité.
2. Le référentiel IDFM relie les identifiants `ID_Line` aux noms commerciaux. La correspondance avec GTFS reste une correspondance exacte par identifiant stable et unique.
3. Le catalogue IDFM des plans et fiches horaires fournit des liens vers les documents commerciaux. Tous les liens applicables à une route sont conservés ; aucun document n’est choisi arbitrairement.
4. Les sources contractuelles et d’exploitation datées établissent les relations DSP–ligne–COB. Les polygones, la proximité géographique, un terminus ou la présence d’un arrêt « Centre Bus » sur un plan ne suffisent pas à prouver le rattachement.
5. Les éléments historiques ou secondaires peuvent être conservés comme candidats clairement marqués `historique` ou `à vérifier`, jamais présentés comme une affectation actuelle confirmée.

Sources déjà identifiées : [attribution IDFM de la DSP 45](https://presse.iledefrance-mobilites.fr/mise-en-concurrence-des-transports-franciliens/?lang=fr), [réorganisation Bords de Marne au 1er novembre 2026](https://www.iledefrance-mobilites.fr/actualites/locales/detail/a-compter-du-1er-novembre-2026-ile-de-france-mobil), [référentiel IDFM des lignes](https://prim.iledefrance-mobilites.fr/fr/jeux-de-donnees/referentiel-des-lignes), [liens IDFM des plans et fiches horaires](https://data.iledefrance-mobilites.fr/explore/dataset/fiches-horaires-et-plans/), [GTFS IDFM](https://prim.iledefrance-mobilites.fr/fr/jeux-de-donnees/offre-horaires-theoriques).

## Appels de conception

- Conserver le modèle macOS SwiftUI/MapKit existant.
- Réutiliser les importeurs et le versionnage de `NetworkLibrary`, `LineReferenceStore`, `LineDocumentStore` et `DepotAssignmentStore`.
- Présenter l’inventaire du dépôt et la grille dans une vue dédiée. Les liens de documents restent accessibles pour chaque ligne sans obliger le joueur à parcourir séparément toutes les fiches d’arrêt.
- Alimenter la grille avec les courses et `stop_times` GTFS archivés. Les PDF officiels restent une référence complémentaire et ouvrable ; ils ne remplacent pas le détail du planning GTFS.
- Garder les rattachements proposés mais non établis visibles dans la couverture, avec leur niveau de preuve et leur période. Seules les affectations opérationnellement utilisables autorisent une carrière.
- Ne pas intégrer de jeton PRIM, ne pas copier les PDFs liés, et garder l’import manuel disponible lorsque le téléchargement nécessite un accès ou une archive locale.

## Hors périmètre

- Déduire les rattachements à partir des tracés, des noms, des dépôts les plus proches ou des horaires.
- Importer les PDFs eux-mêmes dans le bundle de l’application ; les conditions de réutilisation varient selon le document.
- Déclarer complète une couverture avant d’avoir confronté les sources à un GTFS et aux référentiels IDFM datés.
- Traiter le projet de COB de Neuilly-sur-Marne comme une installation actuellement exploitable.

## État des preuves connu au 20 octobre 2026

IDFM confirme le contrat DSP 45, 29 lignes dont 7 Noctilien et les deux COB de Saint-Maur et Neuilly-Plaisance, mais les sources contractuelles publiques trouvées ne donnent pas la ventilation nominative actuelle par COB. Une FAQ publique de RATP Group donne un compte historique de 9 lignes régulières à Saint-Maur, 13 à Bords de Marne et 7 Noctilien au pôle Gare de Lyon, puis renvoie le détail nominatif à l’intranet UrbanWeb. Des listes secondaires permettent d’établir des candidats historiques, pas de certifier les affectations actuelles. L’application doit donc préserver cette distinction et montrer les lacunes plutôt que d’inventer un roster confirmé.

La demande de l’utilisateur tranche le point de planification : la recherche et l’intégration des données réelles font partie du livrable. Si une preuve publique manque pour une affectation individuelle, le registre doit rester incomplet et demander la source manquante plutôt que prétendre que la fonctionnalité seule satisfait l’objectif.
