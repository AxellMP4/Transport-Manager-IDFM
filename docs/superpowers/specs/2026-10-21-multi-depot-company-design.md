# Jeu d’exploitation multi-dépôts

## Intention

Faire de Transport Manager IDFM un jeu de gestion d’exploitation inspiré du principe de Transport Manager : le joueur dirige une entreprise de transport, choisit ses dépôts, affecte ses lignes, achète et suit ses bus, organise les conducteurs et pilote l’exploitation. Le réseau, les itinéraires, les arrêts et les horaires viennent des données IDFM réelles.

## Objectifs

- Donner un accès direct à tous les dépôts recensés, avec recherche par nom, ville, réseau et statut.
- Permettre à une même partie d’exploiter plusieurs dépôts et de basculer entre eux sans perdre le contexte du dépôt actif.
- Afficher pour chaque dépôt ses lignes, cartes de parcours, plans et fiches horaires disponibles.
- Afficher les bus de la partie sur la carte et dans le parc du dépôt correspondant, avec modèle, coquille, conducteur et kilométrages.
- Distinguer clairement les rattachements COB documentés, partagés, partiels, observés et candidats.
- Conserver les dépôts sans preuve de rattachement en consultation et montrer les lignes du contrat comme candidates, sans les attribuer fictivement à chaque COB.

## Principe de données

Le GTFS IDFM établit les routes, courses, arrêts et heures de service. Le référentiel IDFM relie les lignes commerciales aux contrats. Les sources publiques de COB sont de granularité variable : certaines donnent un centre unique ou une ligne particulière, d’autres ne donnent que le nombre de lignes d’un lot ou la liste des centres d’un contrat.

Une ligne qui n’a qu’une preuve de contrat reste disponible à l’échelle du contrat et candidate pour chaque COB de ce contrat. Elle ne devient une affectation opérationnelle à un dépôt que si une source datée l’établit ou si le joueur la choisit comme décision de gestion dans la partie. Une affectation de jeu par le joueur doit rester distincte de la preuve historique publique.

Les documents et horaires sont résolus par identifiant de ligne IDFM et version de réseau. Une absence de PDF ou de course active est affichée explicitement ; elle ne doit pas masquer la ligne.

## Modèle de partie

- Une carrière possède une entreprise, un ou plusieurs contrats et un ensemble de dépôts gérés.
- Le dépôt actif est un contexte d’interface ; il ne remplace pas le dépôt d’attache de chaque bus.
- Chaque bus conserve son dépôt d’attache, sa coquille, son kilométrage et son état. Les affectations de course référencent une ligne et un dépôt de départ.
- Les conducteurs et les affectations de service sont associés au dépôt où leur service commence.
- Les pannes, dépannages, retours, atelier et infrastructures utilisent le dépôt du véhicule concerné.
- Les soldes et rapports financiers restent consolidés pour l’entreprise et peuvent être filtrés par dépôt lorsque les enregistrements le permettent.
- Les sauvegardes existantes à un dépôt restent lisibles et migrent vers une entreprise ne contenant que ce dépôt.

## Interface

- Un sélecteur « Dépôts » reste visible pendant la partie et permet de passer directement d’un dépôt géré à l’autre.
- Un répertoire séparé donne accès à tous les autres sites en consultation et explique leur statut.
- Le panneau du dépôt actif regroupe sa carte, ses lignes et ses bus. Les plans et horaires s’ouvrent depuis la ligne ou l’arrêt concerné.
- Les onglets de gestion sont des espaces dédiés : Réseau, Lignes, Affectations, Parc, Personnel, Dépôts, Rapports, Incidents et Sources.
- Chaque ligne et chaque centre affichent leur niveau de preuve et la période de validité.

## Garde-fous

- Ne pas déduire l’affectation d’une ligne à un COB de sa proximité géographique, d’un numéro de ligne ou du seul contrat.
- Ne pas rendre un site projet opérationnel avant une preuve de mise en service.
- Ne pas démarrer un service sans course GTFS pour la date choisie.
- Ne pas faire partir un bus d’un autre dépôt sans trajet à vide explicite et faisable.
- Garder les nouveaux champs de sauvegarde compatibles avec les carrières existantes.

## Vérification attendue

- Choisir chaque dépôt recensé depuis le répertoire et voir son identité, son contrat, ses lignes connues et les quatre compteurs de couverture (GTFS, tracés, plans, horaires).
- Dans une carrière multi-dépôts, changer le dépôt actif et vérifier que lignes, parc, affectations et marqueurs de bus suivent le dépôt choisi.
- Vérifier qu’un bus acheté ou transféré à un dépôt conserve ce rattachement après sauvegarde et reprise.
- Vérifier une carrière historique à dépôt unique et un COB sans affectation publique.
- Compiler l’application macOS. Aucun test automatisé ne sera ajouté ou lancé sans demande de l’utilisateur.
