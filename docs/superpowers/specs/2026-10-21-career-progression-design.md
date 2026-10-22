# Progression de carrière — choix de conception

## Intention

Le jeu possède un parcours de démarrage qui explique l’achat d’un bus, le recrutement, la première course et le premier bilan. Il lui manque une progression durable qui récompense les étapes d’exploitation et aide le joueur à se fixer des objectifs sur plusieurs journées.

## Règles retenues

- Les jalons sont déclenchés uniquement par des faits déjà enregistrés dans la sauvegarde : livraison de véhicule, recrutement, courses réellement terminées, bilans, réparations, investissements, qualité journalière et règlements de facture.
- Un jalon est attribué une fois par carrière. Sa date est celle de l’événement ou du bilan qui l’a validé, jamais l’heure système de consultation.
- Les anciennes sauvegardes sans état de progression reconstituent leurs jalons à partir de leur historique, de leurs machinistes, de leurs bilans et de leurs factures déjà enregistrés. Une course planifiée ou une course de remplacement encore en route ne compte pas comme terminée.
- Les jalons donnent des points de progression de jeu, sans prime en euros et sans effet sur le montant des contrats, les factures ou la trésorerie.
- Quatre niveaux sont définis : Nouvel exploitant (0 point), Réseau en service (40), Gestionnaire confirmé (120) et Référence régionale (220).
- Tous les jalons restent visibles. Ceux dont le rang requis n’est pas atteint sont présentés comme verrouillés avec le rang nécessaire. Leur critère peut être rempli en avance ; les points sont attribués au premier rang admissible et la date conservée reste celle de l’événement d’origine.
- Les fonctionnalités existantes restent toutes accessibles, et aucune relation COB ou condition contractuelle n’est débloquée par le niveau.
- Les points et les niveaux sont un système de progression fictif clairement présenté comme tel. Ils n’imitent aucun classement ou bonus IDFM.
- Le jalon de production utilise le `contractCompletionRate` sauvegardé lorsqu’il existe. Pour les autres carrières, le taux de jeu est le nombre de courses terminées divisé par le maximum entre les départs assurés et non assurés réunis, et les courses terminées ; le dénominateur doit être supérieur à zéro.
- Les fins de course proviennent des trois événements historiques de fin de service actuels et de l’ancien événement `.serviceCompleted` pour les sauvegardes antérieures. Les événements en attente ne sont jamais comptés.
- Un jalon de bilan utilise l’heure de son événement historique `dailySettlement`. Si une sauvegarde ancienne n’a pas cet événement, sa date est le début de la date locale du `dateKey`, dans le fuseau Europe/Paris.
- La réconciliation intervient au chargement, à l’import, après le traitement d’un événement, avant la sauvegarde et avant l’export.

## Jalons

| Niveau requis | Jalon | Critère | Points |
|---:|---|---|---:|
| 1 | Premier bus reçu | Un événement de livraison a été traité | 10 |
| 1 | Première recrue | Un machiniste est enregistré | 10 |
| 1 | Première course terminée | Une fin de service réelle est dans l’historique | 20 |
| 1 | Premier bilan quotidien | Un bilan de journée est enregistré | 20 |
| 2 | Dix courses terminées | Dix fins de service sont enregistrées | 25 |
| 2 | Sept bilans quotidiens | Sept bilans journaliers sont enregistrés | 30 |
| 2 | Vingt-cinq courses terminées | Vingt-cinq fins de service sont enregistrées | 35 |
| 3 | Première panne réparée | Une réparation de panne est terminée | 20 |
| 3 | Premier investissement achevé | Une extension d’atelier ou une installation énergétique est terminée | 20 |
| 3 | Journée de production tenue | Un bilan enregistre au moins 98 % de production | 25 |
| 3 | Première facture réglée | Une facture de jeu a une date de règlement | 15 |
| 3 | Cinquante courses terminées | Cinquante fins de service sont enregistrées | 50 |

## Architecture

Un état optionnel Codable est ajouté à `SimulationSession`. Il conserve les identifiants stables des jalons, leurs dates d’obtention et leurs points. Un catalogue pur calcule les conditions et les valeurs de progression depuis la session, puis réconcilie de façon idempotente les nouveaux jalons avec l’état sauvegardé.

La réconciliation s’effectue lors des sauvegardes, après le traitement des événements et à la reprise d’une ancienne sauvegarde. Les événements de fin de course, les bilans et les échéances sont évalués à partir de `eventHistory` ou des enregistrements effectivement réglés, jamais à partir d’événements futurs encore en attente.

## Interface

Ajouter **Progression** à l’espace **Rapports** pour garder la navigation principale actuelle. L’écran présente le niveau, les points, la progression vers le prochain niveau, les jalons et leur état, puis l’historique des réussites. Au rang maximal, il indique que le rang est atteint sans afficher de prochain niveau. Les icônes et libellés textuels portent l’état en plus de la couleur.

Le bloc actuel devient **Démarrage de carrière** afin de distinguer le tutoriel des niveaux durables.

## Hors portée

Cette tranche ne crée pas de primes financières, de nouvelles obligations contractuelles, de relations COB, de scénarios ni de restrictions de fonctionnalités. Les nouveaux contrats et leur déblocage resteront à concevoir avec leurs propres données et règles avant d’affecter une carrière.
