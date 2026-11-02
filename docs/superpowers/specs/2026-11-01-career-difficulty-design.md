# Proposition de difficulté à la création d’une carrière

**État : approuvée et implémentée le 1er novembre 2026.** Les smokes domaine et d’intégration, les builds Debug macOS/iPhoneOS et les contrôles plist passent. L’inspection visuelle sur appareil reste ouverte car CoreSimulator est indisponible. Cette proposition ne constitue pas une règle de contrat IDFM. Les multiplicateurs et capitaux ci-dessous sont des valeurs de réglage de jeu, pas des valeurs observées chez un opérateur.

## Objectif

Ajouter au parcours de préparation de carrière demandé par le cahier des charges une difficulté compréhensible avant de lancer la partie. Le choix doit avoir des effets observables dans la simulation, rester compatible avec les sauvegardes et être disponible sur macOS et iPhone.

Le jeu ne dispose pas d’un modèle de difficulté existant. Il dispose toutefois de deux familles de paramètres cohérentes avec une difficulté de démarrage : le capital initial et les fréquences des incidents de véhicules et des perturbations routières fictives. Les coûts, rémunérations et contributions restent des règles communes à toutes les carrières tant qu’un barème réel et une décision produit ne justifient pas leur variation.

## Paramètres actuels pertinents

- `VehicleMarketCatalog.initialCareerCapital` vaut actuellement 1 000 000 €. Le moteur débite séparément le stock initial de pièces de cette somme; le solde de départ est donc `capital de départ − VehicleWorkshopPartCatalog.initialStockCostEuro`.
- `VehicleIncidentFrequency` expose `reduced`, `standard` et `increased`, avec des multiplicateurs de risque respectifs de 0,5, 1 et 2.
- `TrafficDisruptionFrequency` expose les mêmes multiplicateurs, ainsi qu’un mode sans événement. Il ne s’agit que de congestions, travaux et accidents fictifs produits par le jeu.
- Les deux fréquences sont déjà enregistrées par carrière et restent modifiables dans les options. Les coûts de véhicules, d’énergie, de paie, de maintenance et les règles de règlement sont communs à la partie; aucun montant annuel de rémunération ni barème détaillé de bonus/malus DSP 45 n’est disponible dans les sources intégrées.
- Une carrière commence sans autobus ni machiniste. Le joueur doit acheter un véhicule, recruter, puis affecter les départs; les prix du marché sont des estimations de jeu, parfois de faible confiance.

Ces données suffisent à proposer un réglage de difficulté de démarrage, mais ne suffisent pas à affirmer que les niveaux sont équilibrés sur une carrière complète. Les propositions doivent être éprouvées dans plusieurs tailles de réseau avant d’être présentées comme équilibrées.

## Proposition de profils

Chaque profil est un préréglage initial indépendant du scénario et de la date. Les effets sont cumulatifs : le capital indiqué est le capital avant débit du stock initial, puis les deux fréquences utilisent les multiplicateurs déjà définis.

| Profil proposé | Capital avant stock | Risque de panne | Risque de perturbation routière fictive | Effet mesurable |
| --- | ---: | ---: | ---: | --- |
| Accompagnée | 1 250 000 € (+25 % du réglage actuel) | Réduit · ×0,5 | Réduite · ×0,5 | 250 000 € de marge initiale supplémentaire et moitié du risque de référence pour chaque famille d’événements. |
| Standard | 1 000 000 € (réglage actuel) | Standard · ×1 | Standard · ×1 | Reproduit les conditions de départ actuelles. |
| Exigeante | 800 000 € (−20 % du réglage actuel) | Élevée · ×2 | Élevée · ×2 | 200 000 € de capital initial en moins et risque doublé pour chaque famille d’événements. |

Les niveaux et les deux écarts de capital sont une proposition de réglage de jeu, pas une recommandation financière ni une valeur observée chez un opérateur. Le stock de pièces reste identique entre profils : le joueur reçoit les mêmes références et quantités; seule la trésorerie restante varie. Les montants exacts après débit doivent être calculés à partir de `initialStockCostEuro`, jamais recopiés en dur dans l’interface.

### Limites et cohérence à vérifier

- Le mode « Exigeante » doit conserver un solde positif après le débit du stock et permettre d’acheter l’offre de bus éligible la moins chère du scénario/date sélectionné. À défaut, le profil ne permettrait pas de démarrer les objectifs existants « recevoir un premier bus » et « terminer une première course ».
- Le scénario régional peut avoir un catalogue d’offres différent de Bords de Marne. La faisabilité doit être contrôlée sur les scénarios pris en charge et les dates jouables; ne pas garantir un autobus compatible lorsque les données de compatibilité ou les offres manquent.
- Les fréquences d’incident ont déjà un réglage manuel. Le profil ne doit pas prétendre garantir une carrière « facile » ou « difficile » après que le joueur les modifie. Il décrit les conditions initiales; les options restent libres et affichent leurs valeurs effectives.
- Doubler une probabilité de base ne garantit pas deux fois plus d’incidents observés sur une courte partie, du fait du tirage déterministe et des plafonds du moteur. La copie doit parler de risque relatif, pas de nombre promis d’incidents.
- Aucun facteur ne doit changer la contribution contractuelle, les pénalités, les salaires, l’énergie ou les montants publiés sur la DSP 45. Les sources actuelles ne donnent pas les annexes financières détaillées permettant d’en déduire des niveaux de difficulté réalistes.

