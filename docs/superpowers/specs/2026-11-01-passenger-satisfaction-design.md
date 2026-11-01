# Satisfaction voyageurs estimée

**État :** implémentée comme estimation de rapport dans « Voyageurs ». Elle n’agit ni sur la trésorerie, ni sur les contrats, ni sur les objectifs de carrière.

## Intention

Donner au joueur un indicateur lisible de la qualité vécue du service dans le rapport « Voyageurs », afin qu’il puisse relier la demande refusée, la charge des bus et les correspondances manquées aux décisions d’exploitation.

L’application simule des passagers; elle ne reçoit ni enquête ni mesure de satisfaction réelle. L’interface doit donc parler d’« estimation de satisfaction » et expliquer les observations qui la composent.

## Objectifs

- Calculer un score de 0 à 100 sur la période et le périmètre déjà choisis dans le rapport.
- Montrer séparément l’accès à bord, le confort de charge et la réussite des correspondances.
- Rendre visibles la couverture des données et les capacités de véhicule estimées.
- Préserver les sauvegardes existantes et ne pas inférer les événements manquants.

## Proposition de calcul

Les trois composantes disponibles reçoivent le même poids. Le score général est leur moyenne arithmétique, arrondie à l’entier. Si seulement une ou deux composantes peuvent être calculées, l’interface affiche la moyenne partielle et le nombre de composantes couvertes. Sans composante calculable, elle affiche « Indisponible ».

### Accès à bord

Pour les arrivées dont le résultat est connu :

`100 × montées de nouveaux arrivants / (montées de nouveaux arrivants + nouveaux arrivants laissés à quai)`

La demande d’arrivée est celle déjà déterminée par la simulation après les effets d’information et d’événement local. Les passagers déjà en attente et les voyageurs en correspondance ne sont pas comptés une deuxième fois comme de nouvelles arrivées. Les arrêts terminaux sans possibilité de montée et les arrivées prises en charge par un itinéraire de remplacement sont hors de ce dénominateur; le rapport continue de montrer séparément les voyageurs redirigés. Une fermeture sans solution de remplacement reste un échec d’accès.

Le moteur persiste le nombre de nouveaux passagers montés et l’éligibilité de l’échange dans `PassengerStopExchange`. Le décompte de nouveaux arrivants laissés à quai existant complète la mesure. Les anciennes sauvegardes où ces nouveaux champs sont absents ne contribuent pas à cette composante.

### Confort de charge

Chaque échange exploitable fournit un échantillon égal, calculé à partir de la charge après l’échange et de la capacité du véhicule. Un échange fermé est ignoré. Un échantillon est retenu s’il reste des passagers à bord après l’échange ou si au moins un passager vient de monter; les échanges terminaux qui vident le bus et les échanges vides ne sont donc pas évalués comme une expérience de confort. Les seuils du jeu déjà affichés dans `PassengerLoadPresentation` servent de barème : charge normale (<80 %) = 100 points, bus très chargé (80–99 %) = 50 points, bus complet (≥100 %) = 0 point. La composante est la moyenne des points par échantillon, non une mesure de minutes-passagers.

Les capacités estimées restent utilisables, puisque la simulation en dépend déjà; leur nombre doit être indiqué parmi les échantillons pour éviter de présenter une précision qu’on n’a pas.

### Réussite des correspondances

Une tentative compte quand des voyageurs sont rattachés à une course cible précise. Elle réussit si ces voyageurs montent dans cette course; elle échoue si le départ de cette course est traité alors qu’ils ne sont pas montés. Les tentatives encore en attente ne figurent pas au dénominateur. Un voyage ultérieur après une correspondance manquée n’efface pas cet échec.

`100 × tentatives réussies / (tentatives réussies + tentatives manquées)`

Pour chaque nouvel échange, le moteur enregistre le nombre de voyageurs tentant la course visée et le nombre de ceux qui y montent, y compris zéro. La file de correspondance conserve la course cible et son bus quand ils sont connus. Les anciennes sauvegardes dépourvues de ces champs sont exclues de la composante.

## Interface et accessibilité

