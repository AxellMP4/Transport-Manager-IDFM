# Cahier des charges complet — jeu de gestion des bus d’Île-de-France

**Version : 19 octobre 2026**  
**Plateforme cible : macOS, projet Xcode natif en Swift**  
**Périmètre de jeu : dépôts et lignes de bus exploités dans le réseau Île-de-France Mobilités**  
**Principe : une simulation de gestion jouable en continu sur Apple Maps, avec un marché de véhicules et des incidents traités au moment où ils surviennent.**

## 1. Décisions de cadrage

Cette version remplace le cadrage précédent orienté application web et pilote limité à Bords de Marne.

- **Le livrable final est un jeu macOS créé dans Xcode**, écrit en Swift. Il comprend une boucle de jeu, des parties sauvegardables, des scénarios, des objectifs, une économie, une progression et des événements. Ce n’est pas un simple tableau de bord.
- **Apple MapKit est le fond de carte principal.** La carte interactive affiche les lignes IDFM, les arrêts, les dépôts, les bus en circulation, les pannes, les fermetures d’arrêts et les déviations.
- **Le catalogue de lancement couvre tous les centres bus qui exploitent des lignes IDFM en Île-de-France**, et pas uniquement les sites RATP ou Bords de Marne. Il couvre les huit départements franciliens.
- **Le jeu comprend toutes les lignes de bus IDFM et leurs variantes datées**, y compris lignes de nuit, scolaires, express, services urbains et lignes créées ou modifiées. Une partie ne doit pas démarrer en présentant un échantillon de lignes comme s’il était complet.
- **Au début d’une carrière, le dépôt ne possède pas automatiquement les bus historiques.** Le joueur achète les véhicules sur un marché. Le catalogue du marché comprend les modèles de bus attestés dans les parcs franciliens, avec des prix de jeu estimés et clairement étiquetés comme tels.
- **À ×1, une seconde simulée dure une seconde réelle.** La simulation peut ensuite être accélérée ou mise en pause.
- **Les pannes, recettes, déviations, arrêts non desservis, retards et dépannages sont traités au fil du jeu.** La nuit sert à produire un bilan journalier, jamais à exécuter en bloc les événements de la journée.
- **Bords de Marne est le scénario de référence pour valider le système**, mais le catalogue complet des autres dépôts et réseaux reste un objectif de livraison, pas une extension repoussée à une version future.

## 2. Ce que le jeu observé apporte au cahier des charges

L’audit de Transport Manager montre une gestion d’entreprise de transport qui combine :

| Système observé | Règle de recréation |
|---|---|
| Création et exploitation de lignes | Importer les tracés, arrêts, services, horaires et calendriers réels. Séparer les directions, variantes et dates de validité. |
| Créneaux et services | Conserver les vues par pointe, heures creuses, soirée et nuit comme outils de planification. Simuler les courses à leurs horaires réels plutôt que par lots fixes. |
| Affectation des bus | Planifier des blocs de courses avec battements, retours au dépôt, relève, autonomie et contraintes d’affectation. |
| Personnel | Gérer les machinistes, les services, les qualifications, les absences, les pauses, le repos, la durée de travail et la paie. |
| Dépôt et atelier | Modéliser capacité de remisage, énergie, bornes, ravitaillement, lavage, entretien, pièces et véhicules de réserve. |
| État des bus | Suivre âge, kilométrage, énergie, état, contrôles, accessibilité, capacité et immobilisations. |
| Voyageurs | Simuler l’attente, les montées et descentes, les correspondances, la capacité, les voyageurs laissés à quai et l’effet des arrêts fermés. |
| Recettes et charges | Tenir un journal financier à mesure que les courses et événements se produisent ; présenter ensuite les bilans par jour, mois, ligne et dépôt. |
| Contrats et qualité | Modéliser la rémunération contractuelle, la qualité, l’offre réalisée, les bonus/malus, les coûts et la trésorerie. Les tickets ne sont pas assimilés automatiquement au chiffre d’affaires du transporteur. |
| Progression | Ajouter objectifs, améliorations de dépôt, achats, niveaux et nouveaux contrats sans masquer les règles économiques. |
| Événements | Déclencher et résoudre les événements dans la simulation active au lieu d’attendre un traitement nocturne. |

Les règles de serveur et les formules privées de Transport Manager ne sont pas visibles depuis ses écrans. On reprend les familles de mécaniques, mais on crée nos propres règles, interface, illustrations, données et équilibrages.

## 3. Plateforme et expérience de jeu macOS

### 3.1 Projet Xcode

Le projet initial cible uniquement **macOS**. Le code est en Swift et reste structuré pour que le moteur puisse être testé indépendamment de l’interface.

- **SwiftUI** : menus du jeu, écrans de gestion, panneaux de détail, commandes de temps, marché, contrats et finances.
- **MapKit pour SwiftUI** : carte géographique interactive, recherche de lieux, annotations et tracés de lignes avec des polylignes.
- **SpriteKit** : animations et scènes de jeu qui gagnent à être dessinées en 2D — véhicules en mouvement, dépôt, atelier et retours visuels. La carte régionale reste dans MapKit.
- **Moteur Swift séparé de l’interface** : l’horloge, les règles, les événements et l’économie ne dépendent pas du nombre d’images dessinées.
- **Données locales versionnées** : les horaires, plans et référentiels importés sont conservés avec leur date, leur source et leur licence. Une sauvegarde de partie conserve également la version du réseau utilisée.
- **Parties locales sauvegardées** : reprise, sauvegarde automatique et export/import de partie. Le jeu peut rester jouable sans compte ni connexion permanente.

