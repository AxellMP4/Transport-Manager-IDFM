# Repos avancés des machinistes — cadrage produit

**État : périmètre limité approuvé le 1er novembre 2026.** Rendre lisibles les règles de jeu déjà présentes et garder leur contrôle commun. Ne pas ajouter de repos hebdomadaire, de limite de jours consécutifs ni de seuil présenté comme légal. Les règles existantes restent des règles de simulation.

## Intention

Le cahier des charges demande de gérer services, repos, absences, pauses, relèves et attente après panne. Le jeu couvre déjà plusieurs de ces sujets, mais ne spécifie pas de repos hebdomadaire ni de règles de repos au-delà des limites fixes de ses blocs. Ce document sépare les comportements observables du choix de ce que « repos avancé » doit ajouter.

## Comportements déjà implémentés

- Un bloc de service peut réunir des courses dont le battement successif ne dépasse pas 2 heures; la durée de présence entre le début et la fin du bloc ne dépasse pas 10 heures.
- Deux blocs distincts d’un même machiniste sont séparés par au moins 11 heures de repos de jeu.
- Une pause de jeu de 30 minutes peut être planifiée dans un battement libre entre deux courses du même bloc. Elle est conservée et déduite des heures rémunérées.
- La formation à la qualification articulée dure 8 heures simulées et utilise le taux horaire estimé existant. Elle est traitée comme une période d’activité et respecte le repos de jeu de 11 heures de part et d’autre.
- Les absences planifiées ne peuvent chevaucher les services ou formations concernés. Les congés, arrêts maladie simulés et absences non rémunérées ont les facteurs de rémunération de jeu déjà documentés; les heures affectées sont estimées par le joueur.
- Les affectations et corrections peuvent rouvrir ou prolonger certains blocs déjà soldés. La paie acquise reste conservée; le moteur ne facture que le complément lors du règlement suivant.
- Les services, blocs, pauses, absences, formations et écritures de paie sont stockés dans les champs de session Codable existants; plusieurs collections sont optionnelles afin que les anciennes sauvegardes restent décodables.

Sources de vérification : `docs/Plan_recreation_Transport_Manager_IDFM.md` (sections 11.3, 12 et Phase F), `docs/IMPLEMENTATION_STATUS.md` (paragraphe « blocs machinistes »), `TransportManagerIDFM/Domain/VehicleMarket.swift` (`MachinistWorkRules`) et `TransportManagerIDFM/Domain/SimulationEngine.swift` (validation des blocs, formations, pauses, absences et règlement de paie).

## Objectifs si une extension est approuvée

- Faire apparaître clairement au joueur le repos déjà écoulé ou requis autour des services et activités enregistrés.
- Appliquer une règle unique aux nouveaux services, relèves, reprises après panne, transports spéciaux, recalages de détours, formations et corrections de blocs, sans divergence entre le sélecteur et le moteur.
- Expliquer un refus d’affectation par le conflit ou le repos manquant, sans changer rétroactivement les montants déjà réglés.
- Préserver les carrières existantes, l’export/import JSON et la synchronisation de la même sauvegarde entre Mac et iPhone.

## Hors périmètre

- Revendiquer une conformité réglementaire ou reproduire une convention collective sans source et validation adaptées.
- Modifier les taux horaires, les règles de congé, les absences, le salaire, les événements de circulation ou les objectifs de carrière.
- Inférer les heures de travail non enregistrées par le jeu ou générer un planning de poste qui n’existe pas.
- Ajouter des seuils de repos hebdomadaire, des limites de jours consécutifs ou une période de référence sans décision produit explicite.

## Décision approuvée

Présenter le temps restant et la date/heure de fin du repos de jeu dans la liste du personnel, en indiquant s’il suit un service ou une formation. Le moteur conserve ses contrôles bloquants actuels : battement maximal de 2 h dans un bloc, présence maximale de 10 h et repos minimal de jeu de 11 h entre blocs et autour des formations. Paie, activité passée et compatibilité des anciennes sauvegardes gardent leur comportement.

## Portée laissée ouverte

Toute future extension au repos hebdomadaire, aux jours consécutifs, à une nouvelle période de référence ou à de nouveaux comportements de blocage demande une nouvelle décision produit. Elle devra préciser les activités comptées et le traitement des corrections historiques avant tout changement de simulation.

## Critères de préparation du plan

Le changement limité d’interface utilise l’horloge simulée et les fins de service/formation déjà persistées. Il ne modifie pas les événements passés, les blocs soldés, la paie, la persistance ou les sélecteurs d’affectation. Les validations moteur restent la référence pour les actions.
