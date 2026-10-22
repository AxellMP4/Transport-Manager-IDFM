# Progression de carrière — plan d’implémentation

> **For agentic workers:** Utiliser `superpowers:executing-plans` tâche par tâche. Ne pas ajouter ni lancer de tests automatisés sans demande de l’utilisateur. Vérifier avec le parseur Swift et le build macOS Debug.

**Goal:** Ajouter des jalons persistants et des niveaux de carrière dérivés de l’exploitation réellement enregistrée.

**Architecture:** Un catalogue pur réconcilie les jalons avec un état Codable optionnel de `SimulationSession`. Le moteur l’applique aux événements et sauvegardes, et une vue dédiée dans Rapports présente les niveaux, les jalons débloqués et les réussites.

**Tech Stack:** Swift 6, SwiftUI, Codable, app native macOS.

**Spec:** `docs/superpowers/specs/2026-10-21-career-progression-design.md`

## Global Constraints

- Les jalons donnent des points de progression de jeu, sans prime en euros ni effet sur les contrats, les factures ou la trésorerie.
- Les anciennes sauvegardes sans état de progression reconstituent leurs jalons depuis les données qu’elles contiennent déjà.
- Les fonctionnalités existantes restent accessibles à tous les niveaux.
- Une course en attente ne compte qu’après sa fin effective dans `eventHistory`.
- Ne pas ajouter ni lancer de tests automatisés; vérifier la syntaxe et compiler le schéma Debug macOS.
- Ne pas créer de commit; les fichiers du projet sont actuellement non suivis dans Git.

## Review Focus

- Une fin de course encore en attente ne doit jamais attribuer de jalon.
- Les événements de remplacement ne comptent pas comme une fin de service.
- Plusieurs appels de réconciliation ne doivent pas attribuer deux fois les points.
- Une ancienne sauvegarde doit se restaurer et recevoir ses jalons sans migration manuelle.
- Une réparation, un investissement ou une facture encore en attente ne doit pas être présenté comme terminé ou réglé.
- Les jalons futurs sont visibles et verrouillés jusqu’au rang requis ; un critère rempli en avance est récompensé à son déblocage, avec la date simulée d’origine.
- Les anciennes fins de course `.serviceCompleted` restent prises en compte ; le jalon de production utilise un taux de jeu générique si le rapport n’a pas de taux contractuel.

---

### Task 1: Modèle et attribution idempotente

**Files:**
- Create: `TransportManagerIDFM/Domain/CareerProgression.swift`
- Modify: `TransportManagerIDFM/Domain/SimulationEngine.swift`

**Interfaces:**
- Produces `CareerAchievement`, `CareerProgressionState`, `CareerMilestoneProgress`, `CareerProgressionSnapshot` et `CareerProgressionCatalog.reconcile(session:)` / `.snapshot(for:)`.
- `SimulationSession.careerProgression` est optionnel pour décoder les anciennes sauvegardes.

- [x] Définir les quatre rangs et douze jalons du spec avec les points, critères et niveaux requis.
- [x] Dériver la progression depuis les événements historiques, machinistes, bilans et factures effectivement réglées.
- [x] Réconcilier au chargement, à l’import, à la sauvegarde, à l’export et après le traitement des événements ; conserver les dates et éviter les doublons.
- [x] Initialiser une nouvelle carrière avec un état de progression vide.

### Task 2: Écran Progression

**Files:**
- Create: `TransportManagerIDFM/Features/CareerProgressionView.swift`
- Modify: `TransportManagerIDFM/Features/OperationsDashboardView.swift`

**Interfaces:**
- Consumes `CareerProgressionCatalog.snapshot(for:)` et la session active.

- [x] Présenter le rang, le total de points, la progression vers le rang suivant et l’explication des règles de jeu.
- [x] Présenter les jalons, leurs critères, leur avancement et leur date de validation.
- [x] Montrer les jalons verrouillés avec le rang nécessaire et l’historique des réussites.
- [x] Ajouter l’écran dans Rapports > Progression et renommer le tutoriel en « Démarrage de carrière ».

### Task 3: Documentation et build

**Files:**
- Modify: `README.md`
- Modify: `docs/IMPLEMENTATION_STATUS.md`

- [x] Documenter les niveaux, points et jalons comme règles de jeu sans conséquence contractuelle ou financière.
- [x] Parcourir toutes les sources Swift avec `swiftc -frontend -parse`.
- [x] Compiler Debug macOS pour l’architecture `x86_64` prise en charge sur cette machine et lire le résultat.
- [x] Noter la vérification et les limites dans l’état de réalisation.