Le rapport « Voyageurs » affiche en tête un groupe « Satisfaction voyageurs · estimation », sans remplacer les métriques existantes.

- En premier : le score général, ou « Indisponible », et la couverture, par exemple « 2 composantes sur 3 · données partielles ».
- En dessous : trois lignes de composante avec nom, score, formule courte et volume observé.
- Pour la charge : montrer le nombre d’échantillons à capacité estimée.
- Pour les correspondances : montrer les réussites, les échecs et les tentatives encore exclues car non résolues.
- Réutiliser les filtres existants de dates, ligne et bus; les détails par ligne, bus, course ou arrêt suivent le regroupement déjà sélectionné.
- Utiliser du texte et des nombres en plus des couleurs. L’annonce VoiceOver nomme le score, le nombre de composantes disponibles et les données couvertes. La mise en page reste adaptable à une fenêtre étroite et large.
- Quand aucune donnée n’est disponible, le rapport explique qu’il faut laisser circuler des bus et résoudre des correspondances pour alimenter l’indice.

## Sauvegardes et données historiques

Les nouveaux champs d’`PassengerStopExchange` sont optionnels et décodables en l’absence dans les anciens JSON. La génération courante les remplit avec zéro lorsqu’il n’y a aucun événement correspondant et avec un nombre quand il y en a un. Une valeur absente signifie « ancien enregistrement sans mesure », pas zéro. Aucun historique ne sera réécrit pour fabriquer ces données.

La composante confort peut être calculée à partir des échanges anciens qui comportent déjà charge et capacité, avec une couverture clairement signalée. L’accès à bord et les correspondances n’incluent que les enregistrements disposant des champs de précision nécessaires.

## Effet sur le jeu — règle retenue

L’indice reste un indicateur de rapport. Il ne modifie pas les recettes, les bonus/malus, la trésorerie, les objectifs ni le règlement des contrats. Les annexes DSP45 disponibles ne fournissent aucun barème permettant de relier ce score aux paiements; aucun effet de jeu n’est donc inventé.

## Hors périmètre

- Une prétention à mesurer la satisfaction des voyageurs réels ou un sondage.
- Un barème financier ou contractuel.
- La conversion des validations de titres en recettes d’exploitant.
- Une reconstruction approximative des champs absents dans les anciennes sauvegardes.
- La refonte des rapports existants ou un nouveau graphique décoratif.

## Critères d’acceptation

1. Le score et ses composantes suivent les filtres actuels du rapport et se mettent à jour avec le regroupement choisi.
2. Les nombres d’anciens enregistrements sans mesure ne sont jamais interprétés comme des zéros; la couverture partielle est explicitée.
3. Les montées issues d’une file antérieure ou d’une correspondance ne gonflent pas le numérateur d’accès des nouvelles arrivées.
4. Une capacité estimée est signalée dans le décompte d’échantillons de charge.
5. Un échange vide ou fermé n’est pas un échantillon de confort; les correspondances en attente ne sont ni réussites ni échecs, et la réussite est attribuée à la course cible, pas à un autre groupe présent au même arrêt.
6. Les sauvegardes antérieures restent lisibles et leurs données sont conservées sans migration destructive.
7. Le rapport ne présente jamais l’indice comme une enquête réelle et n’en tire aucun effet financier.
8. VoiceOver peut lire le score et la couverture sans dépendre de la couleur; les libellés restent lisibles en fenêtre étroite.

## Choix de cette version

- L’indice reste consultatif et sans effet sur les objectifs de carrière ou les finances.
- Le confort utilise le barème proposé de 100 / 50 / 0 points.
- Les voyageurs pris en charge par un arrêt de remplacement sont exclus de l’accès à bord et comptés dans la métrique de redirection existante.

## Revue de conception

La revue de conception a conduit à omettre les échanges vides et fermés du confort. La validation couvre les trois scores, l’exclusion des transferts en attente du dénominateur, l’attribution aux courses visées, les données historiques absentes et la compatibilité de l’ancien JSON. La disposition et VoiceOver restent à vérifier dans l’application; le contrôle statique et le build ne remplacent pas cette revue visuelle.