## Persistance et compatibilité

- Ajouter un identifiant de profil à `SimulationSession` en champ optionnel. Une ancienne sauvegarde sans cet identifiant reste décodable et son profil effectif est présenté comme `Standard` ou `Historique · réglage standard`, sans changer son solde, ses incidents ni ses autres paramètres.
- Lors de `startNew`, calculer le solde avec le capital du profil moins le coût des pièces initiales; conserver l’écriture de stock de départ existante dans le grand livre.
- Enregistrer les fréquences effectives du profil dans les champs déjà présents. Ne pas les recalculer lors d’une reprise, d’un import, d’une synchronisation iCloud, ni après une modification manuelle.
- Un profil décrit les conditions choisies au démarrage. Une modification ultérieure des fréquences ne réécrit pas ce choix historique et ne change pas la trésorerie. L’interface doit indiquer sans ambiguïté les fréquences actives si elles diffèrent du préréglage.
- Les imports dupliqués changent l’identifiant de carrière selon le flux existant, mais préservent le profil et toutes les valeurs financières. La synchronisation iCloud transporte le champ dans la sauvegarde existante; elle ne doit pas créer une deuxième source de vérité.
- Ne pas faire de migration destructive ni recalculer les capitaux d’une carrière déjà créée.

## Interface proposée

Dans la préparation d’une carrière macOS et iPhone, ajouter une section « Difficulté » avec un sélecteur système à trois profils, placé près des conditions de départ. Le choix doit afficher une brève explication en texte, par exemple :

> **Accompagnée** · 1 250 000 € avant le stock de départ · risques de panne et de circulation réduits de moitié.

La description se met à jour immédiatement. Elle précise que les valeurs sont des règles de jeu. La section garde le même contenu et les mêmes choix sur Mac et iPhone; la disposition s’empile naturellement sur une largeur étroite. Les libellés et les multiplicateurs ne reposent pas sur la couleur, et VoiceOver lit le profil ainsi que ses trois effets. Le réglage ne doit pas être caché dans les options générales puisqu’il définit la création de la carrière.

Dans les options pendant la partie, conserver les réglages indépendants des fréquences existants. Si l’une de ces valeurs ne correspond plus au profil initial, afficher les valeurs actives plutôt que de laisser entendre que le profil les impose encore.

## Critères d’acceptation proposés

1. Le formulaire macOS et iPhone permet de choisir les trois profils et décrit explicitement le capital avant stock et les multiplicateurs d’incident.
2. Une nouvelle carrière standard reproduit exactement le capital de départ et les fréquences utilisés aujourd’hui.
3. Les profils accompagnée et exigeante utilisent les facteurs proposés (capital ×1,25 et ×0,8; fréquences ×0,5 et ×2), avec arrondis documentés et aucun autre changement financier.
4. Le débit du stock initial reste identique dans les trois profils et le grand livre conserve une seule écriture de stock.
5. Le profil exigeant laisse assez de trésorerie pour acheter l’offre de bus éligible la moins chère dans chaque parcours de création officiellement pris en charge; les cas sans offre vérifiable sont signalés plutôt que rendus impossibles silencieusement.
6. Une sauvegarde antérieure sans champ de difficulté se décode sans perte et garde inchangés ses valeurs financières et ses fréquences effectives.
7. L’import/export JSON, l’import en copie et la préparation de synchronisation iCloud préservent le profil et les valeurs réellement enregistrées.
8. Modifier une fréquence après création ne change ni le capital initial ni le profil mémorisé; l’interface montre la fréquence active.
9. Aucun calcul de contrat, de paie ou de bonus/malus n’est modifié par les profils.
10. Les contrôles restent utilisables au clavier sur macOS et avec VoiceOver; le texte s’adapte à la largeur iPhone.

## Smoke suggéré

Créer un smoke de domaine indépendant de SwiftUI qui :

1. vérifie les trois résolutions de profil, leurs capitaux et multiplicateurs exacts;
2. crée une carrière pour chaque profil et compare les soldes, l’écriture du stock, le profil et les fréquences;
3. modifie les fréquences, sauvegarde puis recharge et confirme que le profil historique n’écrase pas les valeurs actives;
4. décode un JSON de carrière historique sans le champ, puis vérifie que son solde et ses fréquences ne changent pas;
5. teste la limite d’abordabilité du profil exigeant sur les scénarios/dates pris en charge sans créer de fausse offre ni contourner l’état d’éligibilité du véhicule.

Ajouter un contrôle de source léger pour vérifier que macOS et iPhone exposent le même sélecteur et le texte descriptif, tout en notant qu’il ne remplace pas le test visuel dans la fenêtre et sur appareil.

## Décisions approuvées

1. Profils et capital : Accompagnée 1 250 000 €, Standard 1 000 000 €, Exigeante 800 000 €, avant débit du stock initial.
2. Les risques de panne et de perturbation routière utilisent les multiplicateurs respectifs ×0,5, ×1 et ×2. Les fréquences actives restent modifiables après le démarrage.
3. La difficulté ne change ni les contrats, ni les salaires, ni la demande, ni les objectifs.
4. Une sauvegarde historique sans profil est présentée comme Standard, sans recalcul de son argent ou de ses fréquences.