### 3.2 Boucle de jeu

Une carrière suit le cycle suivant :

1. choisir un COB et une date de départ ;
2. étudier les lignes de son contrat et les équipements du centre ;
3. acheter des bus sur le marché et préparer le parc ;
4. construire les blocs de courses et les services machinistes ;
5. faire rouler l’offre, surveiller la carte et traiter les événements ;
6. suivre les voyageurs, la qualité, les coûts, les recettes et la trésorerie ;
7. réparer, remplacer, revendre ou renouveler le parc ;
8. améliorer les bâtiments et préparer les changements d’offre ;
9. comparer les résultats et faire progresser l’entreprise.

Les objectifs et l’aide expliquent au joueur pourquoi une décision a un coût ou un effet. La partie doit être compréhensible sans connaissance préalable de l’exploitation réelle.

### 3.3 Carte Apple

La carte principale utilise MapKit. Elle comprend :

- une vue de l’Île-de-France pour choisir un dépôt ;
- un zoom local sur le dépôt, ses lignes et son aire d’exploitation ;
- une couleur distincte pour chaque ligne et variante ;
- des annotations sélectionnables pour les arrêts, COB, bus, dépanneuses et incidents ;
- l’état de service en direct : à l’heure, en retard, dévié, immobilisé ou remplacé ;
- des couches activables pour lignes, arrêts, travaux, arrêts fermés, densité des voyageurs et véhicules ;
- une légende, une date des données et les attributions requises.

MapKit dessine le fond et les superpositions. Les géométries des bus et les itinéraires à exploiter viennent des données de transport. Le temps de trajet de la dépanneuse doit provenir d’un calcul de déplacement explicite et non d’une simple animation en ligne droite.

## 4. Réseau complet d’Île-de-France

### 4.1 Lignes à intégrer

Le périmètre de livraison comprend toutes les lignes de bus IDFM en service dans les huit départements, quels que soient l’exploitant ou la taille du réseau.

Pour chaque ligne, importer ou conserver :

- l’identifiant source IDFM et le nom public ;
- le réseau, l’exploitant et le contrat, avec dates de validité ;
- les directions, parcours, variantes et branches ;
- tous les arrêts, points d’arrêt, quais et terminus ;
- les courses, horaires, calendriers, jours fériés et périodes de service ;
- les géométries de parcours disponibles ;
- les changements programmés et les versions précédentes ;
- le lien vers le plan PDF officiel et la fiche horaire lorsqu’ils existent ;
- la source, la date de téléchargement, la licence et l’état de vérification.

Le numéro commercial seul n’est jamais une clé : il peut être réutilisé, renommé, déplacé ou exploité par un autre opérateur. Le jeu conserve les identifiants IDFM et les dates de début/fin.

### 4.2 Catalogue de dépôts / centres opérationnels bus

Un catalogue complet est à constituer pour les dépôts et COB qui exploitent les lignes IDFM, qu’ils soient exploités par la RATP, RATP Cap, Keolis, Transdev ou un autre transporteur francilien. Il faut distinguer :

- le site physique ;
- son nom actuel et ses anciens noms ;
- l’exploitant et le contrat en vigueur ;
- le réseau et les lignes réellement desservies ;
- les véhicules vus sur ce site, avec date et source ;
- les installations, capacités et énergies attestées ;
- les changements de site, transferts et périodes de validité.

Les noms de la capture envoyée sont repris comme **liste d’amorçage à réconcilier**, sans supposer que chaque entrée est un COB physique actuel ni que la capture contient tous les dépôts d’Île-de-France.

| Entrées reprises de la capture | Travail à faire dans le registre |
|---|---|
| Asnières, Aubervilliers, Belliard, Bords de Marne, Championnet, Charlebourg, Corentin, Créteil, Croix-Nivert, Flandre, Fontenay, Ivry, Lagny, Lebrun, Les Lilas, Les Pavillons, Malakoff, Massy, Michelet, Nanterre, Pleyel, Point du Jour, Saint-Denis, Saint-Maur, Thiais, Vitry, Villiers le Bel | Conserver le nom original, rechercher l’adresse et le site, puis confirmer s’il est actuel, historique, renommé ou associé à plusieurs activités. |
| VOO, GMR, BUS-STL, RATP-COM, RATP-DEV, Nanterre Transdev | Conserver ces noms tels quels et déterminer s’ils désignent un site, un exploitant, un réseau, un contrat ou une entrée historique. Ne pas les supprimer sur la seule base de leur intitulé. |

Cette capture est une source de libellés, pas un inventaire certifié. La RATP publie par exemple une liste de ses centres bus et distingue les installations électriques et biométhane ; elle signale aussi un nouveau centre à Villiers-le-Bel. Les sites de tous les exploitants ne sont pas réunis dans une table qui donne automatiquement chaque relation dépôt–ligne–bus. Le jeu doit donc rapprocher référentiels IDFM, contrats, exploitants, documents de site et observations de parc.

