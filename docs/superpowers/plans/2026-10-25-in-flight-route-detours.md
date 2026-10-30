# Replanification des courses en cours lors d’une déviation

> **Plan d’implémentation**

**Objectif :** appliquer une déviation planifiée aux étapes encore à venir d’une course déjà affectée, en gardant cohérents ses événements, ses distances et ses réservations de ressources.

**Architecture :** conserver dans la sauvegarde un plan d’arrêts par course affectée et les séquences des événements produits au dispatch. À la création ou à la prolongation d’une déviation, recalculer les plans concernés, mettre à jour uniquement les événements encore en attente et vérifier les conflits bus/machiniste avant de valider atomiquement la modification.

**Technologies :** Swift 6, SwiftUI, Codable, moteur de simulation existant.

**Référence :** cahier des charges §9, notamment les lignes 308–332; `docs/IMPLEMENTATION_STATUS.md`.

## Contraintes globales

- Conserver la lecture des anciennes sauvegardes qui ne possèdent pas encore de plan de course persisté.
- Ne jamais modifier les événements déjà passés ni leurs écritures de distance et de recettes.
- Recalculer la géométrie, les horaires et la demande voyageurs des seuls événements encore en attente.
- Vérifier la compatibilité des horaires recalculés avec les réservations du bus et du machiniste avant d’enregistrer la déviation.
- Compiler la cible Debug macOS universelle après cette reprise.

## Points de revue

- Une déviation déjà passée ne doit pas modifier rétroactivement une étape déjà parcourue.
- Une étape future doit recevoir la géométrie de détour et le retard correspondant une seule fois.
- Une déviation dont le retard entre en conflit avec une réservation doit échouer sans laisser de partie partiellement modifiée.
- Les événements conservés dans l’historique doivent rester identiques après le recalcul.
- Une ancienne sauvegarde sans plan actif doit rester décodable.
- Un retard ne déplace une course suivante que s’il rattrape son départ; les courses déjà affectées sur la même ressource sont ensuite recalées en chaîne.
- Si une course à décaler n’a pas de plan d’exécution modifiable, l’opération complète doit échouer sans mutation partielle.

## Étapes

- [x] Ajouter un smoke exécutable pour l’application d’un détour à une étape future, l’exclusion d’une étape déjà passée, la mise à jour des événements associés, la propagation sur trois courses et le rejet transactionnel d’un conflit.
- [x] Persister un plan d’exécution optionnel pour les courses dispatchées, puis mettre à jour les événements futurs, les courses suivantes rattrapées et leurs réservations quand une déviation est créée ou prolongée.
- [x] Exécuter le smoke, les validations ciblées, le build Debug macOS et le build iOS non signé; consigner les résultats et limites dans `docs/IMPLEMENTATION_STATUS.md`.
