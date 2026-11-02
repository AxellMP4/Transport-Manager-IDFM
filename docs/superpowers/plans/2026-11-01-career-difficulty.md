# Plan — Profils de difficulté de carrière

Référence approuvée : `docs/superpowers/specs/2026-11-01-career-difficulty-design.md` et décision utilisateur du 1er novembre 2026.

## Résultat attendu

À la création, proposer Accompagnée (1 250 000 € avant stock, pannes ×0,5, circulation ×0,5), Standard (1 000 000 €, ×1, ×1) et Exigeante (800 000 €, ×2, ×2). Le coût du stock initial reste unique et identique. Chaque carrière mémorise le profil de départ et ses fréquences effectives; des ajustements ultérieurs des fréquences restent possibles sans réécrire le profil ni le capital. Les sauvegardes anciennes sans profil deviennent `Standard` à l’affichage, sans altération de leurs valeurs.

## Hors périmètre

Ne pas changer salaires, demande voyageurs, objectifs, coûts de contrat, stock ni paramètres de simulation autres que le capital initial et les deux fréquences déjà prises en charge. Ne pas qualifier les profils d’équilibrés sans essais de carrière. Le guide optionnel, déjà livré, reste inchangé.

## Fichiers et étapes

1. **Règles et persistance** — Dans `TransportManagerIDFM/Domain/SimulationEngine.swift` (ou un fichier domaine référencé par le projet), ajouter le modèle `CareerDifficulty` et ses valeurs résolues. Ajouter un champ optionnel à `SimulationSession`, avec accès effectif standard pour les anciennes sauvegardes. Faire accepter le profil par `startNew`, calculer `capital - initialStockCostEuro`, garder l’écriture de stock existante, puis enregistrer les fréquences initiales. Ajouter un smoke domaine avant le code et vérifier exactement les trois configurations et le décodage sans champ.
2. **Préparation et réglages** — Dans `OperationsDashboardView.swift`, mémoriser le choix de difficulté pour la nouvelle préparation et exposer le même sélecteur macOS/iPhone avec son capital avant stock, les deux multiplicateurs et l’indication « règle de jeu ». Transmettre le profil à `startNew`. Relier les réglages de fréquence de la carrière active à sa session pour qu’ils restent modifiables; afficher distinctement le profil initial et les valeurs actives lorsqu’elles divergent. Tester le partage du sélecteur et l’intégration à la création.
3. **Validation et suivi** — Étendre les smokes de sauvegarde/import/guide si nécessaire; lancer les validations domaine et UI pertinentes, contrôler les fichiers/plist et les entitlements, compiler Debug macOS puis iPhoneOS, mettre `docs/IMPLEMENTATION_STATUS.md` à jour avec résultats et limites. Réviser le diff du changement avant toute publication.

## Contrat de validation

- Smoke rouge avant le comportement, puis vert après : capitaux, multiplicateurs, coût de stock unique, champs de profil, fréquences modifiables, et sauvegarde historique dont solde/fréquences restent identiques.
- Le contrôle source confirme le sélecteur unique dans la préparation commune aux deux plateformes.
- Compilation non signée macOS universelle et iPhoneOS arm64; noter séparément toute panne de l’outillage Xcode, l’absence de test visuel/appareil, de provisionnement CloudKit, et les données externes indisponibles.

## Journal de décisions

- Décision utilisateur : appliquer les trois valeurs exactes de la proposition. Le profil standard conserve le comportement actuel.
- Décision utilisateur : les fréquences sont modifiables après création; leur modification ne change pas le profil mémorisé ni le capital.
- Décision d’implémentation : le profil absent d’une ancienne sauvegarde est présenté comme standard; aucune donnée de sauvegarde historique n’est migrée ni recalculée.

## État de réalisation — 1er novembre 2026

- Modèle et persistance ajoutés, sélecteur macOS/iPhone relié à `startNew`, fréquences actives éditables et indépendantes du profil initial.
- Smoke des trois profils et contrôles source verts; analyse syntaxique, projet/entitlements plist et `git diff --check` ciblé passent.
- Builds Debug non signés macOS arm64 et iPhoneOS arm64 passent depuis la copie temporaire du projet. Le lancement visuel sur simulateur/appareil et l’essai réel CloudKit restent externes à cette validation.