Chaque relation est tracée avec une preuve et un statut :

- **confirmée** : source officielle ou source d’exploitation claire ;
- **corroborée** : plusieurs sources datées concordent ;
- **à vérifier** : rattachement probable mais preuve insuffisante ;
- **historique** : vrai pour une période antérieure ;
- **non identifié** : données manquantes, sans invention.

Un dépôt peut être affiché dans le catalogue avant d’avoir toutes ses données, mais son niveau de complétude est visible. Une donnée incertaine ne doit jamais être présentée comme un fait vérifié.

### 4.3 Plans officiels des lignes

Pour chaque ligne, le système de données cherche le lien vers sa fiche horaire et son plan PDF officiel. Il conserve l’URL, le nom, l’identifiant de ligne, la date de collecte, la version du document et les conditions de réutilisation.

Dans le jeu :

- afficher le plan PDF officiel quand le document permet cet affichage ;
- sinon ouvrir le PDF depuis sa page source ;
- générer en parallèle un plan interactif original à partir des arrêts et tracés IDFM ;
- permettre au joueur de comparer la carte jouable au plan officiel ;
- ne pas intégrer de façon permanente les photos ou bases communautaires sans droits adaptés.

Le jeu de liens IDFM est un index utile des plans et horaires, mais chaque PDF doit garder ses propres conditions de réutilisation. Les cartes interactives du jeu sont redessinées depuis les géométries ouvertes.

### 4.4 Jeu de données et mises à jour

| Donnée | Utilisation | Précaution |
|---|---|---|
| GTFS IDFM | Lignes, arrêts, courses, horaires et calendriers | L’offre disponible est une fenêtre glissante ; archiver les versions utilisées par une partie. |
| Tracés commerciaux IDFM | Parcours de ligne sur la carte | Conserver la date et vérifier les écarts ou corrections géographiques. |
| Référentiel de lignes IDFM | Identifiants, noms et états de lignes | Ne pas fusionner des lignes au seul motif qu’elles ont le même numéro. |
| Contrats d’exploitation IDFM | Exploitant, lots et territoires | Un contour de contrat ne donne pas à lui seul le dépôt de chaque véhicule. |
| Liens vers les fiches horaires et plans IDFM | Référence documentaire et PDF | Vérifier les conditions propres aux PDF avant leur copie ou intégration. |
| Données de validation IDFM | Profils de demande agrégée | Ne pas inventer un comptage exact à chaque arrêt si le grain source ne le permet pas. |
| TC Infos | Modèles, fiches de véhicules, dépôts et états de parc observés | Source communautaire à dater et recouper ; respecter ses conditions d’usage. |
| DataBus / Busparisiens | Vérification de mutations et d’états de parc | Source communautaire de recoupement, pas un substitut à la preuve contractuelle. |
| Données des opérateurs et de marchés | Noms des sites, modèles, équipements et renouvellements | Garder les références et la date de publication. |

La donnée théorique, les observations de flotte et l’information trafic en direct sont trois couches distinctes. Elles ne doivent pas être confondues.

## 5. Scénario Bords de Marne : couverture complète et datée

Le scénario Bords de Marne charge le **réseau du contrat en entier** et ses centres opérationnels bus. La page du réseau indique 29 lignes, dont 7 Noctilien, et deux COB : Saint-Maur-des-Fossés et Neuilly-Plaisance. Ces nombres décrivent le lot ; ils ne signifient pas que chaque ligne ou chaque bus doit être affecté aux deux sites indistinctement.

La liste de contrôle de travail **avant la réorganisation** comprend les lignes régulières **101, 106, 107, 108, 110, 111, 112, 113, 114, 116, 118, 120, 124, 127, 201, 203, 210, 214, 221, 303, 306 et 520**, ainsi que les Noctilien **N11, N16, N32, N33, N34, N35 et N71**. Elle est recoupée avec le décompte du réseau, mais reste à confirmer à partir des identifiants, calendriers et parcours GTFS valides à la date de départ. Le GTFS daté — et non cette liste de contrôle — fait foi dans la partie.

À partir du **1er novembre 2026**, IDFM annonce la création de la ligne **314** entre Neuilly-Plaisance et la zone industrielle des Chanoux. L’offre est restructurée sur plus de vingt lignes ; les fréquences, amplitudes, horaires et itinéraires changent. La 210 modifie notamment son itinéraire à Fontenay-sous-Bois et Vincennes. Le scénario conserve donc une version avant et après le 1er novembre au lieu d’écraser les anciennes données.

Règles de réalisation :

1. importer toutes les lignes actives du lot pour la date choisie, pas une liste codée en dur ;
2. inclure les lignes de jour, Noctilien, variantes, branches et services spéciaux du contrat ;
3. associer chaque course au COB réellement plausible quand une source l’établit ;
4. conserver au niveau du lot les lignes dont la répartition entre Saint-Maur et Neuilly-Plaisance reste à confirmer, sans en cacher aucune ;
5. importer les plans PDF et créer l’affichage interactif pour chaque ligne ;
6. vérifier les changements du 1er novembre à partir des données datées et des fiches officielles ;
7. rendre visibles l’exploitant, le contrat et l’origine de chaque affectation.

