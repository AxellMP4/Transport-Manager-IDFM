# Factures différées — choix de conception

## Intention

La synthèse financière doit distinguer le résultat acquis pendant l’exploitation, la facture émise, son règlement et la trésorerie. Aujourd’hui, les contributions contractuelles estimées et l’énergie estimée apparaissent au journal au moment où le service a lieu et modifient immédiatement la trésorerie. Cette tranche ajoute un cycle de facturation sauvegardé sans changer les hypothèses de montant déjà utilisées par le jeu.

## Règles retenues pour le jeu

- Les écritures « Contribution contractuelle estimée (jeu) », « Recette de service estimée », les bonus/malus quotidiens de production et « Énergie estimée » conservent leur date et leur montant d’exploitation.
- À la clôture de chaque journée parisienne, les contributions et ajustements du contrat sont regroupés en une facture de prestation nette. Une facture positive est à encaisser; une facture négative est à régler.
- Le bonus ou malus calculé pendant l’événement de minuit est daté à la dernière seconde de la journée de service clôturée, afin qu’il figure dans la facture de cette journée.
- Les coûts d’énergie de la journée sont regroupés en une facture fournisseur à régler.
- Les factures sont émises à minuit, au moment de la clôture, puis réglées automatiquement 30 jours calendaires après leur émission. Ce délai et cette périodicité sont des hypothèses d’équilibrage du jeu, pas les conditions réelles de la DSP 45 ou d’un fournisseur.
- L’émission ne crée aucune nouvelle recette ou charge. Le règlement change la trésorerie et ajoute une écriture de règlement à résultat nul.
- Les pièces de paie, achats, ventes, réparations, prêts et investissements restent réglés selon leur mécanisme actuel dans cette tranche.

## Données et sauvegardes

Chaque facture conserve son identifiant déterministe, sa contrepartie, son sens, les postes facturés avec leurs identifiants d’écriture source, le total net, la date d’émission, l’échéance et la date de règlement éventuelle. Une échéance est un événement de simulation sauvegardé et idempotent.

`SimulationLedgerEntry.amount` reste le montant de résultat d’exploitation ou de financement. Un nouveau `cashDeltaEuro` optionnel porte séparément le mouvement de trésorerie; sans cette valeur, le mouvement vaut `amount`, ce qui conserve l’interprétation des sauvegardes existantes. Les postes nouvellement acquis ont un mouvement de trésorerie nul. Les règlements ont un montant de résultat nul, une nature `.settlement` et un mouvement de trésorerie signé.

Les factures et nouveaux champs de journal sont optionnels pour préserver le décodage des anciennes carrières. Les écritures d’anciennes sauvegardes ne sont pas transformées rétroactivement en factures.

## Présentation

Dans **Finances mensuelles**, présenter les factures ouvertes puis réglées avec contrepartie, sens, total, émission, échéance et statut textuel. Dans les écritures, distinguer le montant acquis du mouvement de trésorerie quand ils diffèrent. Utiliser les couleurs système et le texte/icône ensemble afin que le statut ne dépende pas de la couleur seule. Garder une liste compacte et extensible dans le style des groupes financiers existants.

## Portée et limites

Cette version reporte uniquement les contributions/bonus-malus du contrat et les coûts d’énergie. Elle ne modélise pas la TVA, les avoirs, le rapprochement bancaire, les paiements manuels, les délais de paiement documentés, les impayés, les paies différées ni les factures d’atelier. Les montants restent des estimations de jeu et les pièces d’origine restent visibles dans le journal.
