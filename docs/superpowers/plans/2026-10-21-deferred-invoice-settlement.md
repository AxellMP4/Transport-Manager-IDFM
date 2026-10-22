# Factures différées — plan d’implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Séparer les montants d’exploitation acquis des factures à encaisser/régler et des mouvements de trésorerie, avec des échéances sauvegardées.

**Architecture:** Ajouter des factures et des lignes liées au journal existant. Le journal conserve le résultat dans `amount` et porte le mouvement de caisse dans un champ optionnel distinct; les paiements passent par des événements datés et sauvegardés. La vue Finances mensuelles affiche les factures avec leurs échéances et conserve les indicateurs de résultat actuels.

**Tech Stack:** Swift 6, SwiftUI, Codable, calendrier grégorien au fuseau `GTFSServiceDate.parisTimeZone`.

**Spec:** `docs/superpowers/specs/2026-10-21-deferred-invoice-settlement-design.md`

## Global Constraints

- App native macOS en Swift/SwiftUI, sans nouvelle dépendance.
- Le GTFS et les dates d’exploitation restent interprétés dans le fuseau `Europe/Paris`.
- Les règles de facturation, montants et délais ajoutés sont des hypothèses de jeu, pas des conditions contractuelles réelles.
- Préserver les anciennes sauvegardes grâce à des propriétés optionnelles et au repli du mouvement de caisse sur `amount`.
- Ne pas ajouter ni lancer de tests automatisés pour cette tâche; vérifier avec une compilation macOS.
- Ne pas créer de commit : le dépôt courant contient le projet en fichiers non suivis.

## Review Focus

- Une ancienne sauvegarde ne doit pas générer des factures rétroactives; les champs absents doivent garder l’ancien mouvement de caisse.
- Un événement d’échéance dupliqué ne doit jamais régler deux fois une facture.
- Un rattrapage de simulation au-delà d’une échéance doit régler à la date exacte de l’événement.
- Un bonus ou malus calculé à l’événement de minuit doit être rattaché à la journée de service clôturée et à sa facture.
- Une facture de prestation nette négative doit devenir un montant à régler, sans retourner les lignes de résultat d’exploitation.
- Le résultat d’exploitation mensuel ne doit pas compter le règlement une seconde fois; la variation de trésorerie doit, elle, le compter.

---

### Task 1: Modèles de facture et de mouvement de caisse

**Files:**
- Modify: `TransportManagerIDFM/Domain/VehicleMarket.swift`
- Modify: `TransportManagerIDFM/Domain/SimulationEngine.swift`

**Interfaces:**
- Produces: `SimulationInvoice`, `SimulationInvoiceLineItem`, `SimulationInvoiceDirection`, `SimulationInvoiceRules.dueDate(for:)`, `SimulationLedgerEntry.cashMovementEuro`, `.settlement`, and optional `SimulationSession.invoices`.

- [x] Ajouter les valeurs Codable/Hashable pour une facture, ses lignes liées à des identifiants du journal, sa contrepartie, son sens, ses dates, son règlement éventuel et son total net.
- [x] Définir une échéance à 30 jours calendaires dans le calendrier grégorien au fuseau Paris.
- [x] Ajouter `cashDeltaEuro` optionnel et `cashMovementEuro` avec repli sur `amount`; ajouter la nature `.settlement` et le tableau optionnel `invoices` à la session.

### Task 2: Émission et règlement par événements

**Files:**
- Modify: `TransportManagerIDFM/Domain/SimulationEngine.swift`

**Interfaces:**
- Consumes: les modèles de la Task 1.
- Produces: événements `.invoiceSettlementDue(invoiceID:)` et traitement idempotent des factures.

- [x] Marquer les écritures nouvellement acquises d’énergie, de contribution de service et d’ajustement contractuel avec `cashDeltaEuro: 0`; ne plus modifier la trésorerie à ces points d’acquisition.
- [x] À `.dailySettlement`, émettre au plus une facture nette de prestation et une facture d’énergie pour les seules écritures nouvellement acquises du jour; conserver les liens vers chaque écriture source.
- [x] Programmer l’événement de règlement, le sauvegarder dans `pendingEvents`, traiter les échéances atteintes pendant un rattrapage et empêcher tout double règlement.
- [x] Au règlement, débiter/créditer la trésorerie une fois et ajouter une écriture `.settlement` à `amount == 0` avec le mouvement signé dans `cashDeltaEuro`.

### Task 3: Rapports et interface Finances

**Files:**
- Modify: `TransportManagerIDFM/Features/OperationsDashboardView.swift`

**Interfaces:**
- Consumes: `SimulationSession.invoices`, `SimulationInvoice`, `SimulationLedgerEntry.cashMovementEuro`.

- [x] Calculer la variation, les soldes d’ouverture et de clôture depuis `cashMovementEuro`; garder recettes, charges et financement calculés depuis `amount` et la nature d’écriture.
- [x] Ajouter une liste groupée de factures avec contrepartie, total, émission, échéance et statut textuel réglé/ouvert; garder un état vide explicite.
- [x] Rendre visibles les montants acquis et les mouvements de trésorerie distincts dans le journal et le détail mensuel.
- [x] Garder la hiérarchie SwiftUI existante, les couleurs système et un libellé/icône de statut qui ne s’appuie pas seulement sur la couleur.

### Task 4: Documentation et vérification native

**Files:**
- Modify: `README.md`
- Modify: `docs/IMPLEMENTATION_STATUS.md`
- Create: `.superpowers/sdd/2026-10-21-deferred-invoice-settlement/progress.md`

- [x] Remplacer le TODO des factures différées par les règles jouables, le délai assumé et les catégories couvertes; laisser explicites les limites financières restantes.
- [x] Mettre à jour le ledger SDD avec les changements et les éventuels arbitrages.
- [x] Vérifier la syntaxe des sources Swift et compiler le schéma Debug macOS pour `arm64` et `x86_64`; lire les diagnostics avant de conclure.