Ainsi, le joueur peut gérer le lot Bords de Marne complet tout en choisissant ou en inspectant chacun des COB, sans attribuer arbitrairement toutes les lignes à un site unique.

## 6. Bus réels et marché de véhicules

### 6.1 Catalogue des modèles

Créer un catalogue de modèles séparé de la liste des véhicules individuels. Il couvre tous les modèles observés sur les lignes de bus d’Île-de-France : autobus standards, articulés, midibus, véhicules express et motorisations pertinentes. Les gammes à inclure suivent les données recensées et vérifiées dans les parcs franciliens, pas un catalogue mondial sans lien avec le réseau.

Pour chaque modèle et version, enregistrer :

- constructeur et nom commercial ;
- longueur, portes, capacité assise/debout et accessibilité ;
- motorisation, énergie, batterie ou autonomie ;
- consommation estimée et compatibilité de recharge/ravitaillement ;
- années de production et périodes de présence attestées en Île-de-France ;
- limites de ligne et de dépôt ;
- sources de la fiche technique et niveau de confiance ;
- visuel original dessiné pour le jeu ou ressource explicitement réutilisable.

### 6.2 Marché au démarrage

Le joueur démarre avec un dépôt, ses infrastructures et ses contrats, **mais sans bus automatiquement garés dans la cour**. Le parc jouable se construit en achetant des véhicules. La flotte historique sert de référence pour les modèles, capacités, énergies et compatibilités.

Le marché affiche dès le début tous les modèles recensés, avec une offre neuve seulement si le modèle est encore disponible en production ou dans un marché identifié ; les modèles anciens et retirés sont proposés en occasion, en collection ou en lot de pièces selon leur état. Le joueur voit toute la gamme, même si l’état et les conditions de vente diffèrent.

Le marché présente dès le début :

- les familles de modèles attestées dans les parcs franciliens ;
- des offres neuves ou d’occasion, selon le modèle et la date de partie ;
- le prix de base estimé, l’année, l’état, le kilométrage et les frais à venir ;
- le délai de livraison et la disponibilité ;
- l’autonomie, la capacité, l’accessibilité et les compatibilités avec les lignes et installations ;
- les coûts prévisibles d’énergie, d’entretien et de remplacement de batterie ;
- le niveau de confiance et la source de l’estimation.

### 6.3 Prix estimés, pas prix officiels

Aucun prix de jeu ne sera présenté comme un prix contractuel officiel d’un véhicule précis si la source ne donne pas cette information. Pour chaque modèle, créer un **prix de référence estimé en euros de l’année de la partie**, accompagné d’une fourchette et d’un niveau de confiance.

La valeur de marché est construite à partir, par ordre de priorité, des accords-cadres et avis d’achat publics, des études de coût de possession de la CATP, de l’année-modèle, de la motorisation, de l’équipement, de la capacité, de l’état et de l’usure. Comme simple repère de départ, une synthèse de 2026 cite environ **200 000 € pour un standard diesel de 12 m** et **450 000 à 600 000 € pour un standard électrique de 12 m** ; elle estime séparément les bornes de recharge à 30 000–90 000 € pièce. Ce sont des ordres de grandeur, pas les tarifs officiels des modèles IDFM ; le catalogue doit recalculer une estimation pour chaque modèle et année. Le prix de l’infrastructure — dépôt, chargeurs, station gaz ou renforcement électrique — reste séparé du prix du bus. Une estimation d’occasion baisse selon l’âge, le kilométrage, l’état et la durée de vie restante.

L’interface peut montrer, par exemple, « estimation : X–Y € — confiance moyenne — base de données 2026 ». Les valeurs doivent être équilibrées et modifiables dans les données de jeu ; les montants exacts sont établis par modèle au moment du catalogue. Les sources TC Infos et DataBus aident à identifier les véhicules et les configurations ; elles ne constituent pas une grille officielle de prix.

### 6.4 Achat, vente et renouvellement

- inspection avant achat et coût de remise en état ;
- possibilité de négocier ou de commander avec délai ;
- financement à crédit, apport, intérêts et échéances ;
- éligibilité d’un véhicule à une ligne et à un dépôt ;
- revente, déclassement et pièces détachées ;
- pannes et indisponibilités dès la mise en service ;
- comparaison du coût total de possession, pas uniquement du prix affiché.

## 7. Horloge et simulation continue

### 7.1 Vitesses

La barre de contrôle est toujours visible pendant la partie.

| Réglage | Avancement simulé | Utilisation |
|---|---:|---|
| Pause | 0 | Planifier et intervenir |
| ×1 | 1 seconde simulée par seconde réelle | Observer une exploitation au rythme réel |
| ×2 | 2 secondes par seconde | Accélération légère |
| ×5 | 5 secondes par seconde | Suivre un service sans attendre |
| ×10 | 10 secondes par seconde | Accélération courante |
| ×30 | 30 secondes par seconde | Suivre une heure de trafic |
| ×60 | 60 secondes par seconde | Une heure de jeu par minute réelle |
| ×300 | 300 secondes par seconde | Passer rapidement des périodes calmes |
| Prochain événement | Avance jusqu’au prochain événement programmé | Traiter le prochain départ ou incident |

