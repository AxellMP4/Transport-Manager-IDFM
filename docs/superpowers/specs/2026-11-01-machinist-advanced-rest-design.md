# Repos avancés des machinistes — cadrage à approuver

**État : brouillon à faire approuver.** Aucun comportement de simulation n’est modifié par ce document. Les règles de jeu existantes ne sont pas présentées comme des normes de droit du travail.

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

## Décisions nécessaires avant une implémentation

1. **Portée :** veut-on uniquement mieux présenter et contrôler les repos déjà modélisés, ou ajouter une nouvelle règle de repos hebdomadaire / jours consécutifs ? Le cahier des charges ne tranche pas.
2. **Période :** si une nouvelle règle hebdomadaire est voulue, quelle fenêtre de calcul faut-il utiliser (période glissante ou semaine calendaire), et quelles activités enregistrées comptent comme du travail ?
3. **Application :** une violation éventuelle doit-elle bloquer l’action, avertir le joueur avec possibilité de continuer, ou rester informative ?
4. **Historique :** lorsqu’une correction autorisée rouvre un bloc ancien, doit-elle être évaluée contre les règles actuelles ou seulement contre les règles en vigueur à la date du service ?

Ces réponses changent le modèle de dates, la validation des actions, l’explication de l’interface et la couverture de compatibilité des sauvegardes. En leur absence, un développeur ne doit ni ajouter un seuil ni choisir silencieusement une fenêtre ou un comportement de blocage.

## Critères de préparation du plan

Après approbation des décisions ci-dessus, le plan d’implémentation devra préciser : les intervalles exacts concernés, la source d’horloge simulée, la politique sur événements passés et blocs soldés, les effets nuls ou non sur la paie, la persistance/migration, l’équivalence des sélecteurs et des validations moteur, ainsi que des cas de sauvegardes historiques. Les seuils devront être présentés comme des règles de jeu à moins qu’une source officielle et une revue spécialisée ne justifient une autre qualification.
