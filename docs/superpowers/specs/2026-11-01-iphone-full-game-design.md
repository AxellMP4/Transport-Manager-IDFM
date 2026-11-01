# Jeu complet sur iPhone — design

## Intention

Faire de l’iPhone une vraie plateforme de jeu pour Transport Manager IDFM : créer ou reprendre une carrière, suivre l’exploitation sur une carte, gérer les autobus et les machinistes, consulter les rapports et travailler avec les mêmes données réseau que la version macOS.

## État constaté

- L’entrée iOS lance actuellement `MobileOperationsView`, un parcours distinct et simplifié.
- Cet écran expose Carrière, Courses, Réseau, Parc et Finances. « Réseau » ne montre qu’une liste de routes; il n’y a pas de carte opérationnelle. La liste de flotte ne donne pas accès aux outils complets de maintenance, d’atelier, d’énergie et d’inspection.
- `OperationsDashboardView` est la source de référence du jeu complet : Carte, Courses / Motifs, Lignes, Affectations, Parc, Personnel, Dépôts, Rapports, Incidents et Sources. Ces espaces utilisent déjà `SimulationEngine`, `NetworkLibrary`, MapKit, les sauvegardes et les données intégrées.
- Le projet vise iOS 17+. L’onglet système et l’accessoire de lecture utilisent Liquid Glass et les API iOS 26 quand elles sont disponibles.

## Décisions de conception

- Réutiliser `OperationsDashboardView` comme tableau de bord partagé plutôt que maintenir deux implémentations métier divergentes. Le parcours de lancement, la carrière, le moteur, les données, les règles et les actions de gestion restent ceux du jeu complet.
- Sur iPhone, grouper les dix espaces dans cinq onglets système : **Carte** (`network`), **Courses** (`assignments`), **Parc** (`fleet`, `staff`, `depots`), **Rapports** (`reports`, `incidents`) et **Réseau** (`lines`, `coursesMotifs`, `sources`). Les sections secondaires restent toutes accessibles par un sélecteur compact.
- Sur iOS 26+, garder la barre d’onglets native Liquid Glass et placer pause/reprise, vitesse, heure simulée et avance au prochain événement dans l’accessoire inférieur. Sur iOS 17–25, garder les mêmes actions dans une présentation système compatible.
- En largeur compacte, la carte occupe l’espace disponible; la liste des lignes devient un panneau présenté à la demande. Les détails de bus, d’arrêt, d’incident et les éditeurs restent atteignables sous forme de feuilles adaptées au téléphone. L’iPad conserve une présentation plus large quand l’espace le permet.
- Garder la sauvegarde locale et les imports/exports JSON. Le build Debug iPhone sur équipe personnelle reste sans CloudKit; une équipe qui provisionne iCloud garde la synchronisation du build Release.

## Critères d’acceptation

1. Les cinq onglets donnent accès aux dix espaces actuels, sans supprimer d’action du jeu complet.
2. Une carrière peut être créée/reprise/importée; ses courses, arrêts, lignes et bus utilisent la même partie et les mêmes versions réseau épinglées que macOS.
3. La carte iPhone affiche les tracés, les arrêts, les bus en mouvement et les couches d’incident existantes; toucher un élément ouvre son détail et ses actions disponibles.
4. Le parc iPhone expose les fonctions du marché et de gestion existant : achat, inspection, état et opérations d’atelier, énergie, maintenance, retour/remorquage; Personnel donne accès au recrutement et à la gestion des machinistes.
5. Rapports, voyageurs, finances, paie, progression et incidents restent consultables, avec les mutations disponibles dans la version complète.
6. Les contrôles principaux restent visibles et utilisables en portrait iPhone; feuilles et commandes ne dépassent pas la largeur de l’écran. Les variantes iOS 17–25 et iOS 26+ gardent les mêmes fonctions.
7. Validation : smoke de couverture de navigation, compilation iOS et macOS, vérifications existantes ciblées, puis lancement réel sur l’iPhone avant de déclarer la version jouable.

## Limites externes connues

- Un compte Apple connecté dans Xcode et une identité Apple Development sont nécessaires pour signer l’application sur l’iPhone.
- À la dernière tentative, `devicectl` n’atteignait pas l’iPhone car `CoreDeviceService` expirait pendant son initialisation. Cette limite devra être retentée après rétablissement de la signature et de la connexion appareil.
- Une équipe personnelle ne peut pas provisionner iCloud; la sauvegarde locale reste donc le chemin Debug sur cet appareil.