Le joueur peut changer de vitesse à tout moment. La vitesse choisie change le temps simulé, pas les règles. Aucun changement de vitesse ne doit supprimer des passages aux arrêts, des événements ou des opérations comptables. La simulation se met en pause lorsque la partie est explicitement suspendue ; les règles de reprise après fermeture sont une préférence de partie, pas un effet caché.

### 7.2 Moteur événementiel

Un moteur à événements datés est préférable à une boucle qui recalcule toutes les données au même rythme d’affichage. Il programme les événements suivants et les traite dans l’ordre exact :

- départ, arrivée à un arrêt et fin de course ;
- montée, descente et attente de voyageurs ;
- kilométrage, consommation et usure ;
- revenus de service, charges et paie acquise ;
- retard, panne, fermeture de voie, arrêt déplacé et déviation ;
- intervention, arrivée de la dépanneuse, remorquage et réparation ;
- changement de planning, absence, relève et fin de service ;
- clôture journalière et versement contractuel.

Chaque événement écrit une entrée dans l’historique. Une graine de simulation sauvegardée permet de rejouer une partie de façon cohérente. Les bilans nocturnes sont des synthèses et ne servent pas de déclencheur unique aux revenus ou pannes.

## 8. Pannes, dépanneuses et machinistes en attente

### 8.1 Cycle complet d’une panne

Une panne est un événement daté qui modifie immédiatement l’état du bus, de la course, du machiniste, des voyageurs et du journal financier.

1. **Détection** : message sur la carte et dans le centre de contrôle, panne décrite et niveau de gravité.
2. **Mise en sécurité** : le bus se place au prochain point sûr, la course est marquée en retard ou interrompue.
3. **Chronomètre de prise en charge** : démarrage du temps d’attente du machiniste dès que le véhicule est immobilisé.
4. **Gestion voyageurs** : descente, attente, transfert ou remplacement par un véhicule de réserve ; indiquer les passagers retardés ou laissés à quai.
5. **Diagnostic et dispatch** : le responsable choisit réparation sur place ou remorquage. Le jeu cherche une dépanneuse disponible au dépôt ou à l’atelier le plus proche.
6. **Trajet de la dépanneuse** : calcul de la distance, de l’heure de départ et de l’ETA selon le réseau routier modélisé et l’état de circulation.
7. **Intervention** : réparer sur place avec durée et pièces, ou prendre en charge le bus et le remorquer au dépôt.
8. **Suite chauffeur** : relève, retour au centre ou attente encadrée selon le temps de travail et les contraintes de service.
9. **Retour du bus** : atelier, durée de réparation, coût, perte d’affectation, puis remise à disposition.

L’écran garde l’heure de panne, la durée d’attente déjà écoulée, l’ETA de la dépanneuse, le coût accumulé, le nombre de voyageurs et les conséquences sur la prochaine course. Le temps d’attente du machiniste est donc une donnée de jeu réelle, pas un message décoratif.

### 8.2 Modèle de fiabilité

La fréquence de panne dépend de l’âge, du kilométrage, des contrôles, de l’état de maintenance, de l’énergie et d’une part d’aléatoire contrôlée. Un entretien préventif réduit le risque sans l’annuler. Les pannes ne sont ni seulement nocturnes ni déclenchées de façon arbitraire.

Les catégories couvrent au minimum : incident mineur réparable en bord de route, défaut imposant un dépannage, panne immobilisante avec remorquage, incident avec bus indisponible pour une période longue. Le joueur peut régler la fréquence d’événements pour faciliter ou corser une partie.

### 8.3 Flotte de dépannage

Les dépanneuses sont des véhicules ou équipes du dépôt avec :

- localisation de départ ;
- disponibilité et durée d’intervention ;
- rayon et type de prise en charge ;
- temps de déplacement estimé ;
- coût fixe et coût par intervention ;
- état, entretien et éventuelle indisponibilité.

Si aucune équipe n’est disponible, l’attente augmente et le joueur choisit un prestataire externe, un renfort ou un remorquage différé. Un bus de réserve peut reprendre les courses si le conducteur, le véhicule, le délai et l’accès à la ligne le permettent.

## 9. Déviations, arrêts fermés et travaux

Une perturbation peut être créée par le jeu, déclenchée par le joueur ou importée comme information réelle lorsqu’une source officielle est disponible.

Chaque incident routier contient :

- début et fin prévus ou indéterminés ;
- lignes, directions, courses et arrêts touchés ;
- segment bloqué, cause et gravité ;
- arrêts supprimés ou déplacés ;
- arrêts de remplacement et distance piétonne ;
- tracé de déviation et temps supplémentaire ;
- contraintes d’accessibilité et d’exploitation ;
- message à transmettre aux voyageurs.

Effets simulés :

- les bus changent leur itinéraire à l’heure prévue ;
- les arrêts fermés ne prennent ni ne déposent de voyageurs ;
- les personnes déjà en attente sont transférées à l’ouverture de la fermeture ; les arrivants estimés suivants sont dirigés vers l’arrêt de remplacement si un message voyageurs est publié, sinon ils sont comptés comme laissés à quai ;
- les retards et kilomètres supplémentaires affectent les courses suivantes ;
- les horaires affichés et les notifications changent immédiatement ;
- l’incident est retiré automatiquement à sa fin ou prolongé par le joueur.

