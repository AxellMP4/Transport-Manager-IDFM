# Suivi des alertes trafic PRIM

## Intention

Quand le joueur consulte les messages trafic PRIM d’une ligne exploitée, les nouveaux rapports doivent apparaître automatiquement dans l’historique des incidents de la carrière. Aujourd’hui, ils ne vivent que dans la vue de ligne; le joueur doit cliquer sur chaque rapport pour ouvrir le préparateur de déviation et peut perdre cette liste en changeant de vue.

## Règle de jeu

- Une consultation PRIM réussie sur une ligne actuellement exploitée enregistre ses rapports comme alertes persistantes de la carrière.
- Une alerte conserve le rapport source, l’`ID_Line`, la route GTFS choisie, l’heure de première et dernière consultation, la source et la licence.
- Les rapports sont dédupliqués par `ID_Line` canonique et identifiant de rapport. Une nouvelle consultation actualise le rapport et `lastSeenAt`; elle ne crée pas une seconde alerte.
- Les périodes d’application échues restent consultables mais ne proposent pas de déviation. Une période absente reste non évaluée et ne peut pas être présentée comme active.
- Dans l’onglet Incidents, une alerte non traitée propose « Préparer une déviation » et « Ignorer ». Préparer ouvre l’éditeur MapKit existant, prérempli avec la provenance PRIM. L’alerte n’altère pas le service, les courses ou la demande avant l’enregistrement de la déviation par le joueur.
- Une déviation enregistrée depuis une alerte la marque comme traitée et conserve l’identifiant de la déviation liée. Ignorer conserve l’alerte dans l’historique avec son état.

## Contraintes et compatibilité

- Les appels PRIM restent déclenchés à la demande et requièrent le jeton du joueur dans le trousseau macOS.
- Seules les lignes opérées par la carrière active peuvent créer des alertes de carrière.
- L’ajout à `SimulationSession` est optionnel pour lire les sauvegardes existantes.
- L’observation externe reste distincte de l’événement simulé; aucun texte ni requête n’est envoyé à IDFM.
- La qualité et le contenu des alertes réelles ne peuvent pas être vérifiés sans jeton PRIM.

## Hors périmètre

- Interroger PRIM automatiquement ou périodiquement sans action du joueur.
- Créer ou activer automatiquement une déviation, modifier une course, facturer des frais ou changer la demande voyageurs.
- Déduire le comportement de la demande à partir d’un message voyageurs.

## Appel d’implémentation

Conserver les alertes dans `SimulationSession`, avec un état persistant (`à traiter`, `déviation planifiée`, `ignorée`). Réutiliser `RouteDetourEditorView` et l’import PRIM existants plutôt que créer un second mécanisme de déviation. Les rapports expirés restent dans l’historique et sont bloqués à l’action. Ajouter l’état des alertes à l’historique Incidents, sans réorganiser le traitement des pannes de bus.