Les travaux planifiés permettent de préparer la déviation à l’avance. Les pannes, accidents, événements locaux et congestions peuvent imposer une déviation immédiate. Une ligne peut ainsi avoir plusieurs versions temporaires, indépendantes de son tracé permanent.

## 10. Information trafic réellement disponible

L’intégration temps réel externe est un complément, pas le moteur du jeu. Les API IDFM documentent les prochains passages SIRI Lite et les messages d’information trafic. Leur couverture de prochains passages est partielle et le périmètre disponible est mis à jour périodiquement ; l’accès aux API nécessite un compte PRIM et relève de la Licence Mobilité.

Règles d’usage :

- utiliser l’API, ses quotas et sa licence après vérification du compte et du droit d’utilisation ;
- présenter ses messages comme observations réelles datées, séparées des événements simulés ;
- ne pas promettre une position GPS de chaque bus : les sources consultées décrivent prochains passages et messages, pas une télémétrie complète de flotte ;
- garder le jeu jouable hors ligne ou quand l’API est indisponible ;
- simuler les pannes, les dépanneuses, les fermetures d’arrêts et les déviations de façon autonome pour couvrir tout le réseau ;
- proposer un mode « données réelles d’information trafic » activable, qui ne modifie pas silencieusement une partie sans avertissement.

## 11. Voyageurs, recettes et gestion de l’entreprise

### 11.1 Voyageurs

La demande est générée par période, arrêt, ligne, correspondances et événements locaux. Les validations agrégées servent à calibrer des profils ; elles ne permettent pas d’inventer des comptages exacts à chaque arrêt. L’interface étiquette les volumes qui sont estimés.

À chaque arrêt, le jeu calcule l’attente, les descentes, les montées, la capacité restante, les refus de montée et les correspondances manquées. Une déviation ou panne peut déplacer ou retarder les flux.

### 11.2 Recettes et charges en direct

Le journal financier se met à jour au moment de chaque événement : kilomètres parcourus, énergie consommée, service réalisé, voyageurs, coût de panne, heures machinistes, pénalité, achat et réparation. Les recettes acquises ou estimées sont visibles en direct, avec une distinction entre montant gagné, montant facturé et montant payé.

Le contrat détermine les contributions d’exploitation, les bonus/malus et le rôle des titres. Les validations de titres ne deviennent pas automatiquement une recette de caisse de l’opérateur. Le bilan quotidien et mensuel synthétise le journal sans retarder l’affichage des événements et coûts.

### 11.3 Systèmes de gestion complets

- contrats IDFM, qualité, offre commandée et kilomètres réalisés ;
- trésorerie, factures, crédit, échéances, achats et revente ;
- recrutement, planning, absences, formation, qualification, repos et paie ;
- disponibilité de l’atelier, maintenance préventive et réparations ;
- carburant, gaz, électricité, chargeurs, autonomie et énergie au dépôt ;
- voyageurs, billettique, satisfaction, accessibilité et information ;
- publicité, transport spécial et recettes accessoires ;
- investissements de dépôt, capacité, ateliers et équipements ;
- objectifs, audits, progression, historique et scénarios.

Les paramètres financiers et sociaux changent avec le contrat et la période ; les valeurs incertaines sont explicitement des règles de jeu.

## 12. Écrans nécessaires

1. **Menu du jeu** : nouvelle carrière, scénarios, continuer, importer et options.
2. **Sélection de COB** : carte IDF, recherche, filtres, exploitant, contrat, parc et niveau de données.
3. **Préparation de partie** : date, conditions de départ, argent, difficulté, incidents et vitesse.
4. **Carte d’exploitation** : lignes, arrêts, bus, dépanneuses, pannes, travaux et déviations.
5. **Centre de contrôle** : liste d’événements, ETA, lignes touchées, retards, messages et décisions.
6. **Fiche de dépôt** : plan du site, capacité, équipements, atelier, véhicules et coûts.
7. **Lignes et horaires** : parcours, plan PDF, services, horaires, fréquences et versions.
8. **Marché de véhicules** : modèles, prix estimés, états, offres, compatibilité et financement.
9. **Flotte et planning** : véhicule, conducteur, blocs de courses, réserves et conflits.
10. **Atelier** : état, pièces, panne, dépannage, file d’attente et réparation.
11. **Machinistes** : services, repos, absence, pause, relève et temps d’attente après panne.
12. **Voyageurs** : attente, charge, refus de montée, arrêts fermés et demande estimée.
13. **Finances et contrat** : recettes acquises, paiements, coûts, marge, qualité et bilan.
14. **Journal et progression** : historique, explications, objectifs, succès et améliorations.

## 13. Architecture de données et moteur

Entités principales :

**Depot**, **DepotAlias**, **Operator**, **OperatingContract**, **DepotLineEvidence**, **VehicleModel**, **MarketOffer**, **Vehicle**, **DepotVehicleHistory**, **Route**, **RouteVariant**, **Stop**, **StopTime**, **Trip**, **ServiceCalendar**, **LinePlanDocument**, **Driver**, **DutyBlock**, **PassengerCohort**, **Incident**, **StopClosure**, **Detour**, **RecoveryVehicle**, **TowCall**, **RepairJob**, **EnergyEvent**, **ContractPayment**, **LedgerEntry**, **SimulationEvent** et **NetworkVersion**.

Principes :

- séparer le référentiel IDFM du monde de la partie ;
- garder les dates de validité et les sources sur chaque donnée importée ;
- conserver le PDF ou son lien, son identifiant et son droit d’affichage ;
- garder les offres de marché et la flotte achetée par le joueur séparées ;
- enregistrer les événements par temps simulé et leur ordre ;
- sauvegarder vitesse, date, graine de simulation et version de données ;
- traiter l’import de données sans bloquer la carte ni l’horloge ;
- afficher les erreurs de rapprochement, doublons et correspondances incertaines.

## 14. Plan de réalisation

### Phase A — Inventaire exhaustif et provenance

- Récupérer les jeux IDFM de lignes, GTFS, tracés, contrats, plans, horaires et demandes agrégées.
- Constituer le registre de tous les sites bus des huit départements.
- Intégrer les 33 libellés de la capture et préserver les alias ou noms historiques.
- Croiser les sites, opérateurs, contrats, lignes, parcs et équipements.
- Inventorier les modèles de bus, fiches techniques, prix publics disponibles et droits des images.
- Mettre en place un catalogue de provenance et de dates.

**Acceptation :** aucun nom reçu n’est perdu ; le catalogue couvre tous les COB actuellement associés aux réseaux bus IDFM et distingue les données manquantes des données confirmées.

### Phase B — Projet Xcode et carte du jeu

- Créer le projet macOS natif en Swift.
- Réaliser le menu, le choix de scénario, la carte MapKit et les panneaux de gestion.
- Afficher les tracés, arrêts, dépôts et fiches de ligne.
- Importer les plans PDF ou leurs liens avec leurs conditions d’affichage.

**Acceptation :** un joueur peut ouvrir le jeu, choisir un COB sur la carte et voir les lignes et arrêts valides à sa date de partie.

### Phase C — Couverture des lignes de toute l’Île-de-France

- Importer toutes les lignes de bus, variantes, horaires et calendriers actifs.
- Charger les huit départements et tous les exploitants.
- Rattacher les plans officiels et créer la vue interactive.
- Versionner les changements de ligne et d’opérateur.

**Acceptation :** chaque ligne bus IDFM active est retrouvable par identifiant source, date, réseau et opérateur ; chaque ligne présente son tracé, ses arrêts, ses services et une référence à son plan officiel ou explique l’absence de document.

### Phase D — COB complets et scénario Bords de Marne

- Réconcilier tous les dépôts et opérateurs.
- Compléter les deux COB de Bords de Marne et leurs lignes du lot entier.
- Charger les lignes et PDF avant et après le 1er novembre 2026.
- Affecter les lignes à chaque site avec preuve et période de validité.

**Acceptation :** le scénario comprend toutes les lignes Bords de Marne et les deux COB ; aucune liste limitée à 113/114/116/120/210 n’est utilisée comme couverture du réseau.

### Phase E — Marché et parc de véhicules

- Créer le catalogue complet de modèles franciliens.
- Établir la fourchette de prix estimée et son niveau de confiance.
- Construire achat, occasion, inspection, financement, livraison et revente.
- Démarrer la carrière avec dépôt vide et modèles disponibles sur le marché.

**Acceptation :** aucun bus historique n’est placé automatiquement dans le dépôt de départ ; chaque offre indique son modèle, sa compatibilité et son estimation de prix datée.

### Phase F — Horloge et circulation

- Implémenter ×1 réel, ×2, ×5, ×10, ×30, ×60, ×300, pause et prochain événement.
- Simuler les départs et passages à chaque arrêt.
- Gérer les blocs de courses, battements, réserves, retards et fins de service.

**Acceptation :** à ×1, une seconde simulée correspond à une seconde réelle ; à toute vitesse supérieure, aucun événement planifié n’est ignoré.

### Phase G — Incidents en temps réel simulé

- Implémenter panne, diagnostic, appel, arrivée de dépanneuse, attente machiniste et réparation/remorquage.
- Implémenter fermeture d’arrêt, travaux, accident, déviation, itinéraire de remplacement et messages voyageurs.
- Mettre à jour retards, services, voyageurs, recettes et charges au fil des événements.

**Acceptation :** une panne en cours de partie immobilise le bus immédiatement, lance un chronomètre d’attente, affecte les voyageurs et fait apparaître une ETA de dépannage ; une fermeture d’arrêt change le service et les horaires sans attendre minuit.

### Phase H — Contrats, voyageurs et entreprise complète

- Compléter demande, capacité, satisfaction et qualité.
- Ajouter coûts, recettes, contrats, trésorerie, crédit, paie et finances.
- Ajouter investissements, progression, objectifs, sauvegarde, tutoriel et difficulté.

**Acceptation :** chaque montant du bilan peut être relié à une course, un véhicule ou un événement ; un joueur peut mener une carrière complète et sauvegarder/reprendre sa partie.

### Phase I — Données trafic externes et robustesse

- Ajouter les messages trafic et prochains passages PRIM lorsqu’une autorisation et un accès API sont configurés.
- Isoler les données observées des événements de jeu.
- Tester le jeu sans Internet et traiter les erreurs d’import ou d’API.
- Vérifier les sauvegardes sur plusieurs dates de réseau et versions de données.

**Acceptation :** une API indisponible ne bloque ni la partie, ni les événements simulés, ni la couverture de lignes.

## 15. Définition de la version complète

La première version complète n’est pas définie par un seul dépôt. Elle doit réunir :

- le jeu macOS natif, jouable dans Xcode et sur Mac ;
- le catalogue complet des COB qui exploitent les lignes IDFM, sur toute l’Île-de-France ;
- toutes les lignes de bus actives avec tracés, arrêts, services, calendriers et plans officiels référencés ;
- un scénario Bords de Marne complet et daté avec ses deux COB et toutes les lignes du contrat ;
- le marché des modèles franciliens, avec prix d’achat estimés et pas de flotte offerte automatiquement ;
- une carte Apple MapKit interactive ;
- une horloge qui respecte le rapport réel à ×1 et accélère sans sauter de calculs ;
- des pannes, dépanneuses, temps d’attente machinistes, déviations et arrêts fermés traités au moment où ils arrivent ;
- voyageurs, RH, finances, énergie, maintenance, contrats et progression reliés à la même simulation.

## Sources de référence

### Données IDFM et Bords de Marne

- IDFM — [Offre théorique GTFS](https://prim.iledefrance-mobilites.fr/fr/jeux-de-donnees/offre-horaires-tc-gtfs-idfm)
- IDFM — [Tracés commerciaux des lignes régulières de bus](https://data.iledefrance-mobilites.fr/explore/dataset/traces-des-lignes-regulieres-de-bus-en-ile-de-france/)
- IDFM — [Référentiel des lignes](https://data.iledefrance-mobilites.fr/explore/dataset/referentiel-des-lignes/)
- IDFM — [Contours des contrats bus](https://prim.iledefrance-mobilites.fr/fr/jeux-de-donnees/contours-des-contrats)
- IDFM — [Fiches horaires et plans des lignes](https://prim.iledefrance-mobilites.fr/fr/jeux-de-donnees/fiches-horaires-et-plans)
- IDFM — [Lignes Bords de Marne : réorganisation au 1er novembre 2026](https://www.iledefrance-mobilites.fr/actualites/locales/detail/a-compter-du-1er-novembre-2026-ile-de-france-mobil)
- TC Infos — [Réseau IDF Mobilités – Bords de Marne](https://tc-infos.fr/reseau/1452)
- Réseau de bus Bord de Marne — [liste de lignes de contrôle, source secondaire à vérifier dans le GTFS](https://fr.wikipedia.org/wiki/R%C3%A9seau_de_bus_Bord_de_Marne)
- IDFM — [Rôle et fonctionnement d’un centre opérationnel bus](https://www.iledefrance-mobilites.fr/actualites/cob-mode-d-emploi--a-la-decouverte-d-un-centre-operationnel)
- RATP — [Centres bus, motorisations et nouveau centre de Villiers-le-Bel](https://www.ratp.fr/programme-bus2025)

### Données temps réel, tarifs, demande et véhicules

- PRIM — [API des prochains passages en temps réel](https://prim.iledefrance-mobilites.fr/fr/apis/idfm-ivtr-requete_globale)
- PRIM — [Périmètre des lignes et arrêts disponibles en temps réel](https://prim.iledefrance-mobilites.fr/fr/jeux-de-donnees/perimetre-des-donnees-tr-disponibles-plateforme-idfm)
- PRIM — [Messages d’information trafic](https://prim.iledefrance-mobilites.fr/fr/jeux-de-donnees/idfm-navitia-line_reports-v2)
- PRIM — [Tarifs IDFM](https://prim.iledefrance-mobilites.fr/fr/jeux-de-donnees/titres-et-tarifs)
- PRIM — [Historique des validations sur le réseau de surface](https://prim.iledefrance-mobilites.fr/fr/jeux-de-donnees/histo-validations-reseau-surface)
- CATP — [Étude comparative des motorisations et coûts de possession, mise à jour 2024](https://www.catp.fr/bus-et-cars/actualisation-de-letude-comparative-sur-les-differentes-motorisations-de-la-catp-4eme-mise-a-jour)
- Hellio — [Synthèse de repères de prix bus 12 m, source secondaire citant la CATP](https://www.hellio.com/actualites/conseils/prime-bus-electrique)
- TC Infos — [Parc Bords de Marne](https://tc-infos.fr/reseau/1452/parc-bus-cars/page1)
- Busparisiens — [États de parc](https://www.busparisiens.fr/forum/databus-optile-etats-de-parc-t102576.html) et [mutations et transferts](https://www.busparisiens.fr/forum/databus-optile-mutations-et-transferts-t102281-720.html)
- TC Infos — [Mentions légales](https://carto.tc-infos.fr/mentions-legales)

### Développement et cartographie

- Apple — [MapKit for SwiftUI](https://developer.apple.com/documentation/mapkit/mapkit-for-swiftui)
- Apple — [MapPolyline](https://developer.apple.com/documentation/mapkit/mappolyline)
- Apple — [SpriteKit](https://developer.apple.com/documentation/spritekit)
- Île-de-France Mobilités — [Licences des données PRIM](https://prim.iledefrance-mobilites.fr/fr/licences)
- OpenStreetMap — [Politique d’utilisation des tuiles publiques](https://operations.osmfoundation.org/policies/tiles/)

