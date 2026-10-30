import Combine
import Foundation

enum SimulationEngineError: LocalizedError {
    case noOperatedRoutes
    case marketUnavailable
    case unknownMarketOffer
    case exhaustedMarketOffer
    case insufficientCapital(required: Int, available: Int)
    case depotEnergyInfrastructureRequired(DepotEnergyInfrastructureKind)
    case depotEnergyInfrastructureUnavailable
    case scheduledDepartureUnavailable
    case vehicleUnavailable
    case vehicleCannotBeSold
    case vehicleSaleEstimateChanged
    case vehicleNotAtTripStart
    case unknownMachinist
    case machinistNotQualified
    case machinistUnavailable
    case invalidMachinistRelief
    case invalidMachinistReliefCancellation
    case machinistTransferUnavailable
    case invalidMachinistAbsence
    case machinistAbsenceConflictsWithService
    case machinistAbsenceConflictsWithExistingAbsence
    case machinistAbsenceUnavailable
    case machinistAbsenceConflictsWithTraining
    case invalidMachinistAbsenceCompensation
    case invalidMachinistTraining
    case machinistAlreadyQualified
    case machinistTrainingConflictsWithWork
    case machinistTrainingConflictsWithAbsence
    case machinistTrainingConflictsWithExistingTraining
    case machinistTrainingUnavailable
    case machinistTrainingAlreadyStarted
    case machinistBreakUnavailable
    case machinistBreakAlreadyStarted
    case machinistDutyBlockCorrectionUnavailable
    case machinistDutyBlockCorrectionReasonRequired
    case machinistDutyBlockCorrectionConflict
    case invalidTripSchedule
    case invalidImportedSave
    case noSessionToExport
    case maintenanceNotRequired
    case workshopPartUnavailable(VehicleWorkshopPart)
    case invalidWorkshopPartQuantity
    case workshopExpansionUnavailable
    case incidentUnavailable
    case incidentDiagnosisRequired
    case incidentDiagnosisAlreadyStarted
    case incidentDiagnosisUnavailable
    case replacementDispatchUnavailable
    case repairAlreadyPlanned
    case operationBlockedByIncident
    case stopClosureUnavailable
    case invalidStopClosureReplacement
    case stopAlreadyClosed
    case routeClosureUnavailable
    case routeAlreadySuspended
    case routeClosureActive
    case invalidRouteDetour
    case routeDetourUnavailable
    case routeDetourOverlap
    case routeDetourConflictsWithAssignment
    case invalidTowRoute
    case invalidDeadheadRoute
    case invalidDepotReturnRoute
    case loanTermsUnavailable
    case loanLimitExceeded
    case electricChargingPointRequired
    case insufficientBatteryReserve
    case rechargeUnavailable

    var errorDescription: String? {
        switch self {
        case .noOperatedRoutes:
            "Une partie doit épingler au moins une ligne affectée à un COB avec une preuve exploitable."
        case .marketUnavailable:
            "Le marché ou le capital de cette ancienne sauvegarde n’est pas disponible."
        case .unknownMarketOffer:
            "Cette offre n’appartient pas au marché épinglé à la partie."
        case .exhaustedMarketOffer:
            "Cette offre n’a plus de véhicule en stock."
        case let .insufficientCapital(required, available):
            "Capital insuffisant : achat à \(required.formatted()) €, solde de \(available.formatted()) €."
        case let .depotEnergyInfrastructureRequired(infrastructure):
            "Le dépôt ne dispose pas d’un équipement \(infrastructure.title.lowercased()) attesté ou construit dans cette partie. Construisez l’installation ou choisissez un dépôt compatible avant d’acheter ou d’affecter ce bus."
        case .depotEnergyInfrastructureUnavailable:
            "Cette installation est déjà présente, en chantier, ou ne peut pas être construite dans ce scénario."
        case .scheduledDepartureUnavailable:
            "Ce départ GTFS n’est plus disponible pour une affectation."
        case .vehicleUnavailable:
            "Ce bus n’est pas disponible pour une nouvelle course."
        case .vehicleCannotBeSold:
            "La cession est possible quand le bus est immobile au dépôt ou au terminus, hors course, livraison et entretien."
        case .vehicleSaleEstimateChanged:
            "L’estimation de revente a évolué depuis l’ouverture de la confirmation. Vérifiez le nouveau montant avant de réessayer."
        case .vehicleNotAtTripStart:
            "Le bus se trouve à un autre arrêt. Affectez une course qui commence à son arrêt actuel."
        case .unknownMachinist:
            "Ce machiniste ne figure pas dans l’effectif de la partie."
        case .machinistNotQualified:
            "La qualification du machiniste ne couvre pas la classe de ce bus."
        case .machinistUnavailable:
            "Ce machiniste n’est pas disponible : chevauchement, repos, absence ou limites du service."
        case .invalidMachinistRelief:
            "La relève doit avoir lieu pendant une course active, lorsque le bus est arrêté à un arrêt."
        case .invalidMachinistReliefCancellation:
            "Cette relève n’est plus prévue ou son arrêt est déjà passé."
        case .machinistTransferUnavailable:
            "Le trajet estimé du machiniste n’arrive pas à temps à l’arrêt de relève. Recalculez-le ou choisissez un arrêt plus tardif."
        case .invalidMachinistAbsence:
            "L’absence doit commencer à l’heure simulée actuelle ou plus tard et se terminer après son début."
        case .machinistAbsenceConflictsWithService:
            "Cette absence chevauche un service programmé ou en cours pour ce machiniste."
        case .machinistAbsenceConflictsWithExistingAbsence:
            "Une autre absence de ce machiniste couvre déjà tout ou partie de cette période."
        case .machinistAbsenceUnavailable:
            "Cette absence a déjà commencé et ne peut plus être retirée de l’historique."
        case .machinistAbsenceConflictsWithTraining:
            "Cette absence chevauche une formation planifiée pour ce machiniste."
        case .invalidMachinistAbsenceCompensation:
            "Les heures rémunérées doivent être finies, positives ou nulles, et tenir dans la période d’absence."
        case .invalidMachinistTraining:
            "La formation doit commencer à l’heure simulée actuelle ou plus tard."
        case .machinistAlreadyQualified:
            "Ce machiniste possède déjà la qualification bus standard et articulé."
        case .machinistTrainingConflictsWithWork:
            "La formation doit respecter les services planifiés et le repos de jeu de 11 heures."
        case .machinistTrainingConflictsWithAbsence:
            "La formation chevauche une absence planifiée."
        case .machinistTrainingConflictsWithExistingTraining:
            "Une autre formation de ce machiniste chevauche cette période ou le repos requis."
        case .machinistTrainingUnavailable:
            "Cette formation n’est plus disponible."
        case .machinistTrainingAlreadyStarted:
            "Une formation commencée ne peut plus être annulée."
        case .machinistBreakUnavailable:
            "Aucun créneau de pause de 30 minutes n’est libre entre deux courses prévues de ce bloc."
        case .machinistBreakAlreadyStarted:
            "Une pause commencée ou terminée ne peut plus être annulée."
        case .machinistDutyBlockCorrectionUnavailable:
            "Seul un bloc machiniste terminé et soldé peut être corrigé."
        case .machinistDutyBlockCorrectionReasonRequired:
            "Indiquez un motif d’au moins quatre caractères pour garder une trace de la correction."
        case .machinistDutyBlockCorrectionConflict:
            "Ce machiniste ne peut pas reprendre tout le bloc : qualification, dépôt, repos, absence, formation ou autre service incompatible."
        case .invalidTripSchedule:
            "La séquence d’arrêts n’a pas d’horaires GTFS géolocalisés et cohérents."
        case .invalidImportedSave:
            "Le fichier JSON ne contient pas une sauvegarde de carrière valide pour ce jeu."
        case .noSessionToExport:
            "Aucune carrière active à exporter."
        case .maintenanceNotRequired:
            "Ce véhicule est déjà à 100 % d’état et ne nécessite pas cet entretien."
        case let .workshopPartUnavailable(part):
            "Stock épuisé : achetez un \(part.title.lowercased()) avant de planifier ce travail."
        case .invalidWorkshopPartQuantity:
            "La quantité de pièces commandée doit être comprise entre 1 et 100 kits."
        case .workshopExpansionUnavailable:
            "L’atelier a déjà sa capacité maximale ou une extension est en cours."
        case .incidentUnavailable:
            "Cette panne n’est plus en attente de dépannage."
        case .incidentDiagnosisRequired:
            "Effectuez d’abord le diagnostic de jeu avant de choisir le dépannage."
        case .incidentDiagnosisAlreadyStarted:
            "Le diagnostic de cette panne a déjà commencé."
        case .incidentDiagnosisUnavailable:
            "Le diagnostic de jeu n’est pas disponible pour cette panne."
        case .replacementDispatchUnavailable:
            "Le bus de réserve ou la suite de cette course n’est plus disponible pour cette panne."
        case .repairAlreadyPlanned:
            "Un dépannage est déjà programmé pour cette panne."
        case .operationBlockedByIncident:
            "Traitez d’abord la panne en attente avant de programmer cette opération."
        case .stopClosureUnavailable:
            "Aucune ligne exploitée de cette partie ne dessert cet arrêt."
        case .invalidStopClosureReplacement:
            "L’arrêt de remplacement ou son itinéraire piéton ne correspond pas à la ligne fermée."
        case .stopAlreadyClosed:
            "Cet arrêt est déjà fermé pour au moins une ligne exploitée."
        case .routeClosureUnavailable:
            "Cette ligne n’est pas exploitée par la carrière ou la durée de suspension est invalide."
        case .routeAlreadySuspended:
            "Cette ligne est déjà suspendue."
        case .routeClosureActive:
            "Ce départ est prévu pendant la suspension de la ligne."
        case .invalidRouteDetour:
            "La déviation doit relier deux arrêts consécutifs de la ligne, avec des horaires, une fenêtre et un tracé routier valides."
        case .routeDetourUnavailable:
            "Cette déviation n’est plus disponible ou sa fin prévue ne peut pas être prolongée."
        case .routeDetourOverlap:
            "Une déviation couvre déjà ce segment de ligne pendant tout ou partie de cette période."
        case .routeDetourConflictsWithAssignment:
            "Le retard de cette déviation chevauche une autre course déjà affectée au même bus ou au même machiniste. Libérez ou réaffectez cette ressource avant de confirmer."
        case .invalidTowRoute:
            "L’itinéraire de remorquage n’est plus valide. Recalculez-le avant de confirmer."
        case .invalidDeadheadRoute:
            "L’acheminement du dépôt au premier arrêt est indisponible ou n’arrive pas avant le départ GTFS. Recalculez-le avant de confirmer."
        case .invalidDepotReturnRoute:
            "L’itinéraire MapKit vers le dépôt est absent, périmé ou ne correspond plus à la position du bus."
        case .loanTermsUnavailable:
            "Le montant ou la durée ne fait pas partie des paramètres de financement de jeu disponibles."
        case .loanLimitExceeded:
            "Le plafond de dette de jeu serait dépassé par ce nouvel emprunt."
        case .electricChargingPointRequired:
            "Construisez au moins une borne de recharge au dépôt actif avant d’acheter un bus électrique suivi."
        case .insufficientBatteryReserve:
            "La charge disponible ne permet pas d’effectuer ce service en conservant la réserve de jeu de 15 %."
        case .rechargeUnavailable:
            "Ce bus ne peut pas être rechargé maintenant : il doit être immobile au dépôt actif et une borne doit être libre."
        }
    }
}

private struct MachinistDutyBlockAssignmentPlan {
    let joiningDutyBlockID: String?
}

private struct MachinistDepotReturnAssignmentPlan {
    let machinist: Machinist
    let previousCourse: MachinistServiceAssignment
    let dutyBlockPlan: MachinistDutyBlockAssignmentPlan
    let estimatedLaborCostEuro: Int
}

enum SimulationSpeed: Int, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case paused = 0
    case x1 = 1
    case x2 = 2
    case x5 = 5
    case x10 = 10
    case x30 = 30
    case x60 = 60
    case x300 = 300

    var id: Int { rawValue }

    var title: String {
        self == .paused ? "Pause" : "×\(rawValue)"
    }
}

enum VehicleIncidentFrequency: String, Codable, CaseIterable, Hashable, Identifiable, Sendable {
    case reduced
    case standard
    case increased

    var id: String { rawValue }

    var title: String {
        switch self {
        case .reduced: "Réduite"
        case .standard: "Standard"
        case .increased: "Élevée"
        }
    }

    var explanation: String {
        switch self {
        case .reduced: "Risque divisé par deux · règle de jeu"
        case .standard: "Risque de référence · règle de jeu"
        case .increased: "Risque doublé · règle de jeu"
        }
    }

    var hazardMultiplier: Double {
        switch self {
        case .reduced: 0.5
        case .standard: 1
        case .increased: 2
        }
    }
}

enum VehicleIncidentSeverity: String, Codable, CaseIterable, Hashable, Identifiable, Sendable {
    case minor
    case major
    case immobilizing

    var id: String { rawValue }

    var title: String {
        switch self {
        case .minor: "Mineure"
        case .major: "Importante"
        case .immobilizing: "Immobilisante"
        }
    }

    var repairDuration: TimeInterval {
        switch self {
        case .minor: 60 * 60
        case .major: 4 * 60 * 60
        case .immobilizing: 12 * 60 * 60
        }
    }

    var repairCostEuro: Int {
        switch self {
        case .minor: 850
        case .major: 3_500
        case .immobilizing: 9_000
        }
    }
}

enum VehicleIncidentDiagnosticFinding: String, Codable, CaseIterable, Hashable, Identifiable, Sendable {
    case electricalCircuit
    case coolingSystem
    case powertrain
    case runningGear
    case doorControl

    var id: String { rawValue }

    var title: String {
        switch self {
        case .electricalCircuit: "Circuit électrique à contrôler"
        case .coolingSystem: "Circuit de refroidissement à contrôler"
        case .powertrain: "Chaîne de traction à contrôler"
        case .runningGear: "Train roulant à contrôler"
        case .doorControl: "Commande de porte à contrôler"
        }
    }

    var explanation: String {
        switch self {
        case .electricalCircuit: "Le scénario de jeu oriente l’intervention vers un contrôle électrique."
        case .coolingSystem: "Le scénario de jeu oriente l’intervention vers un contrôle du refroidissement."
        case .powertrain: "Le scénario de jeu oriente l’intervention vers un contrôle de la chaîne de traction."
        case .runningGear: "Le scénario de jeu oriente l’intervention vers un contrôle du train roulant."
        case .doorControl: "Le scénario de jeu oriente l’intervention vers un contrôle de la commande de porte."
        }
    }

    func recommendedResponse(for severity: VehicleIncidentSeverity) -> VehicleRepairResponse {
        switch severity {
        case .minor: .standardOnSite
        case .major: .priorityOnSite
        case .immobilizing: .towToDepot
        }
    }
}

enum VehicleIncidentDiagnosisRules {
    static let duration: TimeInterval = 15 * 60
    static let costEuro = 180
}

enum VehicleRepairResponse: String, Codable, CaseIterable, Hashable, Identifiable, Sendable {
    case standardOnSite
    case priorityOnSite
    case towToDepot

    static let towDispatchFeeEuro = 2_500
    static let towCostPerRoadKilometerEuro = 12

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standardOnSite: "Dépannage standard sur place"
        case .priorityOnSite: "Dépannage prioritaire sur place"
        case .towToDepot: "Remorquage et réparation au dépôt"
        }
    }

    func duration(for severity: VehicleIncidentSeverity, towTravelSeconds: TimeInterval = 0) -> TimeInterval {
        switch self {
        case .standardOnSite: severity.repairDuration
        case .priorityOnSite: max(30 * 60, severity.repairDuration * 0.5)
        case .towToDepot: max(0, towTravelSeconds) + severity.repairDuration
        }
    }

    func cost(for severity: VehicleIncidentSeverity, towDistanceMeters: Double = 0) -> Int {
        switch self {
        case .standardOnSite: severity.repairCostEuro
        case .priorityOnSite: Int((Double(severity.repairCostEuro) * 1.8).rounded())
        case .towToDepot:
            Self.towDispatchFeeEuro
                + severity.repairCostEuro
                + Int((max(0, towDistanceMeters) / 1_000 * Double(Self.towCostPerRoadKilometerEuro)).rounded())
        }
    }
}

struct VehicleIncident: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let vehicleID: String
    let vehicleModelName: String
    let tripID: String
    let routeID: String
    let stopID: String
    let stopName: String
    let latitude: Double
    let longitude: Double
    var occurredAt: Date
    let severity: VehicleIncidentSeverity
    var serviceDateKey: Int? = nil
    var stopSequence: Int? = nil
    var machinistID: String? = nil
    var repairCompletedAt: Date
    var repairCostEuro: Int
    var displacedPassengerCount: Int
    var repairResponse: VehicleRepairResponse? = nil
    var towPlan: VehicleTowPlan? = nil
    var towArrivedAt: Date? = nil
    var recoveryTeamArrivedAt: Date? = nil
    var busTowStartedAt: Date? = nil
    var depotArrivedAt: Date? = nil
    var workshopStartedAt: Date? = nil
    var replacementVehicleID: String? = nil
    var replacementVehicleModelName: String? = nil
    var replacementMachinistID: String? = nil
    var replacementServiceStartsAt: Date? = nil
    var replacementDelaySeconds: TimeInterval? = nil
    var diagnosisRequired: Bool? = nil
    var diagnosisStartedAt: Date? = nil
    var diagnosisExpectedCompletionAt: Date? = nil
    var diagnosisCompletedAt: Date? = nil
    var diagnosticFinding: VehicleIncidentDiagnosticFinding? = nil
    var resolvedAt: Date?

    var isResolved: Bool { resolvedAt != nil }
    var requiresDiagnosis: Bool { diagnosisRequired == true }
}

struct VehicleMaintenanceRecord: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let vehicleID: String
    let vehicleModelName: String
    let scheduledAt: Date
    var workshopStartedAt: Date? = nil
    let expectedCompletionAt: Date
    let costEuro: Int
    let restoredConditionPercent: Int
    let returnStatus: PurchasedBusStatus
    var resolvedAt: Date?
    var depotID: String? = nil

    var isResolved: Bool { resolvedAt != nil }
}

struct DepotEnergyInfrastructureProject: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let infrastructure: DepotEnergyInfrastructureKind
    let startedAt: Date
    let completesAt: Date
    let costEuro: Int
    var completedAt: Date? = nil
    var chargingPointCount: Int? = nil
    var chargingPowerKilowatts: Double? = nil
    var depotID: String? = nil

    var isComplete: Bool { completedAt != nil }
    var isPending: Bool { completedAt == nil }
}

enum DepotEnergyReadiness: Hashable, Sendable {
    case readyFromEvidence(DepotEnergyEvidence)
    case readyFromGameplayRule(DepotEnergyEvidence)
    case installedByPlayer(DepotEnergyInfrastructureProject)
    case underConstruction(DepotEnergyInfrastructureProject)
    case requiresInstallation(DepotEnergyEvidence)
    case legacyUnverified(DepotEnergyEvidence)

    var isReady: Bool {
        switch self {
        case .readyFromEvidence, .readyFromGameplayRule, .installedByPlayer, .legacyUnverified:
            true
        case .underConstruction, .requiresInstallation:
            false
        }
    }

    var isInstallable: Bool {
        switch self {
        case .requiresInstallation, .legacyUnverified:
            true
        case .readyFromEvidence, .readyFromGameplayRule, .installedByPlayer, .underConstruction:
            false
        }
    }

    var evidence: DepotEnergyEvidence? {
        switch self {
        case let .readyFromEvidence(evidence),
             let .readyFromGameplayRule(evidence),
             let .requiresInstallation(evidence),
             let .legacyUnverified(evidence):
            evidence
        case .installedByPlayer, .underConstruction:
            nil
        }
    }

    var installationProject: DepotEnergyInfrastructureProject? {
        switch self {
        case let .installedByPlayer(project), let .underConstruction(project):
            project
        case .readyFromEvidence, .readyFromGameplayRule, .requiresInstallation, .legacyUnverified:
            nil
        }
    }

    var statusTitle: String {
        switch self {
        case let .readyFromEvidence(evidence), let .readyFromGameplayRule(evidence):
            evidence.statusTitle
        case .installedByPlayer:
            "Installé dans cette partie"
        case .underConstruction:
            "En construction"
        case let .requiresInstallation(evidence):
            evidence.statusTitle
        case .legacyUnverified:
            "Sauvegarde ancienne · non vérifié"
        }
    }

    var detail: String {
        switch self {
        case let .readyFromEvidence(evidence),
             let .readyFromGameplayRule(evidence),
             let .requiresInstallation(evidence),
             let .legacyUnverified(evidence):
            return evidence.note
        case let .installedByPlayer(project):
            if project.infrastructure == .electricCharging,
               let count = project.chargingPointCount,
               let power = project.chargingPowerKilowatts {
                return "Construction de jeu terminée le \(project.completedAt?.formatted(date: .abbreviated, time: .shortened) ?? "date inconnue") · \(count) poste(s), \(Int(power)) kW par poste."
            } else {
                return "Construction de jeu terminée le \(project.completedAt?.formatted(date: .abbreviated, time: .shortened) ?? "date inconnue")."
            }
        case let .underConstruction(project):
            let capacity = project.infrastructure == .electricCharging
                ? " · \(project.chargingPointCount ?? 0) poste à \(Int(project.chargingPowerKilowatts ?? 0)) kW"
                : ""
            return "Fin prévue le \(project.completesAt.formatted(date: .abbreviated, time: .shortened))\(capacity). Le coût et le délai sont des règles de jeu, pas un devis d’équipement réel."
        }
    }

    var sourceLinks: [DepotEnergyEvidenceLink] {
        evidence?.sources ?? []
    }
}

enum StopClosureAccessibilityEvidence: String, Codable, Hashable, Sendable {
    case unknown
}

struct StopClosureReplacementGuide: Codable, Hashable, Sendable {
    let routeID: String
    let replacementStopID: String
    let replacementStopName: String
    let closedStopLatitude: Double
    let closedStopLongitude: Double
    let latitude: Double
    let longitude: Double
    let walkingCoordinates: [BusMovementCoordinate]
    let walkingDistanceMeters: Double
    let expectedWalkingSeconds: TimeInterval
    let accessibilityEvidence: StopClosureAccessibilityEvidence
}

struct SimulatedStopClosure: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let stopID: String
    let stopName: String
    let routeIDs: [String]
    let closedAt: Date
    let scheduledOpenAt: Date
    var replacementGuidesByRouteID: [String: StopClosureReplacementGuide]? = nil
    var redirectedWaitingCountByRouteID: [String: Int]? = nil
    var passengerInformationMessage: String? = nil

    func isActive(at date: Date) -> Bool {
        closedAt <= date && date < scheduledOpenAt
    }

    func affects(stopID: String, routeID: String, at date: Date) -> Bool {
        self.stopID == stopID && routeIDs.contains(routeID) && isActive(at: date)
    }
}

private extension SimulatedStopClosure {
    var startedEventSummary: String {
        let replacements = (replacementGuidesByRouteID ?? [:]).values
            .sorted { $0.routeID < $1.routeID }
            .map { guide in
                let walkingMinutes = Int((guide.expectedWalkingSeconds / 60).rounded())
                let redirectedCount = max(0, redirectedWaitingCountByRouteID?[guide.routeID] ?? 0)
                let transfer = redirectedCount > 0 ? " · \(redirectedCount) déjà en attente redirigé(s)" : ""
                return "ligne \(guide.routeID) → \(guide.replacementStopName) · \(Int(guide.walkingDistanceMeters.rounded())) m · environ \(walkingMinutes) min à pied\(transfer) · accessibilité non vérifiée"
            }
            .joined(separator: "; ")
        let replacementDescription = replacements.isEmpty ? "" : " · remplacement : \(replacements)"
        let informationDescription = passengerInformationMessage.map { " · information voyageurs publiée : \($0)" } ?? " · aucun message voyageurs publié"
        return "Fermeture temporaire de \(stopName) · \(routeIDs.count) ligne(s)\(replacementDescription)\(informationDescription) · réouverture prévue \(scheduledOpenAt.formatted(date: .omitted, time: .shortened))"
    }
}

struct SimulatedRouteDetour: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let routeID: String
    let fromStopID: String
    let fromStopName: String
    let fromStopSequence: Int
    let toStopID: String
    let toStopName: String
    let toStopSequence: Int
    let startsAt: Date
    var scheduledEndAt: Date
    var endedAt: Date? = nil
    let replacementCoordinates: [BusMovementCoordinate]
    let additionalTravelSeconds: TimeInterval
    var sourceObservation: PRIMTrafficObservation? = nil
    var passengerInformationMessage: String? = nil

    func isActive(at date: Date) -> Bool {
        endedAt == nil && startsAt <= date && date < scheduledEndAt
    }
}

struct SimulatedRouteClosure: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let routeID: String
    let routeName: String
    let startsAt: Date
    var scheduledEndAt: Date
    var endedAt: Date? = nil

    func isActive(at date: Date) -> Bool {
        endedAt == nil && startsAt <= date && date < scheduledEndAt
    }
}

private extension SimulatedRouteClosure {
    var startedEventSummary: String {
        "Suspension de la ligne \(routeName) · aucun nouveau départ · les courses déjà engagées continuent · reprise prévue \(scheduledEndAt.formatted(date: .omitted, time: .shortened))"
    }
}

struct RouteDetourEventDetails: Codable, Hashable, Sendable {
    let detourID: String
    let routeID: String
    let fromStopName: String
    let toStopName: String
    let scheduledEndAt: Date

    init(_ detour: SimulatedRouteDetour) {
        detourID = detour.id
        routeID = detour.routeID
        fromStopName = detour.fromStopName
        toStopName = detour.toStopName
        scheduledEndAt = detour.scheduledEndAt
    }
}

enum SimulationEventKind: Codable, Hashable, Sendable {
    case serviceDeparture(tripID: String)
    case scheduledServiceDeparture(tripID: String, routeID: String, serviceDateKey: Int)
    case missedServiceDeparture(tripID: String, routeID: String)
    case routeServiceSuspended(tripID: String, routeID: String, closureID: String)
    case vehicleDelivered(vehicleID: String)
    case busDeadheadStarted(tripID: String, routeID: String, vehicleID: String, stopID: String, stopName: String, latitude: Double, longitude: Double, plan: VehicleDeadheadPlan)
    case busDeadheadArrived(tripID: String, routeID: String, vehicleID: String, stopID: String, stopName: String, latitude: Double, longitude: Double, distanceMeters: Double)
    case busDepotReturnStarted(vehicleID: String, plan: VehicleDepotReturnPlan)
    case busDepotReturnArrived(vehicleID: String, depotID: String, depotName: String, latitude: Double, longitude: Double, distanceMeters: Double)
    case busDepotReturnArrivedWithMachinist(tripID: String, vehicleID: String, depotID: String, depotName: String, latitude: Double, longitude: Double, distanceMeters: Double)
    case busDeparted(tripID: String, vehicleID: String, stopID: String, stopName: String, latitude: Double, longitude: Double)
    case vehicleReplacementDeparted(incidentID: String, tripID: String, vehicleID: String, stopID: String, stopName: String, latitude: Double, longitude: Double, delaySeconds: TimeInterval)
    case busMovementStarted(vehicleID: String, leg: ScheduledBusMovementLeg)
    case busAtStop(tripID: String, vehicleID: String, stopID: String, stopName: String, stopSequence: Int, latitude: Double, longitude: Double)
    case busStopBypassed(tripID: String, vehicleID: String, routeID: String, stopID: String, stopName: String, movementLeg: ScheduledBusMovementLeg?)
    case busServiceCompletedAtClosedStop(tripID: String, vehicleID: String, routeID: String, stopID: String, stopName: String, latitude: Double, longitude: Double, strandedPassengerCount: Int)
    case busServiceCompletedAtClosedStopWithPassengerRedirect(tripID: String, vehicleID: String, routeID: String, stopID: String, stopName: String, latitude: Double, longitude: Double, passengerCount: Int, replacementStopID: String, replacementStopName: String)
    case passengerDemand(PassengerStopDemand)
    case passengersExchanged(PassengerStopExchange)
    case busServiceCompleted(tripID: String, vehicleID: String, stopID: String, stopName: String, latitude: Double, longitude: Double)
    case vehicleBreakdown(VehicleIncident)
    case vehicleDiagnosticCompleted(incidentID: String, finding: VehicleIncidentDiagnosticFinding)
    case vehicleTowTeamArrived(incidentID: String)
    case vehicleTowStarted(incidentID: String)
    case vehicleTowArrived(incidentID: String)
    case vehicleWorkshopWorkStarted(incidentID: String)
    case workshopExpansionCompleted
    case workshopExpansionCompletedAtDepot(depotID: String)
    case depotEnergyInfrastructureCompleted(projectID: String, infrastructure: DepotEnergyInfrastructureKind)
    case batteryRechargeCompleted(planID: String, vehicleID: String, chargeKWh: Double)
    case workshopPartsDelivered(orderID: String)
    case vehicleRepairCompleted(incidentID: String)
    case vehicleMaintenanceStarted(maintenanceID: String)
    case vehicleMaintenanceCompleted(maintenanceID: String)
    case machinistAbsenceCompleted(absenceID: String)
    case machinistTrainingCompleted(trainingID: String)
    case machinistBreakStarted(breakID: String)
    case machinistBreakCompleted(breakID: String)
    case machinistRelieved(tripID: String, vehicleID: String, routeID: String, outgoingMachinistName: String, incomingMachinistName: String, stopName: String)
    case stopClosureStarted(SimulatedStopClosure)
    case stopClosureEnded(closureID: String, stopID: String, stopName: String)
    case routeClosureStarted(SimulatedRouteClosure)
    case routeClosureEnded(closureID: String, routeID: String, routeName: String)
    case routeDetourScheduled(RouteDetourEventDetails, startsAt: Date)
    case routeDetourStarted(RouteDetourEventDetails)
    case routeDetourReplanned(tripID: String, routeID: String, addedDelaySeconds: TimeInterval, addedDistanceMeters: Double)
    case followingServiceDelayed(fromTripID: String, toTripID: String, routeID: String, delaySeconds: TimeInterval)
    case routeDetourExtended(RouteDetourEventDetails)
    case routeDetourEnded(RouteDetourEventDetails)
    case stopArrival(tripID: String, stopID: String)
    case serviceCompleted(tripID: String)
    case incidentStarted(incidentID: String)
    case dailySettlement(dateKey: Int)
    case loanIssued(loanID: String, principalEuro: Int, termMonths: Int)
    case loanInstallmentDue(loanID: String, installmentNumber: Int)
    case invoiceSettlementDue(invoiceID: String)
}

struct SimulationEvent: Codable, Hashable, Identifiable, Sendable {
    let sequence: UInt64
    let simulatedAt: Date
    let kind: SimulationEventKind

    var id: UInt64 { sequence }

    var summary: String {
        switch kind {
        case let .serviceDeparture(tripID):
            "Départ de course \(tripID)"
        case let .scheduledServiceDeparture(_, routeID, _):
            "Départ prévu de la ligne \(routeID)"
        case let .missedServiceDeparture(tripID, routeID):
            "Course non assurée · ligne \(routeID), course \(tripID)"
        case let .routeServiceSuspended(tripID, routeID, _):
            "Départ suspendu · ligne \(routeID), course \(tripID)"
        case .vehicleDelivered:
            "Livraison d’un bus au dépôt"
        case let .busDeadheadStarted(tripID, routeID, _, _, stopName, _, _, _):
            "Sortie du dépôt · ligne \(routeID), course \(tripID) vers \(stopName)"
        case let .busDeadheadArrived(tripID, routeID, _, _, stopName, _, _, distanceMeters):
            "Arrivée au premier arrêt · ligne \(routeID), course \(tripID), \((distanceMeters / 1_000).formatted(.number.precision(.fractionLength(1)))) km à vide · \(stopName)"
        case let .busDepotReturnStarted(vehicleID, plan):
            "Retour à vide vers \(plan.depotName) · bus \(vehicleID) · ETA MapKit"
        case let .busDepotReturnArrived(vehicleID, _, depotName, _, _, distanceMeters):
            "Retour au dépôt terminé · bus \(vehicleID) · \((distanceMeters / 1_000).formatted(.number.precision(.fractionLength(1)))) km à vide · \(depotName)"
        case let .busDepotReturnArrivedWithMachinist(_, vehicleID, _, depotName, _, _, distanceMeters):
            "Retour au dépôt terminé · bus \(vehicleID) avec machiniste · \((distanceMeters / 1_000).formatted(.number.precision(.fractionLength(1)))) km à vide · \(depotName)"
        case let .busDeparted(tripID, _, _, _, _, _):
            "Départ en ligne · course \(tripID)"
        case let .vehicleReplacementDeparted(_, tripID, _, stopID, stopName, _, _, delaySeconds):
            "Reprise après panne · course \(tripID) à \(stopName) (arrêt \(stopID)) · retard \(Int(max(0, delaySeconds) / 60)) min"
        case .busMovementStarted:
            "Progression sur le tracé GTFS"
        case let .busAtStop(_, _, _, stopName, _, _, _):
            "Passage à l’arrêt \(stopName)"
        case let .busStopBypassed(_, _, routeID, _, stopName, _):
            "Arrêt fermé franchi sans desserte · ligne \(routeID), \(stopName)"
        case let .busServiceCompletedAtClosedStop(tripID, _, routeID, _, stopName, _, _, passengerCount):
            "Fin de course \(tripID) · terminus fermé de la ligne \(routeID), \(stopName) · \(passengerCount) voyageur(s) pris en charge par la fermeture"
        case let .busServiceCompletedAtClosedStopWithPassengerRedirect(tripID, _, routeID, _, stopName, _, _, passengerCount, replacementStopID, replacementStopName):
            "Fin de course \(tripID) · terminus fermé de la ligne \(routeID), \(stopName) · \(passengerCount) voyageur(s) redirigé(s) vers \(replacementStopName) (\(replacementStopID))"
        case let .passengerDemand(demand):
            "Demande voyageurs estimée à \(demand.stopName)"
        case let .passengersExchanged(exchange):
            exchange.eventSummary
        case let .busServiceCompleted(tripID, _, stopName, _, _, _):
            "Fin de course \(tripID) · \(stopName)"
        case let .vehicleBreakdown(incident):
            "Panne \(incident.severity.title.lowercased()) · bus \(incident.vehicleModelName), ligne \(incident.routeID), \(incident.stopName)"
        case let .vehicleDiagnosticCompleted(incidentID, finding):
            "Diagnostic de jeu terminé · panne \(incidentID) · \(finding.title.lowercased())"
        case .vehicleTowTeamArrived:
            "Équipe de dépannage arrivée au point de panne"
        case .vehicleTowStarted:
            "Remorquage du bus vers le dépôt commencé"
        case .vehicleRepairCompleted:
            "Intervention terminée · bus remis à disposition"
        case .vehicleTowArrived:
            "Bus remorqué jusqu’au dépôt · entrée dans la file d’atelier"
        case .vehicleWorkshopWorkStarted:
            "Début de réparation en atelier"
        case .workshopExpansionCompleted:
            "Extension terminée · deuxième baie d’atelier disponible"
        case let .workshopExpansionCompletedAtDepot(depotID):
            "Extension terminée · deuxième baie d’atelier disponible au dépôt \(DepotCareerScope.depotReference(for: depotID)?.name ?? depotID)"
        case let .depotEnergyInfrastructureCompleted(_, infrastructure):
            "Installation terminée · \(infrastructure.title.lowercased()) disponible au dépôt"
        case let .batteryRechargeCompleted(_, vehicleID, _):
            "Recharge complète · bus \(vehicleID)"
        case .workshopPartsDelivered:
            "Livraison de pièces d’atelier reçue"
        case .vehicleMaintenanceStarted:
            "Début de l’entretien préventif en atelier"
        case .vehicleMaintenanceCompleted:
            "Entretien préventif terminé"
        case .machinistAbsenceCompleted:
            "Absence machiniste terminée"
        case .machinistTrainingCompleted:
            "Formation terminée · qualification bus articulé obtenue"
        case .machinistBreakStarted:
            "Début de la pause machiniste"
        case .machinistBreakCompleted:
            "Fin de la pause machiniste"
        case let .machinistRelieved(_, _, routeID, outgoingName, incomingName, stopName):
            "Relève sur la ligne \(routeID) à \(stopName) · \(outgoingName) cède la course à \(incomingName)"
        case let .stopClosureStarted(closure):
            closure.startedEventSummary
        case let .stopClosureEnded(_, _, stopName):
            "Réouverture de l’arrêt \(stopName)"
        case let .routeClosureStarted(closure):
            closure.startedEventSummary
        case let .routeClosureEnded(_, _, routeName):
            "Reprise des départs · ligne \(routeName)"
        case let .routeDetourScheduled(details, startsAt):
            "Déviation planifiée · ligne \(details.routeID), \(details.fromStopName) → \(details.toStopName) · début \(startsAt.formatted(date: .omitted, time: .shortened))"
        case let .routeDetourStarted(details):
            "Déviation active · ligne \(details.routeID), \(details.fromStopName) → \(details.toStopName)"
        case let .routeDetourReplanned(tripID, routeID, addedDelaySeconds, addedDistanceMeters):
            "Course \(tripID) recalée sur la déviation de la ligne \(routeID) · +\(Int((addedDelaySeconds / 60).rounded())) min · +\((addedDistanceMeters / 1_000).formatted(.number.precision(.fractionLength(1)))) km"
        case let .followingServiceDelayed(fromTripID, toTripID, routeID, delaySeconds):
            "Retard propagé de la course \(fromTripID) à la course \(toTripID) · ligne \(routeID) · +\(Int((delaySeconds / 60).rounded())) min"
        case let .routeDetourExtended(details):
            "Déviation prolongée · ligne \(details.routeID), \(details.fromStopName) → \(details.toStopName) · fin \(details.scheduledEndAt.formatted(date: .omitted, time: .shortened))"
        case let .routeDetourEnded(details):
            "Fin de déviation · ligne \(details.routeID), \(details.fromStopName) → \(details.toStopName)"
        case let .stopArrival(_, stopID):
            "Arrivée à l’arrêt \(stopID)"
        case .serviceCompleted:
            "Fin de course"
        case .incidentStarted:
            "Incident déclenché"
        case .dailySettlement:
            "Bilan journalier"
        case let .loanIssued(_, principalEuro, termMonths):
            "Crédit de jeu reçu · \(principalEuro.formatted()) € · \(termMonths) mois"
        case let .loanInstallmentDue(_, installmentNumber):
            "Échéance de crédit de jeu · mensualité \(installmentNumber)"
        case let .invoiceSettlementDue(invoiceID):
            "Règlement de facture · \(invoiceID)"
        }
    }
}

struct ScheduledServiceDeparture: Hashable, Sendable {
    let tripID: String
    let routeID: String
    let serviceDateKey: Int
    let departureAt: Date
}

struct ScheduledTripStopVisit: Codable, Hashable, Sendable {
    let stopID: String
    let stopName: String
    let stopSequence: Int
    let latitude: Double
    let longitude: Double
    let scheduledAt: Date
    let departureAt: Date?
    let movementToNext: [BusMovementCoordinate]?
    let movementGeometrySource: ServiceMovementGeometrySource?
}

struct RouteDetourScheduleApplication: Hashable, Sendable {
    let visits: [ScheduledTripStopVisit]
    let appliedDetourIDs: Set<String>
}

enum RouteDetourSchedulePlanner {
    static func applying(
        detours: [SimulatedRouteDetour],
        to sourceVisits: [ScheduledTripStopVisit],
        alreadyAppliedDetourIDs: Set<String> = []
    ) -> RouteDetourScheduleApplication {
        var visits = sourceVisits
        var appliedDetourIDs = alreadyAppliedDetourIDs
        let orderedDetours = detours
            .filter { $0.endedAt == nil && !appliedDetourIDs.contains($0.id) }
            .sorted {
                if $0.fromStopSequence != $1.fromStopSequence {
                    return $0.fromStopSequence < $1.fromStopSequence
                }
                return $0.id < $1.id
            }

        for detour in orderedDetours {
            guard let fromIndex = visits.indices.dropLast().first(where: { index in
                visits[index].stopID == detour.fromStopID
                    && visits[index].stopSequence == detour.fromStopSequence
                    && visits[index + 1].stopID == detour.toStopID
                    && visits[index + 1].stopSequence == detour.toStopSequence
            }) else { continue }
            let segmentDepartureAt = visits[fromIndex].departureAt ?? visits[fromIndex].scheduledAt
            guard detour.startsAt <= segmentDepartureAt,
                  segmentDepartureAt < detour.scheduledEndAt,
                  validCoordinates(detour.replacementCoordinates, from: visits[fromIndex], to: visits[fromIndex + 1]) else {
                continue
            }

            var shiftedVisits: [ScheduledTripStopVisit] = []
            var canShift = true
            for index in (fromIndex + 1)..<visits.count {
                let visit = visits[index]
                let shiftedScheduledAt = visit.scheduledAt.addingTimeInterval(detour.additionalTravelSeconds)
                let shiftedDepartureAt = visit.departureAt?.addingTimeInterval(detour.additionalTravelSeconds)
                guard shiftedScheduledAt.timeIntervalSince1970.isFinite,
                      shiftedDepartureAt?.timeIntervalSince1970.isFinite ?? true else {
                    canShift = false
                    break
                }
                shiftedVisits.append(ScheduledTripStopVisit(
                    stopID: visit.stopID,
                    stopName: visit.stopName,
                    stopSequence: visit.stopSequence,
                    latitude: visit.latitude,
                    longitude: visit.longitude,
                    scheduledAt: shiftedScheduledAt,
                    departureAt: shiftedDepartureAt,
                    movementToNext: visit.movementToNext,
                    movementGeometrySource: visit.movementGeometrySource
                ))
            }
            guard canShift else { continue }

            let startVisit = visits[fromIndex]
            visits[fromIndex] = ScheduledTripStopVisit(
                stopID: startVisit.stopID,
                stopName: startVisit.stopName,
                stopSequence: startVisit.stopSequence,
                latitude: startVisit.latitude,
                longitude: startVisit.longitude,
                scheduledAt: startVisit.scheduledAt,
                departureAt: startVisit.departureAt,
                movementToNext: detour.replacementCoordinates,
                movementGeometrySource: .temporaryRouteDetour
            )
            for (offset, shiftedVisit) in shiftedVisits.enumerated() {
                visits[fromIndex + 1 + offset] = shiftedVisit
            }
            appliedDetourIDs.insert(detour.id)
        }
        return RouteDetourScheduleApplication(visits: visits, appliedDetourIDs: appliedDetourIDs)
    }

    private static func validCoordinates(
        _ coordinates: [BusMovementCoordinate],
        from start: ScheduledTripStopVisit,
        to end: ScheduledTripStopVisit
    ) -> Bool {
        guard coordinates.count >= 2,
              coordinates.allSatisfy({ coordinate in
                  coordinate.latitude.isFinite
                      && coordinate.longitude.isFinite
                      && (-90...90).contains(coordinate.latitude)
                      && (-180...180).contains(coordinate.longitude)
              }),
              let first = coordinates.first,
              let last = coordinates.last else { return false }
        return abs(first.latitude - start.latitude) <= 0.00001
            && abs(first.longitude - start.longitude) <= 0.00001
            && abs(last.latitude - end.latitude) <= 0.00001
            && abs(last.longitude - end.longitude) <= 0.00001
    }
}

struct DispatchedTripRoutePlan: Codable, Hashable, Sendable {
    let tripKey: String
    let tripID: String
    let routeID: String
    let serviceDateKey: Int
    let vehicleID: String
    let machinistID: String
    let passengerCapacity: Int
    let capacityIsEstimated: Bool
    var stopVisits: [ScheduledTripStopVisit]
    var appliedDetourIDs: Set<String>
    var stopEventSequencesByStopSequence: [Int: UInt64]
    var demandEventSequencesByStopSequence: [Int: UInt64]
    var movementEventSequencesByFromStopSequence: [Int: UInt64]
    var completionEventSequence: UInt64?
}

struct GTFSRouteServiceTrip: Identifiable, Hashable, Sendable {
    let tripID: String
    let routeID: String
    let serviceDateKey: Int
    let directionID: String
    let headsign: String
    let stops: [ScheduledTripStopVisit]

    var id: String { "\(serviceDateKey)|\(routeID)|\(tripID)" }
}

struct GTFSRouteTimetable: Hashable, Sendable {
    let trips: [GTFSRouteServiceTrip]
    let unusableTripCount: Int
}

enum ServiceMovementGeometrySource: String, Codable, Hashable, Sendable {
    case gtfsShape
    case stopCoordinateEstimate
    case temporaryRouteDetour
}

struct PassengerStopDemand: Codable, Hashable, Sendable {
    let tripID: String
    let vehicleID: String
    let routeID: String
    let stopID: String
    let stopName: String
    var occurredAt: Date
    let estimatedArrivalsCount: Int
    let alightingShare: Double
    let isTerminal: Bool
    let capacity: Int
    let capacityIsEstimated: Bool
}

enum PassengerInformationRules {
    static let detourMessageArrivalAvoidanceRate = 0.10

    static func avoidedArrivals(from estimatedArrivals: Int) -> Int {
        let count = max(0, estimatedArrivals)
        return min(count, Int((Double(count) * detourMessageArrivalAvoidanceRate).rounded()))
    }
}

struct PassengerStopExchange: Codable, Hashable, Sendable {
    let tripID: String
    let vehicleID: String
    let routeID: String
    let stopID: String
    let stopName: String
    let occurredAt: Date
    let boardedCount: Int
    let alightedCount: Int
    let leftBehindCount: Int
    let onboardAfterExchange: Int
    let capacity: Int
    let capacityIsEstimated: Bool
    let estimatedArrivalsCount: Int?
    let waitingBeforeCount: Int?
    let waitingAfterCount: Int?
    let newlyLeftBehindCount: Int?
    var stopWasClosed: Bool? = nil
    var redirectedPassengerCount: Int? = nil
    var replacementStopID: String? = nil
    var replacementStopName: String? = nil
    var replacementWaitingAfterCount: Int? = nil
    var informedPassengersAvoidingRouteCount: Int? = nil
}

private extension PassengerStopExchange {
    var eventSummary: String {
        let informationEffect = (informedPassengersAvoidingRouteCount ?? 0) > 0
            ? " · message publié : \(informedPassengersAvoidingRouteCount ?? 0) arrivée(s) estimée(s) évitant cette ligne (règle de jeu)"
            : ""
        if stopWasClosed == true {
            guard let replacementStopID else {
                let leftBehind = newlyLeftBehindCount ?? estimatedArrivalsCount ?? leftBehindCount
                return "Arrêt fermé · \(leftBehind) voyageur(s) estimé(s) laissé(s) à quai à \(stopName)\(informationEffect)"
            }
            let replacementName = replacementStopName.map { "\($0) (\(replacementStopID))" } ?? replacementStopID
            return "Arrêt fermé · \(redirectedPassengerCount ?? 0) voyageur(s) redirigé(s) vers \(replacementName) · \(replacementWaitingAfterCount ?? 0) en attente\(informationEffect)"
        }
        return "Voyageurs estimés à \(stopName) · +\(boardedCount), −\(alightedCount), +\(newlyLeftBehindCount ?? leftBehindCount) laissés, \(waitingAfterCount ?? leftBehindCount) en attente\(informationEffect)"
    }
}

struct PassengerExchangeRecord: Codable, Hashable, Identifiable, Sendable {
    let eventSequence: UInt64
    let exchange: PassengerStopExchange

    var id: UInt64 { eventSequence }
}

struct BusMovementCoordinate: Codable, Hashable, Sendable {
    let latitude: Double
    let longitude: Double
}

struct VehicleDepotReturnDestination: Codable, Hashable, Sendable {
    let depotID: String
    let depotName: String
    let requestedAddress: String
    let resolvedAddress: String
    let coordinate: BusMovementCoordinate
}

struct VehicleTowPlan: Codable, Hashable, Sendable {
    let depotID: String
    let depotName: String
    let resolvedDepotAddress: String
    let routeDistanceMeters: Double
    let expectedTravelSeconds: TimeInterval
    let destination: BusMovementCoordinate
    let routeCoordinates: [BusMovementCoordinate]
    let calculatedAt: Date
    let routingSourceTitle: String
    var recoveryTeamID: String? = nil
    var recoveryTeamName: String? = nil
    var dispatchStartsAt: Date? = nil
    var dispatchRouteDistanceMeters: Double? = nil
    var dispatchExpectedTravelSeconds: TimeInterval? = nil
    var dispatchRouteCoordinates: [BusMovementCoordinate]? = nil

    var totalServiceDistanceMeters: Double {
        routeDistanceMeters + max(0, dispatchRouteDistanceMeters ?? 0)
    }

    var expectedRecoveryTeamArrivalAt: Date? {
        guard let dispatchStartsAt, let dispatchExpectedTravelSeconds else { return nil }
        return dispatchStartsAt.addingTimeInterval(dispatchExpectedTravelSeconds)
    }

    var expectedBusTowStartAt: Date? {
        expectedRecoveryTeamArrivalAt?.addingTimeInterval(VehicleRecoveryRules.towHookupDuration)
    }

    var expectedDepotArrivalAt: Date? {
        expectedBusTowStartAt?.addingTimeInterval(expectedTravelSeconds)
    }
}

enum VehicleRecoveryRules {
    static let simulatedTeamCountPerDepot = 1
    static let towHookupDuration: TimeInterval = 15 * 60

    static func teamID(for depotID: String) -> String {
        "simulated-recovery-team-\(depotID)"
    }

    static func teamName(for depotName: String) -> String {
        "Équipe simulée · \(depotName)"
    }
}

struct VehicleDeadheadPlan: Codable, Hashable, Sendable {
    let depotID: String
    let depotName: String
    let requestedDepotAddress: String?
    let resolvedDepotAddress: String
    let stopID: String
    let stopName: String
    let origin: BusMovementCoordinate
    let destination: BusMovementCoordinate
    let routeDistanceMeters: Double
    let expectedTravelSeconds: TimeInterval
    let routeCoordinates: [BusMovementCoordinate]
    let calculatedAt: Date
    let routingSourceTitle: String
}

struct VehicleDepotReturnPlan: Codable, Hashable, Sendable {
    let depotID: String
    let depotName: String
    let requestedDepotAddress: String
    let resolvedDepotAddress: String
    let originBusID: String
    let origin: BusMovementCoordinate
    let destination: BusMovementCoordinate
    let routeDistanceMeters: Double
    let expectedTravelSeconds: TimeInterval
    let routeCoordinates: [BusMovementCoordinate]
    let calculatedAt: Date
    let routingSourceTitle: String

    var destinationSnapshot: VehicleDepotReturnDestination {
        VehicleDepotReturnDestination(
            depotID: depotID,
            depotName: depotName,
            requestedAddress: requestedDepotAddress,
            resolvedAddress: resolvedDepotAddress,
            coordinate: destination
        )
    }
}

struct ScheduledBusMovementLeg: Codable, Hashable, Sendable {
    let startsAt: Date
    let endsAt: Date
    let coordinates: [BusMovementCoordinate]
    var geometrySource: ServiceMovementGeometrySource? = nil
    var depotReturnDestination: VehicleDepotReturnDestination? = nil
}

struct SimulationDataVersions: Codable, Hashable, Sendable {
    let gtfsID: String
    let routeGeometryID: String
    let contractID: String
    let lineReferenceID: String
}

struct TripDistanceRecord: Codable, Hashable, Identifiable, Sendable {
    let eventSequence: UInt64
    let tripID: String
    let tripInstanceID: String?
    let vehicleID: String
    let occurredAt: Date
    let distanceMeters: Double
    let energyConsumedUnits: Double?
    let estimatedEnergyCostEuro: Int?
    let estimatedServiceRevenueEuro: Int?
    let isServiceDistance: Bool?
    var serviceGeometrySource: ServiceMovementGeometrySource? = nil

    var id: UInt64 { eventSequence }
}

struct DailyDepotOperationsSummary: Codable, Hashable, Identifiable, Sendable {
    let depotID: String
    let servedDepartureCount: Int
    let missedDepartureCount: Int
    let completedTripCount: Int
    let tracedDistanceMeters: Double
    let recordedDepotExpensesEuro: Int

    var id: String { depotID }
}

struct DailyOperationsReport: Codable, Hashable, Identifiable, Sendable {
    let dateKey: Int
    let servedDepartureCount: Int
    let missedDepartureCount: Int
    let completedTripCount: Int
    let tracedDistanceMeters: Double
    let recordedPurchaseExpenses: Int
    let recordedVehicleSaleRevenue: Int?
    let machinistLaborExpensesEuro: Int?
    let estimatedEnergyExpenses: Int?
    let estimatedPassengerBoardings: Int?
    let estimatedPassengersLeftBehind: Int?
    let incidentCount: Int?
    let interruptedTripCount: Int?
    let repairExpenses: Int?
    let estimatedServiceRevenueEuro: Int?
    let contractCompletionRate: Double?
    let contractQualityAdjustmentEuro: Int?
    let preventiveMaintenanceExpenses: Int?
    let closingCashBalance: Int?
    var estimatedStopConnectorDistanceMeters: Double? = nil
    var temporaryDetourDistanceMeters: Double? = nil
    var depotSummaries: [DailyDepotOperationsSummary]? = nil

    var id: Int { dateKey }
}

struct SimulationSession: Codable, Hashable, Identifiable, Sendable {
    let id: String
    var scenarioID: String
    let depotID: String
    var managedDepotIDs: [String]? = nil
    var activeDepotID: String? = nil
    let networkVersions: SimulationDataVersions
    let randomSeed: UInt64
    let createdAt: Date
    var updatedAt: Date
    var simulatedAt: Date
    var speed: SimulationSpeed
    var resumeSpeed: SimulationSpeed
    var nextEventSequence: UInt64
    var pendingEvents: [SimulationEvent]
    var eventHistory: [SimulationEvent]
    var energySimulationVersion: Int? = nil
    var timetableHorizonEnd: Date?
    var operatedRouteIDs: [String]?
    var operatedRouteIDsByDepot: [String: [String]]? = nil
    var assignmentRecordIDs: [String]?
    var cashBalance: Int?
    var ownedBuses: [PurchasedBus]?
    var machinists: [Machinist]?
    var machinistServiceAssignments: [MachinistServiceAssignment]?
    var machinistAssignmentCorrections: [MachinistAssignmentCorrection]? = nil
    var plannedMachinistReliefs: [MachinistReliefPlan]? = nil
    var machinistDutyBlocks: [MachinistDutyBlock]?
    var machinistAbsences: [MachinistAbsence]?
    var machinistTrainings: [MachinistTrainingRecord]?
    var machinistBreaks: [MachinistBreak]?
    var machinistPayrollRecords: [MachinistPayrollRecord]?
    var workshopPartsStock: [VehicleWorkshopPartStock]?
    var workshopPartOrders: [VehicleWorkshopPartOrder]?
    var depotEnergyInfrastructureProjects: [DepotEnergyInfrastructureProject]? = nil
    var marketOffers: [VehicleMarketOffer]?
    var purchasedOfferQuantities: [String: Int]?
    var ledgerEntries: [SimulationLedgerEntry]?
    var tripDistanceRecords: [TripDistanceRecord]?
    var dailyOperationsReports: [DailyOperationsReport]?
    var passengerExchangeRecords: [PassengerExchangeRecord]?
    var passengerQueuesByRouteStopKey: [String: Int]?
    var passengerQueueUpdatedAtByRouteStopKey: [String: Date]?
    var vehicleIncidents: [VehicleIncident]?
    var vehicleMaintenanceRecords: [VehicleMaintenanceRecord]?
    var stopClosures: [SimulatedStopClosure]? = nil
    var routeClosures: [SimulatedRouteClosure]? = nil
    var routeDetours: [SimulatedRouteDetour]? = nil
    var dispatchedTripRoutePlans: [DispatchedTripRoutePlan]? = nil
    var primTrafficAlerts: [PRIMTrafficAlert]? = nil
    var breakdownFrequency: VehicleIncidentFrequency? = nil
    var workshopBayCount: Int? = nil
    var workshopExpansionCompletesAt: Date? = nil
    var workshopBayCountsByDepot: [String: Int]? = nil
    var workshopExpansionCompletesAtByDepot: [String: Date]? = nil
    var loans: [SimulationLoan]? = nil
    var invoices: [SimulationInvoice]? = nil
    var careerProgression: CareerProgressionState? = nil

    var effectiveManagedDepotIDs: Set<String> {
        Set((managedDepotIDs ?? [depotID]).filter { !$0.isEmpty } + [depotID])
    }

    var effectiveActiveDepotID: String {
        guard let activeDepotID, effectiveManagedDepotIDs.contains(activeDepotID) else { return depotID }
        return activeDepotID
    }

    func effectiveOperatedRouteIDs(for depotID: String) -> Set<String> {
        if let routesByDepot = operatedRouteIDsByDepot {
            return Set(routesByDepot[depotID] ?? [])
        }
        return depotID == self.depotID ? Set(operatedRouteIDs ?? []) : []
    }

    var allEffectiveOperatedRouteIDs: Set<String> {
        effectiveManagedDepotIDs.reduce(into: Set<String>()) { routeIDs, depotID in
            routeIDs.formUnion(effectiveOperatedRouteIDs(for: depotID))
        }
    }

    func depotEnergyReadiness(
        for infrastructure: DepotEnergyInfrastructureKind,
        depotID: String? = nil
    ) -> DepotEnergyReadiness {
        let depotID = depotID ?? effectiveActiveDepotID
        let evidence = DepotEnergyEvidenceCatalog.evidence(depotID: depotID, infrastructure: infrastructure)
        switch evidence.status {
        case .operationallyConfirmed:
            return .readyFromEvidence(evidence)
        case .gameplayAssumption:
            return .readyFromGameplayRule(evidence)
        case .intentDocumented, .unknown:
            if let project = depotEnergyInfrastructureProjects?.first(where: {
                $0.infrastructure == infrastructure
                    && ($0.depotID ?? self.depotID) == depotID
                    && $0.completedAt != nil
            }) {
                return .installedByPlayer(project)
            }
            if let project = depotEnergyInfrastructureProjects?.first(where: {
                $0.infrastructure == infrastructure
                    && ($0.depotID ?? self.depotID) == depotID
                    && $0.isPending
            }) {
                return .underConstruction(project)
            }
            if depotEnergyInfrastructureProjects == nil {
                return .legacyUnverified(evidence)
            }
            return .requiresInstallation(evidence)
        }
    }

    func installedChargingPointCount(for depotID: String? = nil) -> Int {
        let depotID = depotID ?? effectiveActiveDepotID
        return (depotEnergyInfrastructureProjects ?? []).filter {
            $0.infrastructure == .electricCharging && ($0.depotID ?? self.depotID) == depotID && $0.isComplete
        }
            .reduce(0) { $0 + max(0, $1.chargingPointCount ?? 0) }
    }

    func installedChargingPowerKilowatts(for depotID: String? = nil) -> Double {
        let depotID = depotID ?? effectiveActiveDepotID
        return (depotEnergyInfrastructureProjects ?? []).filter {
            $0.infrastructure == .electricCharging && ($0.depotID ?? self.depotID) == depotID && $0.isComplete
        }
            .reduce(0) { $0 + Double(max(0, $1.chargingPointCount ?? 0)) * max(0, $1.chargingPowerKilowatts ?? 0) }
    }

    var pendingRechargeVehicleIDs: Set<String> {
        Set(pendingEvents.compactMap { event in
            guard case let .batteryRechargeCompleted(_, vehicleID, _) = event.kind else { return nil }
            return vehicleID
        })
    }

    var effectiveBreakdownFrequency: VehicleIncidentFrequency {
        breakdownFrequency ?? .standard
    }

    func effectiveWorkshopBayCount(for depotID: String? = nil) -> Int {
        let depotID = depotID ?? effectiveActiveDepotID
        let storedCount = workshopBayCountsByDepot?[depotID]
            ?? (depotID == self.depotID ? workshopBayCount : nil)
            ?? VehicleWorkshopRules.initialRepairBayCount
        return min(VehicleWorkshopRules.maximumRepairBayCount, max(VehicleWorkshopRules.initialRepairBayCount, storedCount))
    }

    func workshopExpansionCompletionDate(for depotID: String? = nil) -> Date? {
        let depotID = depotID ?? effectiveActiveDepotID
        return workshopExpansionCompletesAtByDepot?[depotID]
            ?? (depotID == self.depotID ? workshopExpansionCompletesAt : nil)
    }

    func nextRecoveryTeamAvailableAt(depotID: String) -> Date {
        let teamID = VehicleRecoveryRules.teamID(for: depotID)
        let occupiedUntil = (vehicleIncidents ?? []).compactMap { incident -> Date? in
            guard incident.repairResponse == .towToDepot,
                  incident.towPlan?.depotID == depotID,
                  (incident.towPlan?.recoveryTeamID == teamID || incident.towPlan?.recoveryTeamID == nil) else { return nil }
            let plan = incident.towPlan
            let expectedArrival = plan?.expectedDepotArrivalAt
                ?? incident.depotArrivedAt
                ?? incident.towArrivedAt
                ?? incident.occurredAt.addingTimeInterval(plan?.expectedTravelSeconds ?? 0)
            return expectedArrival > simulatedAt ? expectedArrival : nil
        }.max()
        return max(simulatedAt, occupiedUntil ?? simulatedAt)
    }

    var activeStopClosures: [SimulatedStopClosure] {
        (stopClosures ?? []).filter { $0.isActive(at: simulatedAt) }
    }

    var activeRouteDetours: [SimulatedRouteDetour] {
        (routeDetours ?? []).filter { $0.isActive(at: simulatedAt) }
    }

    var activeRouteClosures: [SimulatedRouteClosure] {
        (routeClosures ?? []).filter { $0.isActive(at: simulatedAt) }
    }

    func activeRouteClosure(routeID: String, at date: Date) -> SimulatedRouteClosure? {
        (routeClosures ?? []).first { $0.routeID == routeID && $0.isActive(at: date) }
    }

    func routeDetour(id: String) -> SimulatedRouteDetour? {
        routeDetours?.first { $0.id == id }
    }

    func activeStopClosure(stopID: String, routeIDs: [String]) -> SimulatedStopClosure? {
        activeStopClosures.first { closure in
            closure.stopID == stopID && !Set(closure.routeIDs).isDisjoint(with: routeIDs)
        }
    }

    var incidentAwaitingRepairResponse: VehicleIncident? {
        let incidentsWithScheduledRepairs = Set(pendingEvents.compactMap { event -> String? in
            guard case let .vehicleRepairCompleted(incidentID) = event.kind else { return nil }
            return incidentID
        })
        let incidentsWithPendingDiagnostics = Set(pendingEvents.compactMap { event -> String? in
            guard case let .vehicleDiagnosticCompleted(incidentID, _) = event.kind else { return nil }
            return incidentID
        })
        return vehicleIncidents?
            .filter { incident in
                !incident.isResolved
                    && incident.repairResponse == nil
                    && !incidentsWithScheduledRepairs.contains(incident.id)
                    && !(incident.requiresDiagnosis
                        && incident.diagnosisCompletedAt == nil
                        && incidentsWithPendingDiagnostics.contains(incident.id))
            }
            .min { $0.occurredAt < $1.occurredAt }
    }

    var pendingServiceDepartureCount: Int {
        pendingEvents.reduce(into: 0) { count, event in
            if case .scheduledServiceDeparture = event.kind { count += 1 }
        }
    }

    var missedServiceDepartureCount: Int {
        eventHistory.reduce(into: 0) { count, event in
            switch event.kind {
            case .missedServiceDeparture, .routeServiceSuspended:
                count += 1
            default:
                break
            }
        }
    }
}

private enum SimulationSaveStore {
    private static let directoryName = "saves"

    struct LoadedMostRecentSave {
        let session: SimulationSession
        let unreadableFileNames: [String]
    }

    static func save(_ session: SimulationSession) throws {
        let directory = try savesDirectory()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try encodedData(for: session)
        try data.write(to: directory.appending(path: "\(session.id).json"), options: .atomic)
    }

    static func encodedData(for session: SimulationSession) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(session)
    }

    static func decode(_ data: Data) throws -> SimulationSession {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(SimulationSession.self, from: data)
    }

    static func loadMostRecent() throws -> LoadedMostRecentSave? {
        let directory = try savesDirectory()
        guard FileManager.default.fileExists(atPath: directory.path) else { return nil }
        let urls = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )
        let saveURLs = urls.filter { $0.pathExtension.lowercased() == "json" }.sorted { left, right in
            let leftDate = (try? left.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let rightDate = (try? right.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return leftDate > rightDate
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        var lastError: Error?
        var unreadableFileNames: [String] = []
        for url in saveURLs {
            do {
                let session = try decoder.decode(SimulationSession.self, from: Data(contentsOf: url))
                return LoadedMostRecentSave(session: session, unreadableFileNames: unreadableFileNames)
            } catch {
                lastError = error
                unreadableFileNames.append(url.lastPathComponent)
            }
        }
        if let lastError { throw lastError }
        return nil
    }

    private static func savesDirectory() throws -> URL {
        try NetworkVersionStore.rootDirectory().appending(path: directoryName, directoryHint: .isDirectory)
    }
}

@MainActor
final class SimulationEngine: ObservableObject {
    @Published private(set) var session: SimulationSession?
    @Published private(set) var isRunning = false
    @Published private(set) var lastSavedAt: Date?
    @Published private(set) var errorMessage: String?
    @Published private(set) var recoveryNotice: String?

    private var clockTask: Task<Void, Never>?
    private var lastTickUptime: TimeInterval?
    private var lastAutosaveUptime: TimeInterval?
    private let tickIntervalNanoseconds: UInt64 = 200_000_000
    private let autosaveInterval: TimeInterval = 30

    init() {
        do {
            let loadedSave = try SimulationSaveStore.loadMostRecent()
            session = loadedSave?.session
            if let loadedSave, !loadedSave.unreadableFileNames.isEmpty {
                let skippedFiles = loadedSave.unreadableFileNames.joined(separator: ", ")
                recoveryNotice = "La sauvegarde la plus récente (\(skippedFiles)) est illisible. La carrière a été reprise depuis la sauvegarde du \(loadedSave.session.updatedAt.formatted(date: .abbreviated, time: .shortened))."
            }
            if var restoredSession = session {
                let savedProgression = restoredSession.careerProgression
                CareerProgressionCatalog.reconcile(session: &restoredSession)
                let progressionChanged = savedProgression != restoredSession.careerProgression
                if restoredSession.speed != .paused {
                    restoredSession.resumeSpeed = restoredSession.speed
                    restoredSession.speed = .paused
                    session = restoredSession
                    save()
                } else {
                    session = restoredSession
                    lastSavedAt = restoredSession.updatedAt
                    if progressionChanged { save() }
                }
            }
        } catch {
            errorMessage = "La dernière sauvegarde de partie n’a pas pu être lue : \(error.localizedDescription)"
        }
    }

    func setActiveDepot(_ depotID: String) {
        guard var activeSession = session,
              activeSession.effectiveManagedDepotIDs.contains(depotID),
              DepotCareerScope.supports(scenarioID: activeSession.scenarioID, depotID: depotID) else { return }
        activeSession.activeDepotID = depotID
        activeSession.updatedAt = Date.now
        session = activeSession
        save()
    }

    func addManagedDepot(
        _ depotID: String,
        operatedRouteIDs depotRouteIDs: [String],
        assignmentRecordIDs newAssignmentRecordIDs: [String] = [],
        scheduledDepartures: [ScheduledServiceDeparture] = []
    ) throws {
        guard var activeSession = session,
              DepotCareerScope.depotReference(for: depotID) != nil else {
            throw SimulationEngineError.marketUnavailable
        }
        guard !activeSession.effectiveManagedDepotIDs.contains(depotID) else {
            activeSession.activeDepotID = depotID
            activeSession.updatedAt = Date.now
            session = activeSession
            save()
            return
        }

        let routesToAdd = Array(Set(depotRouteIDs).subtracting(activeSession.operatedRouteIDs ?? [])).sorted()
        if activeSession.scenarioID != DepotCareerScope.regionalCompanyScenarioID,
           DepotCareerScope.scenarioID(forDepotID: depotID) != activeSession.scenarioID {
            activeSession.scenarioID = DepotCareerScope.regionalCompanyScenarioID
        }
        var routeMap = activeSession.operatedRouteIDsByDepot ?? [
            activeSession.depotID: activeSession.operatedRouteIDs ?? []
        ]
        routeMap[depotID] = routesToAdd
        activeSession.operatedRouteIDsByDepot = routeMap
        activeSession.operatedRouteIDs = Array(Set((activeSession.operatedRouteIDs ?? []) + routesToAdd)).sorted()
        activeSession.managedDepotIDs = Array(activeSession.effectiveManagedDepotIDs.union([depotID])).sorted()
        activeSession.activeDepotID = depotID

        let horizonStart = activeSession.simulatedAt
        let horizonEnd = activeSession.timetableHorizonEnd ?? horizonStart.addingTimeInterval(48 * 60 * 60)
        let existingTripIDs = Set(activeSession.pendingEvents.compactMap { event -> String? in
            guard case let .scheduledServiceDeparture(tripID, _, _) = event.kind else { return nil }
            return tripID
        }).union(activeSession.eventHistory.compactMap { event -> String? in
            guard case let .scheduledServiceDeparture(tripID, _, _) = event.kind else { return nil }
            return tripID
        })
        for departure in scheduledDepartures
            .filter({ routesToAdd.contains($0.routeID) && $0.departureAt >= horizonStart && $0.departureAt < horizonEnd })
            .sorted(by: {
                if $0.departureAt != $1.departureAt { return $0.departureAt < $1.departureAt }
                if $0.routeID != $1.routeID { return $0.routeID < $1.routeID }
                return $0.tripID < $1.tripID
            }) where !existingTripIDs.contains(departure.tripID) {
            activeSession.pendingEvents.append(SimulationEvent(
                sequence: activeSession.nextEventSequence,
                simulatedAt: departure.departureAt,
                kind: .scheduledServiceDeparture(
                    tripID: departure.tripID,
                    routeID: departure.routeID,
                    serviceDateKey: departure.serviceDateKey
                )
            ))
            activeSession.nextEventSequence &+= 1
        }
        activeSession.pendingEvents.sort(by: Self.eventOrder)
        activeSession.assignmentRecordIDs = Array(Set((activeSession.assignmentRecordIDs ?? []) + newAssignmentRecordIDs)).sorted()
        activeSession.updatedAt = Date.now
        session = activeSession
        save()
    }

    func assignRoutesToDepot(
        _ routeIDs: [String],
        depotID: String,
        scheduledDepartures: [ScheduledServiceDeparture] = []
    ) throws {
        guard var activeSession = session,
              activeSession.effectiveManagedDepotIDs.contains(depotID),
              DepotCareerScope.depotReference(for: depotID) != nil else {
            throw SimulationEngineError.marketUnavailable
        }
        let routeSet = Set(routeIDs)
        guard !routeSet.isEmpty else { return }
        if activeSession.scenarioID != DepotCareerScope.regionalCompanyScenarioID,
           DepotCareerScope.scenarioID(forDepotID: depotID) != activeSession.scenarioID {
            activeSession.scenarioID = DepotCareerScope.regionalCompanyScenarioID
        }

        var routeMap = activeSession.operatedRouteIDsByDepot ?? [
            activeSession.depotID: activeSession.operatedRouteIDs ?? []
        ]
        for existingDepotID in Array(routeMap.keys) {
            routeMap[existingDepotID] = (routeMap[existingDepotID] ?? []).filter { !routeSet.contains($0) }
        }
        routeMap[depotID] = Array(Set((routeMap[depotID] ?? []) + routeSet)).sorted()
        activeSession.operatedRouteIDsByDepot = routeMap

        let existingRoutes = Set(activeSession.operatedRouteIDs ?? [])
        let newRoutes = routeSet.subtracting(existingRoutes)
        activeSession.operatedRouteIDs = Array(existingRoutes.union(routeSet)).sorted()
        let horizonStart = activeSession.simulatedAt
        let horizonEnd = activeSession.timetableHorizonEnd ?? horizonStart.addingTimeInterval(48 * 60 * 60)
        let existingTripIDs = Set(activeSession.pendingEvents.compactMap { event -> String? in
            guard case let .scheduledServiceDeparture(tripID, _, _) = event.kind else { return nil }
            return tripID
        }).union(activeSession.eventHistory.compactMap { event -> String? in
            guard case let .scheduledServiceDeparture(tripID, _, _) = event.kind else { return nil }
            return tripID
        })
        for departure in scheduledDepartures
            .filter({ newRoutes.contains($0.routeID) && $0.departureAt >= horizonStart && $0.departureAt < horizonEnd })
            .sorted(by: {
                if $0.departureAt != $1.departureAt { return $0.departureAt < $1.departureAt }
                if $0.routeID != $1.routeID { return $0.routeID < $1.routeID }
                return $0.tripID < $1.tripID
            }) where !existingTripIDs.contains(departure.tripID) {
            activeSession.pendingEvents.append(SimulationEvent(
                sequence: activeSession.nextEventSequence,
                simulatedAt: departure.departureAt,
                kind: .scheduledServiceDeparture(
                    tripID: departure.tripID,
                    routeID: departure.routeID,
                    serviceDateKey: departure.serviceDateKey
                )
            ))
            activeSession.nextEventSequence &+= 1
        }
        activeSession.pendingEvents.sort(by: Self.eventOrder)
        activeSession.activeDepotID = depotID
        activeSession.updatedAt = Date.now
        session = activeSession
        save()
    }

    func startNew(
        scenarioID: String,
        depotID: String,
        networkVersions: SimulationDataVersions,
        startDate: Date,
        operatedRouteIDs: [String],
        assignmentRecordIDs: [String],
        managedDepotIDs: [String] = [],
        operatedRouteIDsByDepot: [String: [String]]? = nil,
        scheduledDepartures: [ScheduledServiceDeparture] = [],
        timetableHorizonEnd: Date? = nil,
        breakdownFrequency: VehicleIncidentFrequency = .standard
    ) throws {
        let pinnedRouteIDs = Array(Set(operatedRouteIDs)).sorted()
        let pinnedAssignmentIDs = Array(Set(assignmentRecordIDs)).sorted()
        let eligibleDepotIDs = Set(managedDepotIDs.filter {
            DepotCareerScope.supports(scenarioID: scenarioID, depotID: $0)
        } + [depotID])
        guard !pinnedRouteIDs.isEmpty else {
            throw SimulationEngineError.noOperatedRoutes
        }
        let now = Date()
        var gameCalendar = Calendar(identifier: .gregorian)
        gameCalendar.timeZone = GTFSServiceDate.parisTimeZone
        let gameYear = gameCalendar.component(.year, from: startDate)
        var initialEvents = scheduledDepartures.filter { pinnedRouteIDs.contains($0.routeID) }.sorted {
            if $0.departureAt != $1.departureAt { return $0.departureAt < $1.departureAt }
            if $0.routeID != $1.routeID { return $0.routeID < $1.routeID }
            return $0.tripID < $1.tripID
        }.enumerated().map { offset, departure in
            SimulationEvent(
                sequence: UInt64(offset),
                simulatedAt: departure.departureAt,
                kind: .scheduledServiceDeparture(
                    tripID: departure.tripID,
                    routeID: departure.routeID,
                    serviceDateKey: departure.serviceDateKey
                )
            )
        }
        var nextEventSequence = UInt64(initialEvents.count)
        let settlementHorizon = timetableHorizonEnd ?? startDate.addingTimeInterval(48 * 60 * 60)
        initialEvents.append(contentsOf: Self.dailySettlementEvents(
            from: startDate,
            through: settlementHorizon,
            nextSequence: &nextEventSequence
        ))
        initialEvents.sort(by: Self.eventOrder)
        let newSession = SimulationSession(
            id: UUID().uuidString,
            scenarioID: scenarioID,
            depotID: depotID,
            managedDepotIDs: eligibleDepotIDs.sorted(),
            activeDepotID: depotID,
            networkVersions: networkVersions,
            randomSeed: UInt64.random(in: UInt64.min...UInt64.max),
            createdAt: now,
            updatedAt: now,
            simulatedAt: startDate,
            speed: .x1,
            resumeSpeed: .x1,
            nextEventSequence: nextEventSequence,
            pendingEvents: initialEvents,
            eventHistory: [],
            energySimulationVersion: 1,
            timetableHorizonEnd: timetableHorizonEnd,
            operatedRouteIDs: pinnedRouteIDs,
            operatedRouteIDsByDepot: operatedRouteIDsByDepot,
            assignmentRecordIDs: pinnedAssignmentIDs,
            cashBalance: VehicleMarketCatalog.initialCareerCapital - VehicleWorkshopPartCatalog.initialStockCostEuro,
            ownedBuses: [],
            machinists: [],
            machinistServiceAssignments: [],
            machinistAssignmentCorrections: [],
            machinistDutyBlocks: [],
            machinistAbsences: [],
            machinistTrainings: [],
            machinistBreaks: [],
            machinistPayrollRecords: [],
            workshopPartsStock: VehicleWorkshopPartCatalog.initialStock(forDepotID: depotID),
            workshopPartOrders: [],
            depotEnergyInfrastructureProjects: [],
            marketOffers: VehicleMarketCatalog.offers(for: gameYear),
            purchasedOfferQuantities: [:],
            ledgerEntries: [SimulationLedgerEntry(
                id: "initial-workshop-parts",
                occurredAt: startDate,
                category: "Pièces d’atelier",
                description: "Stock de départ · kits génériques d’entretien et de réparation par modèle de bus",
                amount: -VehicleWorkshopPartCatalog.initialStockCostEuro,
                depotID: depotID
            )],
            tripDistanceRecords: [],
            dailyOperationsReports: [],
            passengerExchangeRecords: [],
            passengerQueuesByRouteStopKey: [:],
            passengerQueueUpdatedAtByRouteStopKey: [:],
            vehicleIncidents: [],
            vehicleMaintenanceRecords: [],
            stopClosures: [],
            routeClosures: [],
            breakdownFrequency: breakdownFrequency,
            workshopBayCount: VehicleWorkshopRules.initialRepairBayCount,
            workshopExpansionCompletesAt: nil,
            loans: [],
            careerProgression: CareerProgressionState()
        )
        try SimulationSaveStore.save(newSession)
        session = newSession
        lastSavedAt = now
        errorMessage = nil
        startClockLoop()
    }

    func resume() {
        guard var activeSession = session,
              !isRunning else { return }
        if activeSession.speed == .paused {
            activeSession.speed = activeSession.resumeSpeed == .paused ? .x1 : activeSession.resumeSpeed
        }
        if activeSession.speed != .paused {
            activeSession.resumeSpeed = activeSession.speed
        }
        session = activeSession
        startClockLoop()
        save()
    }

    func pause() {
        let wasRunning = isRunning
        guard let currentSession = session,
              wasRunning || currentSession.speed != .paused else { return }
        if wasRunning { advanceFromRealtime() }
        isRunning = false
        clockTask?.cancel()
        clockTask = nil
        lastTickUptime = nil
        lastAutosaveUptime = nil

        if var activeSession = session {
            if activeSession.speed != .paused {
                activeSession.resumeSpeed = activeSession.speed
            }
            activeSession.speed = .paused
            session = activeSession
        }
        save()
    }

    func pauseAndSave() {
        if isRunning {
            pause()
        } else {
            save()
        }
    }

    func setSpeed(_ speed: SimulationSpeed) {
        guard session != nil else { return }
        if speed == .paused {
            pause()
            return
        }

        if isRunning {
            advanceFromRealtime()
        }
        guard var activeSession = session else { return }
        activeSession.speed = speed
        activeSession.resumeSpeed = speed
        session = activeSession
        if isRunning {
            lastTickUptime = ProcessInfo.processInfo.systemUptime
        } else {
            startClockLoop()
        }
        save()
    }

    func schedule(_ kind: SimulationEventKind, at simulatedAt: Date) {
        guard var activeSession = session else { return }
        let event = SimulationEvent(
            sequence: activeSession.nextEventSequence,
            simulatedAt: simulatedAt,
            kind: kind
        )
        activeSession.nextEventSequence &+= 1
        activeSession.pendingEvents.append(event)
        activeSession.pendingEvents.sort(by: Self.eventOrder)
        session = activeSession
        save()
    }

    func appendScheduledDepartures(_ departures: [ScheduledServiceDeparture], through horizonEnd: Date) {
        guard var activeSession = session,
              let routeIDs = activeSession.operatedRouteIDs,
              !routeIDs.isEmpty else { return }
        let operatedRouteIDs = Set(routeIDs)
        let horizonStart = activeSession.timetableHorizonEnd ?? activeSession.simulatedAt
        let newEvents = departures
            .filter {
                operatedRouteIDs.contains($0.routeID)
                    && $0.departureAt >= horizonStart
                    && $0.departureAt < horizonEnd
            }
            .sorted {
                if $0.departureAt != $1.departureAt { return $0.departureAt < $1.departureAt }
                if $0.routeID != $1.routeID { return $0.routeID < $1.routeID }
                return $0.tripID < $1.tripID
            }
            .map { departure in
                let event = SimulationEvent(
                    sequence: activeSession.nextEventSequence,
                    simulatedAt: departure.departureAt,
                    kind: .scheduledServiceDeparture(
                        tripID: departure.tripID,
                        routeID: departure.routeID,
                        serviceDateKey: departure.serviceDateKey
                    )
                )
                activeSession.nextEventSequence &+= 1
                return event
            }
        let dailyEvents = Self.dailySettlementEvents(
            from: horizonStart,
            through: horizonEnd,
            nextSequence: &activeSession.nextEventSequence
        )
        let existingSettlementKeys = Set(activeSession.pendingEvents.compactMap { event -> Int? in
            guard case let .dailySettlement(dateKey) = event.kind else { return nil }
            return dateKey
        }).union((activeSession.dailyOperationsReports ?? []).map(\.dateKey))
        let newDailyEvents = dailyEvents.filter { event in
            guard case let .dailySettlement(dateKey) = event.kind else { return false }
            return !existingSettlementKeys.contains(dateKey)
        }
        activeSession.pendingEvents.append(contentsOf: newEvents)
        activeSession.pendingEvents.append(contentsOf: newDailyEvents)
        activeSession.pendingEvents.sort(by: Self.eventOrder)
        activeSession.timetableHorizonEnd = max(activeSession.timetableHorizonEnd ?? horizonEnd, horizonEnd)
        session = activeSession
        save()
    }

    func hireMachinist(qualification: MachinistQualification, depotID: String? = nil) throws {
        guard var activeSession = session else { throw SimulationEngineError.marketUnavailable }
        var machinists = activeSession.machinists ?? []
        let employeeNumber = (machinists.map(\.employeeNumber).max() ?? 0) + 1
        machinists.append(Machinist(
            id: UUID().uuidString,
            employeeNumber: employeeNumber,
            qualification: qualification,
            hiredAt: activeSession.simulatedAt,
            depotID: depotID ?? activeSession.effectiveActiveDepotID
        ))
        activeSession.machinists = machinists
        activeSession.machinistServiceAssignments = activeSession.machinistServiceAssignments ?? []
        activeSession.machinistDutyBlocks = activeSession.machinistDutyBlocks ?? []
        activeSession.machinistAbsences = activeSession.machinistAbsences ?? []
        session = activeSession
        save()
    }

    func scheduleMachinistTraining(machinistID: String, startsAt: Date) throws {
        if isRunning { advanceFromRealtime() }
        guard var activeSession = session,
              let machinists = activeSession.machinists,
              let machinistIndex = machinists.firstIndex(where: { $0.id == machinistID }) else {
            throw SimulationEngineError.unknownMachinist
        }
        guard startsAt >= activeSession.simulatedAt else {
            throw SimulationEngineError.invalidMachinistTraining
        }
        guard machinists[machinistIndex].qualification == .standard else {
            throw SimulationEngineError.machinistAlreadyQualified
        }

        let endsAt = startsAt.addingTimeInterval(MachinistWorkRules.articulatedTrainingDuration)
        let machinist = machinists[machinistIndex]
        let absences = activeSession.machinistAbsences ?? []
        guard !absences.contains(where: {
            $0.machinistID == machinistID && Self.periodsOverlap(startsAt, endsAt, $0.startsAt, $0.endsAt)
        }) else {
            throw SimulationEngineError.machinistTrainingConflictsWithAbsence
        }

        let dutyBlocks = (activeSession.machinistDutyBlocks ?? []).filter { $0.machinistID == machinistID }
        for block in dutyBlocks {
            let blockEnd = block.actualEndAt ?? block.plannedEndAt
            guard Self.hasMinimumRest(
                between: startsAt,
                and: endsAt,
                and: block.plannedStartAt,
                blockEnd
            ) else {
                throw SimulationEngineError.machinistTrainingConflictsWithWork
            }
        }
        let assignments = (activeSession.machinistServiceAssignments ?? []).filter {
            $0.machinistID == machinistID && $0.dutyBlockID == nil
        }
        for assignment in assignments {
            let assignmentEnd = assignment.actualEndAt ?? assignment.plannedEndAt
            guard Self.hasMinimumRest(
                between: startsAt,
                and: endsAt,
                and: assignment.plannedStartAt,
                assignmentEnd
            ) else {
                throw SimulationEngineError.machinistTrainingConflictsWithWork
            }
        }

        var trainings = activeSession.machinistTrainings ?? []
        guard !trainings.contains(where: { $0.machinistID == machinistID && $0.isPending }) else {
            throw SimulationEngineError.machinistTrainingConflictsWithExistingTraining
        }
        for training in trainings where training.machinistID == machinistID && training.cancelledAt == nil {
            guard Self.hasMinimumRest(
                between: startsAt,
                and: endsAt,
                and: training.startsAt,
                training.endsAt
            ) else {
                throw SimulationEngineError.machinistTrainingConflictsWithExistingTraining
            }
        }

        let estimatedLaborCost = machinist.estimatedLoadedCostPerServiceHourEuro
            * MachinistWorkRules.articulatedTrainingDurationHours
        let training = MachinistTrainingRecord(
            id: UUID().uuidString,
            machinistID: machinistID,
            sourceQualification: .standard,
            targetQualification: .articulated,
            startsAt: startsAt,
            endsAt: endsAt,
            estimatedLaborCostEuro: estimatedLaborCost,
            recordedAt: activeSession.simulatedAt
        )
        trainings.append(training)
        activeSession.machinistTrainings = trainings
        let sequence = activeSession.nextEventSequence
        activeSession.nextEventSequence &+= 1
        activeSession.pendingEvents.append(SimulationEvent(
            sequence: sequence,
            simulatedAt: endsAt,
            kind: .machinistTrainingCompleted(trainingID: training.id)
        ))
        activeSession.pendingEvents.sort(by: Self.eventOrder)
        session = activeSession
        save()
    }

    func cancelMachinistTraining(trainingID: String) throws {
        if isRunning { advanceFromRealtime() }
        guard var activeSession = session,
              var trainings = activeSession.machinistTrainings,
              let trainingIndex = trainings.firstIndex(where: { $0.id == trainingID && $0.isPending }) else {
            throw SimulationEngineError.machinistTrainingUnavailable
        }
        guard trainings[trainingIndex].startsAt > activeSession.simulatedAt else {
            throw SimulationEngineError.machinistTrainingAlreadyStarted
        }
        trainings[trainingIndex].cancelledAt = activeSession.simulatedAt
        activeSession.machinistTrainings = trainings
        activeSession.pendingEvents.removeAll { event in
            guard case let .machinistTrainingCompleted(eventTrainingID) = event.kind else { return false }
            return eventTrainingID == trainingID
        }
        session = activeSession
        save()
    }

    func scheduleMachinistBreak(machinistID: String, windowID: String) throws {
        if isRunning { advanceFromRealtime() }
        guard var activeSession = session,
              activeSession.machinists?.contains(where: { $0.id == machinistID }) == true else {
            throw SimulationEngineError.unknownMachinist
        }
        let window = Self.machinistBreakWindows(
            machinistID: machinistID,
            simulatedAt: activeSession.simulatedAt,
            assignments: activeSession.machinistServiceAssignments ?? [],
            dutyBlocks: activeSession.machinistDutyBlocks ?? [],
            breaks: activeSession.machinistBreaks ?? [],
            absences: activeSession.machinistAbsences ?? [],
            trainings: activeSession.machinistTrainings ?? []
        ).first(where: { $0.id == windowID })
        guard let window else { throw SimulationEngineError.machinistBreakUnavailable }

        let breakRecord = MachinistBreak(
            id: UUID().uuidString,
            machinistID: machinistID,
            dutyBlockID: window.dutyBlockID,
            startsAt: window.startsAt,
            endsAt: window.endsAt,
            recordedAt: activeSession.simulatedAt
        )
        var breaks = activeSession.machinistBreaks ?? []
        breaks.append(breakRecord)
        activeSession.machinistBreaks = breaks
        let startSequence = activeSession.nextEventSequence
        activeSession.nextEventSequence &+= 1
        activeSession.pendingEvents.append(SimulationEvent(
            sequence: startSequence,
            simulatedAt: breakRecord.startsAt,
            kind: .machinistBreakStarted(breakID: breakRecord.id)
        ))
        let endSequence = activeSession.nextEventSequence
        activeSession.nextEventSequence &+= 1
        activeSession.pendingEvents.append(SimulationEvent(
            sequence: endSequence,
            simulatedAt: breakRecord.endsAt,
            kind: .machinistBreakCompleted(breakID: breakRecord.id)
        ))
        activeSession.pendingEvents.sort(by: Self.eventOrder)
        session = activeSession
        save()
    }

    func cancelMachinistBreak(breakID: String) throws {
        if isRunning { advanceFromRealtime() }
        guard var activeSession = session,
              var breaks = activeSession.machinistBreaks,
              let index = breaks.firstIndex(where: { $0.id == breakID && $0.isPending }) else {
            throw SimulationEngineError.machinistBreakUnavailable
        }
        guard breaks[index].startsAt > activeSession.simulatedAt else {
            throw SimulationEngineError.machinistBreakAlreadyStarted
        }
        breaks[index].cancelledAt = activeSession.simulatedAt
        activeSession.machinistBreaks = breaks
        activeSession.pendingEvents.removeAll { event in
            return switch event.kind {
            case let .machinistBreakStarted(eventBreakID), let .machinistBreakCompleted(eventBreakID):
                eventBreakID == breakID
            default:
                false
            }
        }
        session = activeSession
        save()
    }

    func scheduleMachinistAbsence(
        machinistID: String,
        startsAt: Date,
        endsAt: Date,
        absenceType: MachinistAbsenceType,
        estimatedPaidHours: Double,
        reason: String
    ) throws {
        if isRunning { advanceFromRealtime() }
        guard var activeSession = session else { throw SimulationEngineError.marketUnavailable }
        guard let machinist = activeSession.machinists?.first(where: { $0.id == machinistID }) else {
            throw SimulationEngineError.unknownMachinist
        }
        guard startsAt >= activeSession.simulatedAt, endsAt > startsAt else {
            throw SimulationEngineError.invalidMachinistAbsence
        }
        let absenceDurationHours = endsAt.timeIntervalSince(startsAt) / 3_600
        let estimatedCost = Double(machinist.estimatedLoadedCostPerServiceHourEuro)
            * estimatedPaidHours
            * absenceType.estimatedPayFactor
        let roundedEstimatedCost = estimatedCost.rounded()
        guard estimatedPaidHours.isFinite,
              estimatedPaidHours >= 0,
              estimatedPaidHours <= absenceDurationHours,
              roundedEstimatedCost.isFinite,
              roundedEstimatedCost < Double(Int.max) else {
            throw SimulationEngineError.invalidMachinistAbsenceCompensation
        }

        let cleanReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        let savedReason = cleanReason.isEmpty ? "Absence planifiée" : String(cleanReason.prefix(80))
        let trainings = activeSession.machinistTrainings ?? []
        guard !trainings.contains(where: {
            $0.machinistID == machinistID && $0.isPending
                && Self.periodsOverlap(startsAt, endsAt, $0.startsAt, $0.endsAt)
        }) else {
            throw SimulationEngineError.machinistAbsenceConflictsWithTraining
        }
        var absences = activeSession.machinistAbsences ?? []
        guard !absences.contains(where: {
            $0.machinistID == machinistID
                && Self.periodsOverlap(startsAt, endsAt, $0.startsAt, $0.endsAt)
        }) else {
            throw SimulationEngineError.machinistAbsenceConflictsWithExistingAbsence
        }

        let assignments = activeSession.machinistServiceAssignments ?? []
        let blocks = activeSession.machinistDutyBlocks ?? []
        let conflictsWithBlock = blocks.contains { block in
            guard block.machinistID == machinistID else { return false }
            if block.actualEndAt == nil,
               block.plannedStartAt <= activeSession.simulatedAt,
               block.plannedEndAt <= activeSession.simulatedAt { return true }
            let blockEnd = block.actualEndAt ?? block.plannedEndAt
            return Self.periodsOverlap(startsAt, endsAt, block.plannedStartAt, blockEnd)
        }
        let conflictsWithLegacyAssignment = assignments.contains { assignment in
            guard assignment.machinistID == machinistID,
                  assignment.dutyBlockID == nil,
                  assignment.actualEndAt == nil else { return false }
            if assignment.plannedStartAt <= activeSession.simulatedAt { return true }
            return Self.periodsOverlap(startsAt, endsAt, assignment.plannedStartAt, assignment.plannedEndAt)
        }
        let conflictsWithService = conflictsWithBlock || conflictsWithLegacyAssignment
        guard !conflictsWithService else {
            throw SimulationEngineError.machinistAbsenceConflictsWithService
        }

        let absenceID = UUID().uuidString
        absences.append(MachinistAbsence(
            id: absenceID,
            machinistID: machinistID,
            startsAt: startsAt,
            endsAt: endsAt,
            reason: savedReason,
            recordedAt: activeSession.simulatedAt,
            absenceType: absenceType,
            estimatedPaidHours: estimatedPaidHours,
            estimatedPayrollCostEuro: Int(roundedEstimatedCost)
        ))
        activeSession.machinistAbsences = absences
        let eventSequence = activeSession.nextEventSequence
        activeSession.nextEventSequence &+= 1
        activeSession.pendingEvents.append(SimulationEvent(
            sequence: eventSequence,
            simulatedAt: endsAt,
            kind: .machinistAbsenceCompleted(absenceID: absenceID)
        ))
        activeSession.pendingEvents.sort(by: Self.eventOrder)
        session = activeSession
        save()
    }

    func cancelMachinistAbsence(absenceID: String) throws {
        if isRunning { advanceFromRealtime() }
        guard var activeSession = session,
              var absences = activeSession.machinistAbsences,
              let index = absences.firstIndex(where: { $0.id == absenceID }) else {
            throw SimulationEngineError.machinistAbsenceUnavailable
        }
        guard absences[index].startsAt >= activeSession.simulatedAt else {
            throw SimulationEngineError.machinistAbsenceUnavailable
        }
        activeSession.pendingEvents.removeAll { event in
            guard case let .machinistAbsenceCompleted(eventAbsenceID) = event.kind else { return false }
            return eventAbsenceID == absenceID
        }
        absences.remove(at: index)
        activeSession.machinistAbsences = absences
        session = activeSession
        save()
    }

    func availableMachinists(
        forVehicleID vehicleID: String,
        serviceStartAt: Date,
        serviceEndAt: Date
    ) -> [Machinist] {
        guard let session,
              let bus = session.ownedBuses?.first(where: { $0.id == vehicleID }),
              serviceEndAt >= serviceStartAt else { return [] }
        let vehicleClass = VehicleMarketCatalog.model(id: bus.modelID)?.vehicleClass ?? .standard
        let assignments = session.machinistServiceAssignments ?? []
        let dutyBlocks = session.machinistDutyBlocks ?? []
        let absences = session.machinistAbsences ?? []
        return (session.machinists ?? [])
            .filter { machinist in
                (machinist.depotID ?? session.depotID) == bus.depotID
                    && machinist.hiredAt <= serviceStartAt
                    && machinist.qualification.canDrive(vehicleClass)
                    && Self.machinistDutyBlockAssignmentPlan(
                        machinist.id,
                        from: serviceStartAt,
                        to: serviceEndAt,
                        assignments: assignments,
                        dutyBlocks: dutyBlocks,
                        breaks: session.machinistBreaks ?? [],
                        absences: absences,
                        trainings: session.machinistTrainings ?? [],
                        allowReopeningSettledBlocks: true
                    ) != nil
            }
            .sorted { $0.employeeNumber < $1.employeeNumber }
    }

    func availableMachinistDutyBlockCorrectionCandidates(dutyBlockID: String) -> [Machinist] {
        guard let session,
              let block = session.machinistDutyBlocks?.first(where: { $0.id == dutyBlockID }) else { return [] }
        return (session.machinists ?? [])
            .filter { Self.canCorrectMachinistDutyBlock(block, to: $0, in: session) }
            .sorted { $0.employeeNumber < $1.employeeNumber }
    }

    func correctMachinistDutyBlock(
        dutyBlockID: String,
        toMachinistID: String,
        reason: String
    ) throws {
        if isRunning { advanceFromRealtime() }
        guard var activeSession = session,
              var dutyBlocks = activeSession.machinistDutyBlocks,
              let blockIndex = dutyBlocks.firstIndex(where: { $0.id == dutyBlockID }),
              let correctedMachinist = activeSession.machinists?.first(where: { $0.id == toMachinistID }) else {
            throw SimulationEngineError.machinistDutyBlockCorrectionUnavailable
        }
        let savedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard savedReason.count >= 4 else {
            throw SimulationEngineError.machinistDutyBlockCorrectionReasonRequired
        }
        let block = dutyBlocks[blockIndex]
        guard Self.canCorrectMachinistDutyBlock(block, to: correctedMachinist, in: activeSession),
              var assignments = activeSession.machinistServiceAssignments else {
            throw SimulationEngineError.machinistDutyBlockCorrectionConflict
        }
        guard let previousMachinist = activeSession.machinists?.first(where: { $0.id == block.machinistID }) else {
            throw SimulationEngineError.machinistDutyBlockCorrectionUnavailable
        }

        for index in assignments.indices where assignments[index].dutyBlockID == dutyBlockID {
            assignments[index].machinistID = toMachinistID
        }
        dutyBlocks[blockIndex].machinistID = toMachinistID

        var breaks = activeSession.machinistBreaks ?? []
        for index in breaks.indices where breaks[index].dutyBlockID == dutyBlockID {
            breaks[index].machinistID = toMachinistID
        }

        let payrollRecordID = "machinist-duty-\(dutyBlockID)"
        var payrollRecords = activeSession.machinistPayrollRecords ?? []
        if let payrollIndex = payrollRecords.firstIndex(where: { $0.id == payrollRecordID }) {
            payrollRecords[payrollIndex].machinistID = toMachinistID
            payrollRecords[payrollIndex].details += " · affectation corrigée de \(previousMachinist.displayName) à \(correctedMachinist.displayName) : \(savedReason)"
        }

        let updatedPayrollRecord = payrollRecords.first(where: { $0.id == payrollRecordID })
        var ledgerEntries = activeSession.ledgerEntries ?? []
        if let ledgerIndex = ledgerEntries.firstIndex(where: { $0.id == payrollRecordID }),
           let updatedPayrollRecord {
            let oldEntry = ledgerEntries[ledgerIndex]
            ledgerEntries[ledgerIndex] = SimulationLedgerEntry(
                id: oldEntry.id,
                occurredAt: oldEntry.occurredAt,
                category: oldEntry.category,
                description: "\(correctedMachinist.displayName) · \(updatedPayrollRecord.details)",
                amount: oldEntry.amount,
                nature: oldEntry.nature,
                cashDeltaEuro: oldEntry.cashDeltaEuro,
                depotID: oldEntry.depotID
            )
        }

        let updatedLedgerDescription = ledgerEntries.first(where: { $0.id == payrollRecordID })?.description
        var invoices = activeSession.invoices ?? []
        for index in invoices.indices {
            let invoice = invoices[index]
            let lineItems = invoice.lineItems.map { item in
                guard item.ledgerEntryID == payrollRecordID,
                      let description = updatedLedgerDescription,
                      description != item.description else { return item }
                return SimulationInvoiceLineItem(
                    ledgerEntryID: item.ledgerEntryID,
                    category: item.category,
                    description: description,
                    amountEuro: item.amountEuro
                )
            }
            invoices[index] = SimulationInvoice(
                id: invoice.id,
                title: invoice.title,
                counterparty: invoice.counterparty,
                direction: invoice.direction,
                issuedAt: invoice.issuedAt,
                dueAt: invoice.dueAt,
                lineItems: lineItems,
                paidAt: invoice.paidAt
            )
        }

        let correction = MachinistAssignmentCorrection(
            id: UUID().uuidString,
            dutyBlockID: dutyBlockID,
            previousMachinistID: previousMachinist.id,
            correctedMachinistID: correctedMachinist.id,
            recordedAt: activeSession.simulatedAt,
            reason: savedReason
        )
        activeSession.machinistServiceAssignments = assignments
        activeSession.machinistDutyBlocks = dutyBlocks
        activeSession.machinistBreaks = breaks
        activeSession.machinistPayrollRecords = payrollRecords
        activeSession.ledgerEntries = ledgerEntries
        activeSession.invoices = invoices
        activeSession.machinistAssignmentCorrections = (activeSession.machinistAssignmentCorrections ?? []) + [correction]
        session = activeSession
        save()
    }

    func availableMachinistReliefCandidates(forVehicleID vehicleID: String) -> [Machinist] {
        guard let session,
              session.incidentAwaitingRepairResponse == nil,
              let bus = session.ownedBuses?.first(where: { $0.id == vehicleID }),
              bus.status == .inService,
              bus.activeMovementLeg == nil,
              bus.currentStopID != nil,
              let tripID = bus.currentTripID,
              let assignment = session.machinistServiceAssignments?.last(where: {
                  $0.vehicleID == vehicleID
                      && $0.tripID == tripID
                      && $0.actualEndAt == nil
                      && $0.routeID != "RETOUR-DEPOT"
              }),
              !(session.plannedMachinistReliefs ?? []).contains(where: {
                  $0.outgoingAssignmentID == assignment.id
              }),
              assignment.plannedStartAt <= session.simulatedAt,
              session.simulatedAt < assignment.plannedEndAt else { return [] }
        return availableMachinists(
            forVehicleID: vehicleID,
            serviceStartAt: session.simulatedAt,
            serviceEndAt: assignment.plannedEndAt
        ).filter { $0.id != assignment.machinistID }
    }

    func upcomingMachinistReliefStops(forVehicleID vehicleID: String) -> [MachinistReliefStop] {
        guard let session,
              session.incidentAwaitingRepairResponse == nil,
              let bus = session.ownedBuses?.first(where: { $0.id == vehicleID }),
              bus.status == .inService,
              let tripID = bus.currentTripID,
              let assignment = session.machinistServiceAssignments?.last(where: {
                  $0.vehicleID == vehicleID
                      && $0.tripID == tripID
                      && $0.actualEndAt == nil
                      && $0.routeID != "RETOUR-DEPOT"
                      && $0.plannedStartAt <= session.simulatedAt
                      && session.simulatedAt < $0.plannedEndAt
              }),
              !(session.plannedMachinistReliefs ?? []).contains(where: {
                  $0.outgoingAssignmentID == assignment.id
              }) else { return [] }

        return session.pendingEvents.compactMap { event in
            guard event.simulatedAt > session.simulatedAt,
                  event.simulatedAt < assignment.plannedEndAt,
                  case let .busAtStop(eventTripID, eventVehicleID, stopID, stopName, stopSequence, latitude, longitude) = event.kind,
                  eventTripID == tripID,
                  eventVehicleID == vehicleID else { return nil }
            return MachinistReliefStop(
                eventSequence: event.sequence,
                stopID: stopID,
                stopName: stopName,
                stopSequence: stopSequence,
                scheduledAt: event.simulatedAt,
                coordinate: BusMovementCoordinate(latitude: latitude, longitude: longitude)
            )
        }.sorted { $0.scheduledAt == $1.scheduledAt ? $0.stopSequence < $1.stopSequence : $0.scheduledAt < $1.scheduledAt }
    }

    func machinistTransferRequest(
        machinistID: String,
        stopEventSequence: UInt64
    ) -> MachinistTransferRequest? {
        guard let session,
              let machinist = session.machinists?.first(where: { $0.id == machinistID }),
              let stopEvent = session.pendingEvents.first(where: { $0.sequence == stopEventSequence }),
              case let .busAtStop(_, vehicleID, stopID, stopName, stopSequence, latitude, longitude) = stopEvent.kind,
              let stop = upcomingMachinistReliefStops(forVehicleID: vehicleID)
                .first(where: { $0.eventSequence == stopEventSequence }),
              stop.stopID == stopID,
              stop.stopName == stopName,
              stop.stopSequence == stopSequence,
              latitude.isFinite,
              longitude.isFinite else { return nil }

        let depotID = machinist.depotID ?? session.effectiveActiveDepotID
        guard let depot = DepotCareerScope.depotReference(for: depotID) else { return nil }
        let assignments = (session.machinistServiceAssignments ?? []).filter {
            $0.machinistID == machinistID
                && ($0.actualEndAt ?? $0.plannedEndAt) <= stop.scheduledAt
        }
        let previousAssignment = assignments.max {
            ($0.actualEndAt ?? $0.plannedEndAt) < ($1.actualEndAt ?? $1.plannedEndAt)
        }
        let earliestDepartureAt = max(
            session.simulatedAt,
            previousAssignment?.actualEndAt ?? previousAssignment?.plannedEndAt ?? session.simulatedAt
        )

        if let previousAssignment, previousAssignment.routeID != "RETOUR-DEPOT" {
            let endAt = previousAssignment.actualEndAt ?? previousAssignment.plannedEndAt
            let sourceStops = (session.eventHistory + session.pendingEvents).compactMap { event -> (Date, String, BusMovementCoordinate)? in
                guard event.simulatedAt <= endAt else { return nil }
                switch event.kind {
                case let .busAtStop(tripID, vehicleID, _, sourceStopName, _, sourceLatitude, sourceLongitude)
                    where tripID == previousAssignment.tripID && vehicleID == previousAssignment.vehicleID:
                    return (event.simulatedAt, "\(sourceStopName) (dernier arrêt connu)", BusMovementCoordinate(latitude: sourceLatitude, longitude: sourceLongitude))
                case let .busServiceCompleted(tripID, vehicleID, _, sourceStopName, sourceLatitude, sourceLongitude)
                    where tripID == previousAssignment.tripID && vehicleID == previousAssignment.vehicleID:
                    return (event.simulatedAt, "\(sourceStopName) (terminus)", BusMovementCoordinate(latitude: sourceLatitude, longitude: sourceLongitude))
                case let .busServiceCompletedAtClosedStop(tripID, vehicleID, _, _, sourceStopName, sourceLatitude, sourceLongitude, _)
                    where tripID == previousAssignment.tripID && vehicleID == previousAssignment.vehicleID:
                    return (event.simulatedAt, "\(sourceStopName) (terminus)", BusMovementCoordinate(latitude: sourceLatitude, longitude: sourceLongitude))
                case let .busServiceCompletedAtClosedStopWithPassengerRedirect(tripID, vehicleID, _, _, sourceStopName, sourceLatitude, sourceLongitude, _, _, _)
                    where tripID == previousAssignment.tripID && vehicleID == previousAssignment.vehicleID:
                    return (event.simulatedAt, "\(sourceStopName) (terminus)", BusMovementCoordinate(latitude: sourceLatitude, longitude: sourceLongitude))
                default:
                    return nil
                }
            }
            guard let lastStop = sourceStops.max(by: { $0.0 < $1.0 }) else { return nil }
            return MachinistTransferRequest(
                machinistID: machinistID,
                originName: lastStop.1,
                originAddress: nil,
                originCoordinate: lastStop.2,
                earliestDepartureAt: earliestDepartureAt,
                stop: stop
            )
        }

        return MachinistTransferRequest(
            machinistID: machinistID,
            originName: depot.name,
            originAddress: depot.address,
            originCoordinate: nil,
            earliestDepartureAt: earliestDepartureAt,
            stop: stop
        )
    }

    func availableMachinistPlannedReliefCandidates(
        forVehicleID vehicleID: String,
        stopEventSequence: UInt64
    ) -> [Machinist] {
        guard let session,
              let stop = session.pendingEvents.first(where: { $0.sequence == stopEventSequence }),
              let tripID = session.ownedBuses?.first(where: { $0.id == vehicleID })?.currentTripID,
              case let .busAtStop(eventTripID, eventVehicleID, _, _, _, _, _) = stop.kind,
              eventTripID == tripID,
              eventVehicleID == vehicleID,
              let assignment = session.machinistServiceAssignments?.last(where: {
                  $0.vehicleID == vehicleID
                      && $0.tripID == tripID
                      && $0.actualEndAt == nil
                      && $0.plannedStartAt <= session.simulatedAt
                      && session.simulatedAt < $0.plannedEndAt
                      && stop.simulatedAt < $0.plannedEndAt
              }) else { return [] }
        return availableMachinists(
            forVehicleID: vehicleID,
            serviceStartAt: stop.simulatedAt,
            serviceEndAt: assignment.plannedEndAt
        ).filter { $0.id != assignment.machinistID }
    }

    func scheduleMachinistRelief(
        vehicleID: String,
        incomingMachinistID: String,
        stopEventSequence: UInt64,
        transferPlan: MachinistTransferPlan
    ) throws {
        if isRunning { advanceFromRealtime() }
        guard var activeSession = session,
              activeSession.incidentAwaitingRepairResponse == nil,
              let bus = activeSession.ownedBuses?.first(where: { $0.id == vehicleID }),
              bus.status == .inService,
              let tripID = bus.currentTripID,
              let assignment = activeSession.machinistServiceAssignments?.last(where: {
                  $0.vehicleID == vehicleID
                      && $0.tripID == tripID
                      && $0.actualEndAt == nil
                      && $0.routeID != "RETOUR-DEPOT"
                      && $0.plannedStartAt <= activeSession.simulatedAt
                      && activeSession.simulatedAt < $0.plannedEndAt
              }),
              !(activeSession.plannedMachinistReliefs ?? []).contains(where: {
                  $0.outgoingAssignmentID == assignment.id
              }),
              let stopEvent = activeSession.pendingEvents.first(where: { $0.sequence == stopEventSequence }),
              stopEvent.simulatedAt > activeSession.simulatedAt,
              stopEvent.simulatedAt < assignment.plannedEndAt,
              case let .busAtStop(stopTripID, stopVehicleID, stopID, _, stopSequence, _, _) = stopEvent.kind,
              stopTripID == tripID,
              stopVehicleID == vehicleID else {
            throw SimulationEngineError.invalidMachinistRelief
        }
        guard let incomingMachinist = activeSession.machinists?.first(where: { $0.id == incomingMachinistID }) else {
            throw SimulationEngineError.unknownMachinist
        }
        guard incomingMachinistID != assignment.machinistID,
              availableMachinistPlannedReliefCandidates(
                  forVehicleID: vehicleID,
                  stopEventSequence: stopEventSequence
              ).contains(where: { $0.id == incomingMachinistID }) else {
            throw SimulationEngineError.machinistUnavailable
        }
        guard transferPlan.machinistID == incomingMachinistID,
              transferPlan.stopEventSequence == stopEventSequence,
              transferPlan.stopID == stopID,
              transferPlan.departureAt >= activeSession.simulatedAt,
              transferPlan.expectedTravelSeconds.isFinite,
              transferPlan.expectedTravelSeconds >= 0,
              abs(transferPlan.expectedArrivalAt.timeIntervalSince(transferPlan.departureAt)
                  - transferPlan.expectedTravelSeconds) < 1,
              transferPlan.expectedArrivalAt <= stopEvent.simulatedAt else {
            throw SimulationEngineError.machinistTransferUnavailable
        }
        let assignments = activeSession.machinistServiceAssignments ?? []
        let dutyBlocks = activeSession.machinistDutyBlocks ?? []
        guard let blockPlan = Self.machinistDutyBlockAssignmentPlan(
            incomingMachinistID,
            from: transferPlan.departureAt,
            to: assignment.plannedEndAt,
            assignments: assignments,
            dutyBlocks: dutyBlocks,
            breaks: activeSession.machinistBreaks ?? [],
            absences: activeSession.machinistAbsences ?? [],
            trainings: activeSession.machinistTrainings ?? [],
            allowReopeningSettledBlocks: true
        ) else {
            throw SimulationEngineError.machinistUnavailable
        }

        let incomingDutyBlockID: String
        var updatedDutyBlocks = activeSession.machinistDutyBlocks ?? []
        if let joiningID = blockPlan.joiningDutyBlockID,
           let blockIndex = updatedDutyBlocks.firstIndex(where: { $0.id == joiningID }) {
            incomingDutyBlockID = joiningID
            Self.reopenAndExtendMachinistDutyBlock(
                &updatedDutyBlocks[blockIndex],
                from: transferPlan.departureAt,
                to: assignment.plannedEndAt
            )
        } else {
            incomingDutyBlockID = UUID().uuidString
            updatedDutyBlocks.append(MachinistDutyBlock(
                id: incomingDutyBlockID,
                machinistID: incomingMachinistID,
                plannedStartAt: transferPlan.departureAt,
                plannedEndAt: assignment.plannedEndAt
            ))
        }
        let incomingAssignmentID = "relief-\(UUID().uuidString)"
        let event = SimulationEvent(
            sequence: activeSession.nextEventSequence,
            simulatedAt: stopEvent.simulatedAt,
            kind: .machinistRelieved(
                tripID: tripID,
                vehicleID: vehicleID,
                routeID: assignment.routeID,
                outgoingMachinistName: activeSession.machinists?.first(where: { $0.id == assignment.machinistID })?.displayName ?? "Machiniste",
                incomingMachinistName: incomingMachinist.displayName,
                stopName: {
                    if case let .busAtStop(_, _, _, name, _, _, _) = stopEvent.kind { return name }
                    return "arrêt"
                }()
            )
        )
        activeSession.machinistDutyBlocks = updatedDutyBlocks
        var updatedAssignments = activeSession.machinistServiceAssignments ?? []
        updatedAssignments.append(MachinistServiceAssignment(
            id: incomingAssignmentID,
            machinistID: incomingMachinistID,
            dutyBlockID: incomingDutyBlockID,
            vehicleID: vehicleID,
            vehicleModelID: assignment.vehicleModelID ?? bus.modelID,
            tripID: tripID,
            routeID: assignment.routeID,
            serviceDateKey: assignment.serviceDateKey,
            plannedStartAt: transferPlan.departureAt,
            plannedEndAt: assignment.plannedEndAt
        ))
        activeSession.machinistServiceAssignments = updatedAssignments
        var plans = activeSession.plannedMachinistReliefs ?? []
        plans.append(MachinistReliefPlan(
            id: UUID().uuidString,
            eventSequence: event.sequence,
            outgoingAssignmentID: assignment.id,
            incomingAssignmentID: incomingAssignmentID,
            stopID: stopID,
            stopSequence: stopSequence,
            transferPlan: transferPlan
        ))
        activeSession.plannedMachinistReliefs = plans
        activeSession.pendingEvents.append(event)
        activeSession.nextEventSequence &+= 1
        activeSession.pendingEvents.sort(by: Self.eventOrder)
        session = activeSession
        save()
    }

    func cancelScheduledMachinistRelief(eventSequence: UInt64) throws {
        if isRunning { advanceFromRealtime() }
        guard var activeSession = session,
              let plan = activeSession.plannedMachinistReliefs?.first(where: {
                  $0.eventSequence == eventSequence && $0.cancelledAt == nil
              }),
              let event = activeSession.pendingEvents.first(where: { $0.sequence == eventSequence }),
              event.simulatedAt > activeSession.simulatedAt else {
            throw SimulationEngineError.invalidMachinistReliefCancellation
        }
        Self.cancelPlannedMachinistRelief(plan, at: activeSession.simulatedAt, in: &activeSession)
        activeSession.pendingEvents.removeAll { $0.sequence == eventSequence }
        Self.discardCancelledMachinistRelief(eventSequence: eventSequence, in: &activeSession)
        session = activeSession
        save()
    }

    func relieveMachinist(vehicleID: String, incomingMachinistID: String) throws {
        if isRunning { advanceFromRealtime() }
        guard var activeSession = session else { throw SimulationEngineError.marketUnavailable }
        guard activeSession.incidentAwaitingRepairResponse == nil else {
            throw SimulationEngineError.operationBlockedByIncident
        }
        guard
              let bus = activeSession.ownedBuses?.first(where: { $0.id == vehicleID }),
              bus.status == .inService,
              bus.activeMovementLeg == nil,
              bus.currentStopID != nil,
              let stopName = bus.currentStopName,
              let tripID = bus.currentTripID,
              let assignment = activeSession.machinistServiceAssignments?.last(where: {
                  $0.vehicleID == vehicleID
                      && $0.tripID == tripID
                      && $0.actualEndAt == nil
                      && $0.routeID != "RETOUR-DEPOT"
              }),
              assignment.plannedStartAt <= activeSession.simulatedAt,
              activeSession.simulatedAt < assignment.plannedEndAt else {
            throw SimulationEngineError.invalidMachinistRelief
        }
        guard let incomingMachinist = activeSession.machinists?.first(where: { $0.id == incomingMachinistID }) else {
            throw SimulationEngineError.unknownMachinist
        }
        guard incomingMachinistID != assignment.machinistID,
              (incomingMachinist.depotID ?? activeSession.depotID) == bus.depotID else {
            throw SimulationEngineError.machinistUnavailable
        }
        let vehicleClass = VehicleMarketCatalog.model(id: bus.modelID)?.vehicleClass ?? .standard
        guard incomingMachinist.qualification.canDrive(vehicleClass) else {
            throw SimulationEngineError.machinistNotQualified
        }
        let now = activeSession.simulatedAt
        let assignments = activeSession.machinistServiceAssignments ?? []
        let dutyBlocks = activeSession.machinistDutyBlocks ?? []
        guard let blockPlan = Self.machinistDutyBlockAssignmentPlan(
            incomingMachinistID,
            from: now,
            to: assignment.plannedEndAt,
            assignments: assignments,
            dutyBlocks: dutyBlocks,
            breaks: activeSession.machinistBreaks ?? [],
            absences: activeSession.machinistAbsences ?? [],
            trainings: activeSession.machinistTrainings ?? [],
            allowReopeningSettledBlocks: true
        ) else {
            throw SimulationEngineError.machinistUnavailable
        }

        let outgoingName = activeSession.machinists?.first(where: { $0.id == assignment.machinistID })?.displayName
            ?? "Machiniste"
        let reliefEvent = SimulationEvent(
            sequence: activeSession.nextEventSequence,
            simulatedAt: now,
            kind: .machinistRelieved(
                tripID: tripID,
                vehicleID: vehicleID,
                routeID: assignment.routeID,
                outgoingMachinistName: outgoingName,
                incomingMachinistName: incomingMachinist.displayName,
                stopName: stopName
            )
        )
        Self.finalizeMachinistService(for: reliefEvent, in: &activeSession)
        activeSession.eventHistory.append(reliefEvent)
        activeSession.nextEventSequence &+= 1

        var updatedDutyBlocks = activeSession.machinistDutyBlocks ?? []
        let incomingDutyBlockID: String
        if let joiningID = blockPlan.joiningDutyBlockID,
           let blockIndex = updatedDutyBlocks.firstIndex(where: { $0.id == joiningID }) {
            incomingDutyBlockID = joiningID
            Self.reopenAndExtendMachinistDutyBlock(
                &updatedDutyBlocks[blockIndex],
                from: now,
                to: assignment.plannedEndAt
            )
        } else {
            incomingDutyBlockID = UUID().uuidString
            updatedDutyBlocks.append(MachinistDutyBlock(
                id: incomingDutyBlockID,
                machinistID: incomingMachinistID,
                plannedStartAt: now,
                plannedEndAt: assignment.plannedEndAt
            ))
        }
        activeSession.machinistDutyBlocks = updatedDutyBlocks
        var updatedAssignments = activeSession.machinistServiceAssignments ?? []
        updatedAssignments.append(MachinistServiceAssignment(
            id: "relief-\(UUID().uuidString)",
            machinistID: incomingMachinistID,
            dutyBlockID: incomingDutyBlockID,
            vehicleID: vehicleID,
            vehicleModelID: assignment.vehicleModelID ?? bus.modelID,
            tripID: tripID,
            routeID: assignment.routeID,
            serviceDateKey: assignment.serviceDateKey,
            plannedStartAt: now,
            plannedEndAt: assignment.plannedEndAt
        ))
        activeSession.machinistServiceAssignments = updatedAssignments
        session = activeSession
        save()
    }

    func availableMachinistBreakWindows(for machinistID: String) -> [MachinistBreakWindow] {
        guard let session else { return [] }
        return Self.machinistBreakWindows(
            machinistID: machinistID,
            simulatedAt: session.simulatedAt,
            assignments: session.machinistServiceAssignments ?? [],
            dutyBlocks: session.machinistDutyBlocks ?? [],
            breaks: session.machinistBreaks ?? [],
            absences: session.machinistAbsences ?? [],
            trainings: session.machinistTrainings ?? []
        )
    }

    @discardableResult
    func takeGameLoan(principalEuro: Int, termMonths: Int) throws -> SimulationLoan {
        guard var activeSession = session,
              let cashBalance = activeSession.cashBalance,
              var ledgerEntries = activeSession.ledgerEntries else {
            throw SimulationEngineError.marketUnavailable
        }
        guard let loan = SimulationLoanRules.loan(
            id: UUID().uuidString,
            principalEuro: principalEuro,
            termMonths: termMonths,
            issuedAt: activeSession.simulatedAt
        ) else {
            throw SimulationEngineError.loanTermsUnavailable
        }

        let loans = activeSession.loans ?? []
        let outstandingDebt = loans.reduce(0) { $0 + $1.outstandingPrincipalEuro }
        guard outstandingDebt + principalEuro <= SimulationLoanRules.maximumOutstandingPrincipalEuro else {
            throw SimulationEngineError.loanLimitExceeded
        }

        ledgerEntries.append(SimulationLedgerEntry(
            id: "loan-draw-\(loan.id)",
            occurredAt: activeSession.simulatedAt,
            category: "Emprunt reçu",
            description: "Crédit de jeu · \(termMonths) échéances · taux annuel fixe \(SimulationLoanRules.annualInterestRateBasisPoints / 100) %",
            amount: principalEuro,
            nature: .financing
        ))

        var sequence = activeSession.nextEventSequence
        activeSession.eventHistory.append(SimulationEvent(
            sequence: sequence,
            simulatedAt: activeSession.simulatedAt,
            kind: .loanIssued(loanID: loan.id, principalEuro: principalEuro, termMonths: termMonths)
        ))
        sequence &+= 1
        for installment in loan.installments {
            activeSession.pendingEvents.append(SimulationEvent(
                sequence: sequence,
                simulatedAt: installment.dueAt,
                kind: .loanInstallmentDue(loanID: loan.id, installmentNumber: installment.number)
            ))
            sequence &+= 1
        }
        activeSession.pendingEvents.sort(by: Self.eventOrder)
        activeSession.nextEventSequence = sequence
        activeSession.loans = loans + [loan]
        activeSession.ledgerEntries = ledgerEntries
        activeSession.cashBalance = cashBalance + principalEuro
        session = activeSession
        save()
        return loan
    }

    func purchaseVehicle(offerID: String) throws {
        guard var activeSession = session,
              let cashBalance = activeSession.cashBalance,
              let marketOffers = activeSession.marketOffers,
              var ownedBuses = activeSession.ownedBuses,
              var purchasedQuantities = activeSession.purchasedOfferQuantities,
              var ledgerEntries = activeSession.ledgerEntries else {
            throw SimulationEngineError.marketUnavailable
        }
        guard let offer = marketOffers.first(where: { $0.id == offerID }),
              let model = VehicleMarketCatalog.model(id: offer.modelID) else {
            throw SimulationEngineError.unknownMarketOffer
        }
        guard activeSession.depotEnergyReadiness(for: model.energy.depotInfrastructure, depotID: activeSession.effectiveActiveDepotID).isReady else {
            throw SimulationEngineError.depotEnergyInfrastructureRequired(model.energy.depotInfrastructure)
        }
        if activeSession.energySimulationVersion != nil, model.energy == .electric {
            guard activeSession.installedChargingPointCount(for: activeSession.effectiveActiveDepotID) > 0 else {
                throw SimulationEngineError.electricChargingPointRequired
            }
        }
        let purchasedCount = purchasedQuantities[offer.id, default: 0]
        guard purchasedCount < offer.initialStock else { throw SimulationEngineError.exhaustedMarketOffer }
        guard cashBalance >= offer.askingPrice else {
            throw SimulationEngineError.insufficientCapital(required: offer.askingPrice, available: cashBalance)
        }

        let deliveryAt = activeSession.simulatedAt.addingTimeInterval(Double(offer.deliveryDays) * 24 * 60 * 60)
        let vehicleID = UUID().uuidString
        let highestAssignedFleetNumber = ownedBuses.compactMap { bus -> Int? in
            guard let value = bus.coquilleNumber?.split(separator: "-").last else { return nil }
            return Int(value)
        }.max() ?? ownedBuses.count
        let battery = activeSession.energySimulationVersion == nil ? nil : VehicleMarketCatalog.gameplayBatteryCapacity(for: model)
        ownedBuses.append(PurchasedBus(
            id: vehicleID,
            modelID: model.id,
            offerID: offer.id,
            depotID: activeSession.effectiveActiveDepotID,
            acquiredAt: activeSession.simulatedAt,
            modelYear: offer.vehicleYear,
            odometerKilometers: offer.odometerKilometers,
            conditionPercent: offer.conditionPercent,
            purchasePrice: offer.askingPrice,
            deliveryAt: deliveryAt,
            status: .inDelivery,
            coquilleNumber: String(format: "JEU-%03d", highestAssignedFleetNumber + 1),
            batteryCapacityKWh: battery?.kWh,
            batteryChargeKWh: battery?.kWh,
            batteryCapacityIsEstimated: battery?.isEstimated
        ))
        purchasedQuantities[offer.id] = purchasedCount + 1
        ledgerEntries.append(SimulationLedgerEntry(
            id: UUID().uuidString,
            occurredAt: activeSession.simulatedAt,
            category: "Achat de véhicule",
            description: "\(model.displayName) — offre \(offer.condition.title.lowercased())",
            amount: -offer.askingPrice,
            depotID: activeSession.effectiveActiveDepotID
        ))

        let deliveryEvent = SimulationEvent(
            sequence: activeSession.nextEventSequence,
            simulatedAt: deliveryAt,
            kind: .vehicleDelivered(vehicleID: vehicleID)
        )
        activeSession.nextEventSequence &+= 1
        activeSession.pendingEvents.append(deliveryEvent)
        activeSession.pendingEvents.sort(by: Self.eventOrder)
        activeSession.cashBalance = cashBalance - offer.askingPrice
        activeSession.ownedBuses = ownedBuses
        activeSession.purchasedOfferQuantities = purchasedQuantities
        activeSession.ledgerEntries = ledgerEntries
        session = activeSession
        save()
    }

    func sellVehicle(vehicleID: String, quotedValue: Int) throws {
        guard var activeSession = session,
              let cashBalance = activeSession.cashBalance,
              var ownedBuses = activeSession.ownedBuses,
              var ledgerEntries = activeSession.ledgerEntries else {
            throw SimulationEngineError.marketUnavailable
        }
        guard let vehicleIndex = ownedBuses.firstIndex(where: { $0.id == vehicleID }),
              ownedBuses[vehicleIndex].canBeSold else {
            throw SimulationEngineError.vehicleCannotBeSold
        }

        let bus = ownedBuses[vehicleIndex]
        let resaleValue = VehicleMarketCatalog.estimatedResaleValue(for: bus, at: activeSession.simulatedAt)
        guard resaleValue == quotedValue else { throw SimulationEngineError.vehicleSaleEstimateChanged }
        ownedBuses.remove(at: vehicleIndex)
        let modelName = VehicleMarketCatalog.model(id: bus.modelID)?.displayName ?? bus.modelID
        ledgerEntries.append(SimulationLedgerEntry(
            id: UUID().uuidString,
            occurredAt: activeSession.simulatedAt,
            category: "Revente de véhicule",
            description: "\(modelName) · estimation de jeu · \(bus.odometerKilometers.formatted()) km · état \(bus.conditionPercent) %",
            amount: resaleValue,
            depotID: bus.depotID
        ))
        activeSession.cashBalance = cashBalance + resaleValue
        activeSession.ownedBuses = ownedBuses
        activeSession.ledgerEntries = ledgerEntries
        session = activeSession
        save()
    }

    func scheduleFullRecharge(vehicleID: String) throws {
        if isRunning { advanceFromRealtime() }
        guard var activeSession = session,
              var buses = activeSession.ownedBuses,
              let index = buses.firstIndex(where: { $0.id == vehicleID }),
              let capacity = buses[index].batteryCapacityKWh,
              let charge = buses[index].batteryChargeKWh,
              buses[index].depotID == activeSession.effectiveActiveDepotID,
              buses[index].status == .atDepot,
              buses[index].currentTripID == nil,
              buses[index].rechargePlanID == nil,
              activeSession.energySimulationVersion != nil,
              activeSession.installedChargingPointCount(for: buses[index].depotID) > 0,
              activeSession.installedChargingPowerKilowatts(for: buses[index].depotID) > 0 else {
            throw SimulationEngineError.rechargeUnavailable
        }
        let pendingCount = activeSession.pendingRechargeVehicleIDs.filter { pendingVehicleID in
            buses.first(where: { $0.id == pendingVehicleID })?.depotID == buses[index].depotID
        }.count
        let chargingPointCount = activeSession.installedChargingPointCount(for: buses[index].depotID)
        guard pendingCount < chargingPointCount else {
            throw SimulationEngineError.rechargeUnavailable
        }
        let missing = max(0, capacity - charge)
        guard missing > 0 else { throw SimulationEngineError.rechargeUnavailable }
        let power = activeSession.installedChargingPowerKilowatts(for: buses[index].depotID) / Double(chargingPointCount)
        let completeAt = activeSession.simulatedAt.addingTimeInterval(missing / power * 3_600)
        let planID = UUID().uuidString
        buses[index].rechargePlanID = planID
        activeSession.ownedBuses = buses
        activeSession.pendingEvents.append(SimulationEvent(
            sequence: activeSession.nextEventSequence,
            simulatedAt: completeAt,
            kind: .batteryRechargeCompleted(planID: planID, vehicleID: vehicleID, chargeKWh: capacity)
        ))
        activeSession.nextEventSequence &+= 1
        activeSession.pendingEvents.sort(by: Self.eventOrder)
        session = activeSession
        save()
    }

    func projectedBatteryChargeKWh(for vehicleID: String) -> Double? {
        guard let activeSession = session,
              let bus = activeSession.ownedBuses?.first(where: { $0.id == vehicleID }),
              let capacity = bus.batteryCapacityKWh else { return nil }
        var projected = bus.batteryChargeKWh
        for event in activeSession.pendingEvents
            .filter({ $0.simulatedAt <= activeSession.simulatedAt })
            .sorted(by: Self.eventOrder) {
            guard case let .batteryRechargeCompleted(planID, eventVehicleID, charge) = event.kind,
                  eventVehicleID == vehicleID,
                  bus.rechargePlanID == planID else { continue }
            projected = min(capacity, max(0, charge))
        }
        return projected
    }

    func workshopPartQuantity(for part: VehicleWorkshopPart, modelID: String, depotID: String? = nil) -> Int {
        guard let session else { return 0 }
        let depotID = depotID ?? session.effectiveActiveDepotID
        let stock = session.workshopPartsStock ?? []
        let scopedStock = stock.filter { ($0.depotID ?? session.depotID) == depotID }
        let modelQuantity = scopedStock.first(where: { $0.part == part && $0.vehicleModelID == modelID })?.quantity ?? 0
        let legacyQuantity = scopedStock.first(where: { $0.part == part && $0.vehicleModelID == nil })?.quantity ?? 0
        return max(0, modelQuantity) + max(0, legacyQuantity)
    }

    func pendingWorkshopPartOrders(for part: VehicleWorkshopPart, modelID: String, depotID: String? = nil) -> [VehicleWorkshopPartOrder] {
        guard let session else { return [] }
        let depotID = depotID ?? session.effectiveActiveDepotID
        return (session.workshopPartOrders ?? [])
            .filter {
                $0.part == part && $0.pending && ($0.vehicleModelID == modelID || $0.vehicleModelID == nil)
                    && ($0.depotID ?? session.depotID) == depotID
            }
            .sorted { $0.deliveryAt < $1.deliveryAt }
    }

    func availableWorkshopPartOrderQuantity(for part: VehicleWorkshopPart, modelID: String, depotID: String? = nil) -> Int {
        pendingWorkshopPartOrders(for: part, modelID: modelID, depotID: depotID).reduce(0) { $0 + $1.unreservedQuantity }
    }

    func workshopPartDeliveryEstimate(for part: VehicleWorkshopPart, modelID: String, depotID: String? = nil) -> Date? {
        guard let session, workshopPartQuantity(for: part, modelID: modelID, depotID: depotID) == 0 else { return nil }
        if let pendingOrder = pendingWorkshopPartOrders(for: part, modelID: modelID, depotID: depotID).first(where: { $0.unreservedQuantity > 0 }) {
            return pendingOrder.deliveryAt
        }
        return session.simulatedAt.addingTimeInterval(part.gameDeliveryDuration)
    }

    func restockWorkshopParts(_ part: VehicleWorkshopPart, forModelID modelID: String, quantity: Int = 1, depotID: String? = nil) throws {
        if isRunning { advanceFromRealtime() }
        guard var activeSession = session,
              let cashBalance = activeSession.cashBalance,
              var ledgerEntries = activeSession.ledgerEntries else {
            throw SimulationEngineError.marketUnavailable
        }
        guard let model = VehicleMarketCatalog.model(id: modelID) else {
            throw SimulationEngineError.vehicleUnavailable
        }
        let targetDepotID = depotID ?? activeSession.effectiveActiveDepotID
        guard activeSession.effectiveManagedDepotIDs.contains(targetDepotID) else {
            throw SimulationEngineError.marketUnavailable
        }
        guard (1...100).contains(quantity) else {
            throw SimulationEngineError.invalidWorkshopPartQuantity
        }
        let cost = part.purchasePriceEuro * quantity
        guard cashBalance >= cost else {
            throw SimulationEngineError.insufficientCapital(required: cost, available: cashBalance)
        }

        let order = VehicleWorkshopPartOrder(
            id: UUID().uuidString,
            part: part,
            vehicleModelID: modelID,
            quantity: quantity,
            orderedAt: activeSession.simulatedAt,
            deliveryAt: activeSession.simulatedAt.addingTimeInterval(part.gameDeliveryDuration),
            depotID: targetDepotID
        )
        var orders = activeSession.workshopPartOrders ?? []
        orders.append(order)
        let eventSequence = activeSession.nextEventSequence
        activeSession.nextEventSequence &+= 1
        activeSession.pendingEvents.append(SimulationEvent(
            sequence: eventSequence,
            simulatedAt: order.deliveryAt,
            kind: .workshopPartsDelivered(orderID: order.id)
        ))
        activeSession.pendingEvents.sort(by: Self.eventOrder)
        ledgerEntries.append(SimulationLedgerEntry(
            id: UUID().uuidString,
            occurredAt: activeSession.simulatedAt,
            category: "Pièces d’atelier",
            description: "Commande · \(quantity) × \(part.title) pour \(model.displayName) · livraison prévue \(order.deliveryAt.formatted(date: .abbreviated, time: .shortened)) · délai de jeu",
            amount: -cost,
            nature: .operating,
            cashDeltaEuro: 0,
            depotID: targetDepotID
        ))
        activeSession.workshopPartOrders = orders
        activeSession.ledgerEntries = ledgerEntries
        session = activeSession
        save()
    }

    func purchaseWorkshopExpansion() throws {
        if isRunning { advanceFromRealtime() }
        guard var activeSession = session,
              let cashBalance = activeSession.cashBalance,
              var ledgerEntries = activeSession.ledgerEntries else {
            throw SimulationEngineError.marketUnavailable
        }
        let depotID = activeSession.effectiveActiveDepotID
        guard activeSession.effectiveWorkshopBayCount(for: depotID) < VehicleWorkshopRules.maximumRepairBayCount,
              activeSession.workshopExpansionCompletionDate(for: depotID) == nil else {
            throw SimulationEngineError.workshopExpansionUnavailable
        }
        guard cashBalance >= VehicleWorkshopRules.expansionCostEuro else {
            throw SimulationEngineError.insufficientCapital(
                required: VehicleWorkshopRules.expansionCostEuro,
                available: cashBalance
            )
        }

        let completionAt = activeSession.simulatedAt.addingTimeInterval(VehicleWorkshopRules.expansionConstructionDuration)
        ledgerEntries.append(SimulationLedgerEntry(
            id: "workshop-expansion-\(UUID().uuidString)",
            occurredAt: activeSession.simulatedAt,
            category: "Extension d’atelier",
            description: "Construction d’une deuxième baie · délai de jeu 7 jours",
            amount: -VehicleWorkshopRules.expansionCostEuro,
            depotID: depotID
        ))
        activeSession.cashBalance = cashBalance - VehicleWorkshopRules.expansionCostEuro
        var bayCounts = activeSession.workshopBayCountsByDepot ?? [:]
        bayCounts[depotID] = activeSession.effectiveWorkshopBayCount(for: depotID)
        activeSession.workshopBayCountsByDepot = bayCounts
        var expansionDates = activeSession.workshopExpansionCompletesAtByDepot ?? [:]
        expansionDates[depotID] = completionAt
        activeSession.workshopExpansionCompletesAtByDepot = expansionDates
        if depotID == activeSession.depotID {
            activeSession.workshopBayCount = activeSession.effectiveWorkshopBayCount(for: depotID)
            activeSession.workshopExpansionCompletesAt = completionAt
        }
        activeSession.pendingEvents.append(SimulationEvent(
            sequence: activeSession.nextEventSequence,
            simulatedAt: completionAt,
            kind: .workshopExpansionCompletedAtDepot(depotID: depotID)
        ))
        activeSession.nextEventSequence &+= 1
        activeSession.pendingEvents.sort(by: Self.eventOrder)
        activeSession.ledgerEntries = ledgerEntries
        session = activeSession
        save()
    }

    func scheduleDepotEnergyInfrastructureInstallation(_ infrastructure: DepotEnergyInfrastructureKind) throws {
        if isRunning { advanceFromRealtime() }
        guard var activeSession = session,
              let cashBalance = activeSession.cashBalance,
              var ledgerEntries = activeSession.ledgerEntries,
              let cost = infrastructure.installationCostEuro,
              infrastructure.canBeInstalledByPlayer else {
            throw SimulationEngineError.marketUnavailable
        }

        let depotID = activeSession.effectiveActiveDepotID
        let readiness = activeSession.depotEnergyReadiness(for: infrastructure, depotID: depotID)
        switch readiness {
        case .requiresInstallation, .legacyUnverified:
            break
        case .readyFromEvidence, .readyFromGameplayRule, .installedByPlayer, .underConstruction:
            guard infrastructure == .electricCharging, activeSession.energySimulationVersion != nil else {
                throw SimulationEngineError.depotEnergyInfrastructureUnavailable
            }
        }
        guard cashBalance >= cost else {
            throw SimulationEngineError.insufficientCapital(required: cost, available: cashBalance)
        }

        let projectID = UUID().uuidString
        let completesAt = activeSession.simulatedAt.addingTimeInterval(infrastructure.installationDuration)
        var projects = activeSession.depotEnergyInfrastructureProjects ?? []
        projects.append(DepotEnergyInfrastructureProject(
            id: projectID,
            infrastructure: infrastructure,
            startedAt: activeSession.simulatedAt,
            completesAt: completesAt,
            costEuro: cost,
            chargingPointCount: infrastructure == .electricCharging ? 1 : nil,
            chargingPowerKilowatts: infrastructure == .electricCharging ? 60 : nil,
            depotID: depotID
        ))
        let eventSequence = activeSession.nextEventSequence
        activeSession.nextEventSequence &+= 1
        activeSession.pendingEvents.append(SimulationEvent(
            sequence: eventSequence,
            simulatedAt: completesAt,
            kind: .depotEnergyInfrastructureCompleted(projectID: projectID, infrastructure: infrastructure)
        ))
        activeSession.pendingEvents.sort(by: Self.eventOrder)
        ledgerEntries.append(SimulationLedgerEntry(
            id: "depot-energy-infrastructure-\(projectID)",
            occurredAt: activeSession.simulatedAt,
            category: "Infrastructure énergétique",
            description: "Construction · \(infrastructure.title) · délai de jeu · \(infrastructure.installationEstimateNote)",
            amount: -cost,
            depotID: depotID
        ))
        activeSession.cashBalance = cashBalance - cost
        activeSession.depotEnergyInfrastructureProjects = projects
        activeSession.ledgerEntries = ledgerEntries
        session = activeSession
        save()
    }

    private static func consumeWorkshopPart(
        _ part: VehicleWorkshopPart,
        forModelID modelID: String,
        depotID: String,
        legacyDepotID: String,
        from stock: inout [VehicleWorkshopPartStock]
    ) throws {
        guard let index = stock.firstIndex(where: {
            $0.part == part && $0.vehicleModelID == modelID && ($0.depotID ?? legacyDepotID) == depotID && $0.quantity > 0
        }) ?? stock.firstIndex(where: {
            $0.part == part && $0.vehicleModelID == nil && ($0.depotID ?? legacyDepotID) == depotID && $0.quantity > 0
        }) else {
            throw SimulationEngineError.workshopPartUnavailable(part)
        }
        stock[index].quantity -= 1
    }

    func schedulePreventiveMaintenance(vehicleID: String) throws {
        guard var activeSession = session,
              let cashBalance = activeSession.cashBalance,
              var buses = activeSession.ownedBuses,
              var ledgerEntries = activeSession.ledgerEntries else {
            throw SimulationEngineError.marketUnavailable
        }
        guard let busIndex = buses.firstIndex(where: { $0.id == vehicleID }) else {
            throw SimulationEngineError.vehicleUnavailable
        }
        let bus = buses[busIndex]
        guard (bus.status == .atDepot || bus.status == .atStop), bus.reservedTripKey == nil else {
            throw SimulationEngineError.vehicleUnavailable
        }
        guard bus.conditionPercent < 100 else { throw SimulationEngineError.maintenanceNotRequired }
        let estimatedCost = VehicleMarketCatalog.preventiveMaintenanceCost(for: bus.conditionPercent)
        guard cashBalance >= estimatedCost else {
            throw SimulationEngineError.insufficientCapital(required: estimatedCost, available: cashBalance)
        }
        guard let model = VehicleMarketCatalog.model(id: bus.modelID) else {
            throw SimulationEngineError.vehicleUnavailable
        }

        var workshopPartsStock = activeSession.workshopPartsStock ?? []
        try Self.consumeWorkshopPart(
            .preventiveMaintenance,
            forModelID: bus.modelID,
            depotID: bus.depotID,
            legacyDepotID: activeSession.depotID,
            from: &workshopPartsStock
        )
        let maintenanceID = UUID().uuidString
        var maintenanceRecords = activeSession.vehicleMaintenanceRecords ?? []
        let workshopStartedAt: Date
        if bus.status == .atDepot {
            workshopStartedAt = Self.nextWorkshopStart(
                depotID: bus.depotID,
                earliestStart: activeSession.simulatedAt,
                duration: VehicleMarketCatalog.preventiveMaintenanceDuration,
                incidents: activeSession.vehicleIncidents ?? [],
                maintenanceRecords: maintenanceRecords,
                capacity: activeSession.effectiveWorkshopBayCount(for: bus.depotID),
                expansionCompletesAt: activeSession.workshopExpansionCompletionDate(for: bus.depotID),
                legacyDepotID: activeSession.depotID
            )
        } else {
            workshopStartedAt = activeSession.simulatedAt
        }
        let completionAt = workshopStartedAt.addingTimeInterval(VehicleMarketCatalog.preventiveMaintenanceDuration)
        maintenanceRecords.append(VehicleMaintenanceRecord(
            id: maintenanceID,
            vehicleID: vehicleID,
            vehicleModelName: model.displayName,
            scheduledAt: activeSession.simulatedAt,
            workshopStartedAt: workshopStartedAt,
            expectedCompletionAt: completionAt,
            costEuro: estimatedCost,
            restoredConditionPercent: 100,
            returnStatus: bus.status,
            resolvedAt: nil,
            depotID: bus.depotID
        ))
        buses[busIndex].status = workshopStartedAt > activeSession.simulatedAt ? .waitingForWorkshop : .inMaintenance
        buses[busIndex].currentTripID = nil
        buses[busIndex].activeMovementLeg = nil
        ledgerEntries.append(SimulationLedgerEntry(
            id: "maintenance-\(maintenanceID)",
            occurredAt: activeSession.simulatedAt,
            category: "Entretien préventif",
            description: "\(model.displayName) · restauration de l’état à 100 % · durée de jeu 4 h",
            amount: -estimatedCost,
            nature: .operating,
            cashDeltaEuro: 0,
            depotID: bus.depotID
        ))
        if workshopStartedAt > activeSession.simulatedAt {
            let workshopStartSequence = activeSession.nextEventSequence
            activeSession.nextEventSequence &+= 1
            activeSession.pendingEvents.append(SimulationEvent(
                sequence: workshopStartSequence,
                simulatedAt: workshopStartedAt,
                kind: .vehicleMaintenanceStarted(maintenanceID: maintenanceID)
            ))
        }
        let completionSequence = activeSession.nextEventSequence
        activeSession.nextEventSequence &+= 1
        activeSession.pendingEvents.append(SimulationEvent(
            sequence: completionSequence,
            simulatedAt: completionAt,
            kind: .vehicleMaintenanceCompleted(maintenanceID: maintenanceID)
        ))
        activeSession.pendingEvents.sort(by: Self.eventOrder)
        activeSession.ownedBuses = buses
        activeSession.ledgerEntries = ledgerEntries
        activeSession.vehicleMaintenanceRecords = maintenanceRecords
        activeSession.workshopPartsStock = workshopPartsStock
        session = activeSession
        save()
    }

    func scheduleVehicleRepair(
        incidentID: String,
        response: VehicleRepairResponse,
        towPlan: VehicleTowPlan? = nil
    ) throws {
        guard var activeSession = session,
              let cashBalance = activeSession.cashBalance,
              var incidents = activeSession.vehicleIncidents,
              var ledgerEntries = activeSession.ledgerEntries else {
            throw SimulationEngineError.marketUnavailable
        }
        guard let incidentIndex = incidents.firstIndex(where: { $0.id == incidentID && !$0.isResolved }) else {
            throw SimulationEngineError.incidentUnavailable
        }
        let incident = incidents[incidentIndex]
        guard !incident.requiresDiagnosis || incident.diagnosisCompletedAt != nil else {
            throw SimulationEngineError.incidentDiagnosisRequired
        }
        let alreadyScheduled = activeSession.pendingEvents.contains { event in
            guard case let .vehicleRepairCompleted(scheduledIncidentID) = event.kind else { return false }
            return scheduledIncidentID == incidentID
        }
        guard incident.repairResponse == nil, !alreadyScheduled else {
            throw SimulationEngineError.repairAlreadyPlanned
        }
        if response == .towToDepot {
            guard let towPlan, Self.isValid(towPlan, for: incident, in: activeSession) else {
                throw SimulationEngineError.invalidTowRoute
            }
        } else if towPlan != nil {
            throw SimulationEngineError.invalidTowRoute
        }
        guard let bus = activeSession.ownedBuses?.first(where: { $0.id == incident.vehicleID }),
              bus.status == .outOfService else {
            throw SimulationEngineError.vehicleUnavailable
        }

        var workshopPartsStock = activeSession.workshopPartsStock ?? []
        var workshopPartOrders = activeSession.workshopPartOrders ?? []
        let requiredPart = VehicleWorkshopPart.repairKit(for: incident.severity)
        let modelName = VehicleMarketCatalog.model(id: bus.modelID)?.displayName ?? bus.modelID
        let interventionCost = response.cost(for: incident.severity, towDistanceMeters: towPlan?.totalServiceDistanceMeters ?? 0)
        var partsCost = 0
        var partsAvailableAt = activeSession.simulatedAt
        if workshopPartsStock.contains(where: {
            $0.part == requiredPart && ($0.vehicleModelID == bus.modelID || $0.vehicleModelID == nil)
                && ($0.depotID ?? activeSession.depotID) == bus.depotID && $0.quantity > 0
        }) {
            try Self.consumeWorkshopPart(
                requiredPart,
                forModelID: bus.modelID,
                depotID: bus.depotID,
                legacyDepotID: activeSession.depotID,
                from: &workshopPartsStock
            )
        } else if let orderIndex = workshopPartOrders.firstIndex(where: {
            $0.part == requiredPart && $0.vehicleModelID == bus.modelID && ($0.depotID ?? activeSession.depotID) == bus.depotID && $0.pending && $0.unreservedQuantity > 0
        }) ?? workshopPartOrders.firstIndex(where: {
            $0.part == requiredPart && $0.vehicleModelID == nil && ($0.depotID ?? activeSession.depotID) == bus.depotID && $0.pending && $0.unreservedQuantity > 0
        }) {
            workshopPartOrders[orderIndex].reservedQuantity += 1
            partsAvailableAt = workshopPartOrders[orderIndex].deliveryAt
        } else {
            partsCost = requiredPart.purchasePriceEuro
            let orderID = UUID().uuidString
            let order = VehicleWorkshopPartOrder(
                id: orderID,
                part: requiredPart,
                vehicleModelID: bus.modelID,
                quantity: 1,
                orderedAt: activeSession.simulatedAt,
                deliveryAt: activeSession.simulatedAt.addingTimeInterval(requiredPart.gameDeliveryDuration),
                depotID: bus.depotID,
                reservedQuantity: 1
            )
            workshopPartOrders.append(order)
            partsAvailableAt = order.deliveryAt
            let deliverySequence = activeSession.nextEventSequence
            activeSession.nextEventSequence &+= 1
            activeSession.pendingEvents.append(SimulationEvent(
                sequence: deliverySequence,
                simulatedAt: order.deliveryAt,
                kind: .workshopPartsDelivered(orderID: order.id)
            ))
            ledgerEntries.append(SimulationLedgerEntry(
                id: "workshop-part-order-\(order.id)",
                occurredAt: activeSession.simulatedAt,
                category: "Pièces d’atelier",
                description: "Commande liée à l’incident · \(requiredPart.title) pour \(modelName) · livraison prévue \(order.deliveryAt.formatted(date: .abbreviated, time: .shortened))",
                amount: -partsCost,
                nature: .operating,
                cashDeltaEuro: 0,
                depotID: bus.depotID
            ))
        }
        let totalCost = interventionCost + partsCost
        guard cashBalance >= totalCost else {
            throw SimulationEngineError.insufficientCapital(required: totalCost, available: cashBalance)
        }
        let travelSeconds = towPlan?.expectedTravelSeconds ?? 0
        let workshopStartedAt: Date?
        let completionAt: Date
        if let towPlan {
            let arrivalAt = towPlan.expectedDepotArrivalAt
                ?? activeSession.simulatedAt.addingTimeInterval(travelSeconds)
            let startAt = Self.nextWorkshopStart(
                depotID: towPlan.depotID,
                earliestStart: max(arrivalAt, partsAvailableAt),
                duration: incident.severity.repairDuration,
                incidents: incidents,
                maintenanceRecords: activeSession.vehicleMaintenanceRecords ?? [],
                capacity: activeSession.effectiveWorkshopBayCount(for: towPlan.depotID),
                expansionCompletesAt: activeSession.workshopExpansionCompletionDate(for: towPlan.depotID),
                legacyDepotID: activeSession.depotID
            )
            workshopStartedAt = startAt
            completionAt = startAt.addingTimeInterval(incident.severity.repairDuration)
        } else {
            workshopStartedAt = nil
            completionAt = max(activeSession.simulatedAt, partsAvailableAt).addingTimeInterval(
                response.duration(for: incident.severity, towTravelSeconds: travelSeconds)
            )
        }
        let interventionDetails: String
        if let towPlan {
            let dispatchDistance = ((towPlan.dispatchRouteDistanceMeters ?? 0) / 1_000)
                .formatted(.number.precision(.fractionLength(1)))
            let towDistance = (towPlan.routeDistanceMeters / 1_000)
                .formatted(.number.precision(.fractionLength(1)))
            interventionDetails = " · équipe \(dispatchDistance) km jusqu’à la panne, bus \(towDistance) km vers \(towPlan.depotName)"
        } else {
            interventionDetails = ""
        }
        incidents[incidentIndex].repairResponse = response
        incidents[incidentIndex].repairCostEuro = totalCost
        incidents[incidentIndex].repairCompletedAt = completionAt
        incidents[incidentIndex].towPlan = towPlan
        incidents[incidentIndex].recoveryTeamArrivedAt = nil
        incidents[incidentIndex].busTowStartedAt = nil
        incidents[incidentIndex].depotArrivedAt = nil
        incidents[incidentIndex].towArrivedAt = nil
        incidents[incidentIndex].workshopStartedAt = workshopStartedAt
        ledgerEntries.append(SimulationLedgerEntry(
            id: "repair-\(incident.id)",
            occurredAt: activeSession.simulatedAt,
            category: "Réparation",
            description: "\(incident.vehicleModelName) · \(response.title.lowercased()) · panne à \(incident.stopName)\(interventionDetails)",
            amount: -interventionCost,
            nature: .operating,
            cashDeltaEuro: 0,
            depotID: bus.depotID
        ))
        if let towPlan,
           var buses = activeSession.ownedBuses,
           let busIndex = buses.firstIndex(where: { $0.id == incident.vehicleID }) {
            let teamArrivalAt = towPlan.expectedRecoveryTeamArrivalAt ?? activeSession.simulatedAt
            let busTowStartAt = towPlan.expectedBusTowStartAt ?? teamArrivalAt
            let depotArrivalAt = towPlan.expectedDepotArrivalAt
                ?? busTowStartAt.addingTimeInterval(towPlan.expectedTravelSeconds)
            buses[busIndex].status = .outOfService
            buses[busIndex].currentStopID = incident.stopID
            buses[busIndex].currentStopName = incident.stopName
            buses[busIndex].currentTripID = nil
            buses[busIndex].reservedTripKey = nil
            buses[busIndex].reservedUntil = nil
            buses[busIndex].activeMovementLeg = nil
            activeSession.ownedBuses = buses

            let teamArrivalSequence = activeSession.nextEventSequence
            activeSession.nextEventSequence &+= 1
            activeSession.pendingEvents.append(SimulationEvent(
                sequence: teamArrivalSequence,
                simulatedAt: teamArrivalAt,
                kind: .vehicleTowTeamArrived(incidentID: incidentID)
            ))
            let towStartSequence = activeSession.nextEventSequence
            activeSession.nextEventSequence &+= 1
            activeSession.pendingEvents.append(SimulationEvent(
                sequence: towStartSequence,
                simulatedAt: busTowStartAt,
                kind: .vehicleTowStarted(incidentID: incidentID)
            ))
            let arrivalSequence = activeSession.nextEventSequence
            activeSession.nextEventSequence &+= 1
            activeSession.pendingEvents.append(SimulationEvent(
                sequence: arrivalSequence,
                simulatedAt: depotArrivalAt,
                kind: .vehicleTowArrived(incidentID: incidentID)
            ))
            if let workshopStartedAt {
                let workshopStartSequence = activeSession.nextEventSequence
                activeSession.nextEventSequence &+= 1
                activeSession.pendingEvents.append(SimulationEvent(
                    sequence: workshopStartSequence,
                    simulatedAt: workshopStartedAt,
                    kind: .vehicleWorkshopWorkStarted(incidentID: incidentID)
                ))
            }
        }
        let eventSequence = activeSession.nextEventSequence
        activeSession.nextEventSequence &+= 1
        activeSession.pendingEvents.append(SimulationEvent(
            sequence: eventSequence,
            simulatedAt: completionAt,
            kind: .vehicleRepairCompleted(incidentID: incidentID)
        ))
        activeSession.pendingEvents.sort(by: Self.eventOrder)
        activeSession.ledgerEntries = ledgerEntries
        activeSession.vehicleIncidents = incidents
        activeSession.workshopPartsStock = workshopPartsStock
        activeSession.workshopPartOrders = workshopPartOrders
        session = activeSession
        save()
    }

    @discardableResult
    func scheduleVehicleDiagnosis(incidentID: String) throws -> VehicleIncident {
        if isRunning { advanceFromRealtime() }
        guard var activeSession = session,
              let cashBalance = activeSession.cashBalance,
              var incidents = activeSession.vehicleIncidents,
              var ledgerEntries = activeSession.ledgerEntries else {
            throw SimulationEngineError.marketUnavailable
        }
        guard activeSession.incidentAwaitingRepairResponse?.id == incidentID,
              let incidentIndex = incidents.firstIndex(where: { $0.id == incidentID && !$0.isResolved }) else {
            throw SimulationEngineError.incidentUnavailable
        }
        var incident = incidents[incidentIndex]
        guard incident.requiresDiagnosis else {
            throw SimulationEngineError.incidentDiagnosisUnavailable
        }
        guard incident.diagnosisStartedAt == nil,
              incident.diagnosisCompletedAt == nil else {
            throw SimulationEngineError.incidentDiagnosisAlreadyStarted
        }
        guard cashBalance >= VehicleIncidentDiagnosisRules.costEuro else {
            throw SimulationEngineError.insufficientCapital(
                required: VehicleIncidentDiagnosisRules.costEuro,
                available: cashBalance
            )
        }

        let startsAt = activeSession.simulatedAt
        let completionAt = startsAt.addingTimeInterval(VehicleIncidentDiagnosisRules.duration)
        let findingIndex = Int(Self.deterministicDemandHash(
            seed: activeSession.randomSeed,
            key: "\(incident.id)|diagnostic"
        ) % UInt64(VehicleIncidentDiagnosticFinding.allCases.count))
        let finding = VehicleIncidentDiagnosticFinding.allCases[findingIndex]
        incident.diagnosisStartedAt = startsAt
        incident.diagnosisExpectedCompletionAt = completionAt
        incidents[incidentIndex] = incident
        ledgerEntries.append(SimulationLedgerEntry(
            id: "incident-diagnostic-\(incident.id)",
            occurredAt: startsAt,
            category: "Diagnostic de panne",
            description: "Diagnostic de jeu · \(incident.vehicleModelName) · ligne \(incident.routeID), \(incident.stopName)",
            amount: -VehicleIncidentDiagnosisRules.costEuro,
            nature: .operating,
            cashDeltaEuro: 0,
            depotID: activeSession.ownedBuses?.first(where: { $0.id == incident.vehicleID })?.depotID ?? activeSession.depotID
        ))
        let eventSequence = activeSession.nextEventSequence
        activeSession.nextEventSequence &+= 1
        activeSession.pendingEvents.append(SimulationEvent(
            sequence: eventSequence,
            simulatedAt: completionAt,
            kind: .vehicleDiagnosticCompleted(incidentID: incident.id, finding: finding)
        ))
        activeSession.pendingEvents.sort(by: Self.eventOrder)
        activeSession.ledgerEntries = ledgerEntries
        activeSession.vehicleIncidents = incidents
        session = activeSession
        save()
        guard let updatedIncident = session?.vehicleIncidents?.first(where: { $0.id == incidentID }) else {
            throw SimulationEngineError.incidentDiagnosisUnavailable
        }
        return updatedIncident
    }

    func workshopRepairEstimate(
        for plan: VehicleTowPlan,
        severity: VehicleIncidentSeverity,
        modelID: String
    ) -> (arrivalAt: Date, startsAt: Date, completesAt: Date)? {
        guard let session else { return nil }
        let arrivalAt = plan.expectedDepotArrivalAt
            ?? session.simulatedAt.addingTimeInterval(plan.expectedTravelSeconds)
        let repairPart = VehicleWorkshopPart.repairKit(for: severity)
        let partsAvailableAt = workshopPartDeliveryEstimate(for: repairPart, modelID: modelID, depotID: plan.depotID) ?? session.simulatedAt
        let startsAt = Self.nextWorkshopStart(
            depotID: plan.depotID,
            earliestStart: max(arrivalAt, partsAvailableAt),
            duration: severity.repairDuration,
            incidents: session.vehicleIncidents ?? [],
            maintenanceRecords: session.vehicleMaintenanceRecords ?? [],
            capacity: session.effectiveWorkshopBayCount(for: plan.depotID),
            expansionCompletesAt: session.workshopExpansionCompletionDate(for: plan.depotID),
            legacyDepotID: session.depotID
        )
        return (arrivalAt, startsAt, startsAt.addingTimeInterval(severity.repairDuration))
    }

    private static func nextWorkshopStart(
        depotID: String,
        earliestStart: Date,
        duration: TimeInterval,
        incidents: [VehicleIncident],
        maintenanceRecords: [VehicleMaintenanceRecord],
        capacity: Int,
        expansionCompletesAt: Date?,
        legacyDepotID: String
    ) -> Date {
        let occupiedIntervals = incidents.compactMap { incident -> (start: Date, end: Date)? in
            guard !incident.isResolved,
                  incident.repairResponse == .towToDepot,
                  let plan = incident.towPlan,
                  plan.depotID == depotID,
                  incident.repairCompletedAt > earliestStart else { return nil }
            let estimatedArrival = plan.expectedDepotArrivalAt
                ?? incident.occurredAt.addingTimeInterval(plan.expectedTravelSeconds)
            let start = incident.workshopStartedAt ?? incident.depotArrivedAt ?? incident.towArrivedAt ?? estimatedArrival
            guard start < incident.repairCompletedAt else { return nil }
            return (start, incident.repairCompletedAt)
        }
        let occupiedMaintenanceIntervals = maintenanceRecords.compactMap { record -> (start: Date, end: Date)? in
            guard !record.isResolved,
                  record.returnStatus == .atDepot,
                  (record.depotID ?? legacyDepotID) == depotID,
                  record.expectedCompletionAt > earliestStart else { return nil }
            let start = record.workshopStartedAt ?? record.scheduledAt
            guard start < record.expectedCompletionAt else { return nil }
            return (start, record.expectedCompletionAt)
        }
        let allOccupiedIntervals = (occupiedIntervals + occupiedMaintenanceIntervals).sorted { $0.start < $1.start }

        var candidate = earliestStart
        let currentCapacity = max(VehicleWorkshopRules.initialRepairBayCount, capacity)
        while true {
            let candidateEnd = candidate.addingTimeInterval(duration)
            let overlaps = allOccupiedIntervals.filter { $0.start < candidateEnd && $0.end > candidate }
            let availableCapacity = expansionCompletesAt.map {
                candidate >= $0 ? VehicleWorkshopRules.maximumRepairBayCount : currentCapacity
            } ?? currentCapacity
            guard overlaps.count >= availableCapacity else { return candidate }
            let nextJobEnd = overlaps.map(\.end).filter({ $0 > candidate }).min()
            let nextCapacityIncrease = expansionCompletesAt.flatMap { $0 > candidate ? $0 : nil }
            guard let nextFreeTime = [nextJobEnd, nextCapacityIncrease].compactMap({ $0 }).min() else { return candidate }
            candidate = nextFreeTime
        }
    }

    private static func isValid(_ plan: VehicleTowPlan, for incident: VehicleIncident, in session: SimulationSession) -> Bool {
        guard let bus = session.ownedBuses?.first(where: { $0.id == incident.vehicleID }),
              session.effectiveManagedDepotIDs.contains(bus.depotID),
              DepotCareerScope.supports(scenarioID: session.scenarioID, depotID: bus.depotID),
              plan.depotID == bus.depotID,
              let depot = DepotCareerScope.depotReference(for: plan.depotID),
              plan.depotName == depot.name,
              plan.recoveryTeamID == VehicleRecoveryRules.teamID(for: depot.id),
              plan.recoveryTeamName == VehicleRecoveryRules.teamName(for: depot.name),
              let dispatchStartsAt = plan.dispatchStartsAt,
              dispatchStartsAt == session.nextRecoveryTeamAvailableAt(depotID: depot.id),
              let dispatchDistance = plan.dispatchRouteDistanceMeters,
              dispatchDistance.isFinite,
              dispatchDistance > 0,
              let dispatchTravelSeconds = plan.dispatchExpectedTravelSeconds,
              dispatchTravelSeconds.isFinite,
              dispatchTravelSeconds > 0,
              let dispatchCoordinates = plan.dispatchRouteCoordinates,
              dispatchCoordinates.count >= 2,
              !plan.resolvedDepotAddress.isEmpty,
              !plan.routingSourceTitle.isEmpty,
              plan.routeDistanceMeters.isFinite,
              plan.routeDistanceMeters > 0,
              plan.expectedTravelSeconds.isFinite,
              plan.expectedTravelSeconds > 0,
              plan.calculatedAt <= Date.now,
              Date.now.timeIntervalSince(plan.calculatedAt) <= 10 * 60,
              plan.routeCoordinates.count >= 2,
              let first = plan.routeCoordinates.first,
              let last = plan.routeCoordinates.last else { return false }
        let coordinates = plan.routeCoordinates + dispatchCoordinates + [plan.destination]
        guard coordinates.allSatisfy({ coordinate in
            coordinate.latitude.isFinite
                && coordinate.longitude.isFinite
                && (-90...90).contains(coordinate.latitude)
                && (-180...180).contains(coordinate.longitude)
        }) else { return false }
        guard let dispatchFirst = dispatchCoordinates.first,
              let dispatchLast = dispatchCoordinates.last,
              dispatchStartsAt >= session.simulatedAt,
              abs(first.latitude - incident.latitude) < 0.0001,
              abs(first.longitude - incident.longitude) < 0.0001,
              abs(last.latitude - plan.destination.latitude) < 0.0001,
              abs(last.longitude - plan.destination.longitude) < 0.0001,
              abs(dispatchLast.latitude - incident.latitude) < 0.0001,
              abs(dispatchLast.longitude - incident.longitude) < 0.0001 else { return false }
        return abs(dispatchFirst.latitude - plan.destination.latitude) < 0.02
            && abs(dispatchFirst.longitude - plan.destination.longitude) < 0.02
    }

    private static func isValid(
        _ plan: VehicleDeadheadPlan,
        for bus: PurchasedBus,
        firstStop: ScheduledTripStopVisit,
        serviceStartAt: Date,
        session: SimulationSession
    ) -> Bool {
        guard session.effectiveManagedDepotIDs.contains(bus.depotID),
              DepotCareerScope.supports(scenarioID: session.scenarioID, depotID: bus.depotID),
              plan.depotID == bus.depotID,
              let depot = DepotCareerScope.depotReference(for: plan.depotID),
              plan.depotName == depot.name,
              plan.requestedDepotAddress == depot.address,
              plan.stopID == firstStop.stopID,
              plan.stopName == firstStop.stopName,
              !plan.resolvedDepotAddress.isEmpty,
              !plan.routingSourceTitle.isEmpty,
              plan.routeDistanceMeters.isFinite,
              plan.routeDistanceMeters > 0,
              plan.expectedTravelSeconds.isFinite,
              plan.expectedTravelSeconds > 0,
              plan.calculatedAt <= Date.now,
              Date.now.timeIntervalSince(plan.calculatedAt) <= 10 * 60,
              serviceStartAt.addingTimeInterval(-plan.expectedTravelSeconds) >= session.simulatedAt,
              plan.routeCoordinates.count >= 2,
              let first = plan.routeCoordinates.first,
              let last = plan.routeCoordinates.last else { return false }
        let coordinates = plan.routeCoordinates + [plan.origin, plan.destination]
        guard coordinates.allSatisfy({ coordinate in
            coordinate.latitude.isFinite
                && coordinate.longitude.isFinite
                && (-90...90).contains(coordinate.latitude)
                && (-180...180).contains(coordinate.longitude)
        }) else { return false }
        return abs(first.latitude - plan.origin.latitude) < 0.0001
            && abs(first.longitude - plan.origin.longitude) < 0.0001
            && abs(last.latitude - plan.destination.latitude) < 0.0001
            && abs(last.longitude - plan.destination.longitude) < 0.0001
            && abs(plan.destination.latitude - firstStop.latitude) < 0.0001
            && abs(plan.destination.longitude - firstStop.longitude) < 0.0001
    }

    private static func isValid(
        _ plan: VehicleDepotReturnPlan,
        for bus: PurchasedBus,
        in session: SimulationSession
    ) -> Bool {
        guard session.effectiveManagedDepotIDs.contains(bus.depotID),
              DepotCareerScope.supports(scenarioID: session.scenarioID, depotID: bus.depotID),
              plan.depotID == bus.depotID,
              bus.status == .atStop,
              bus.currentStopID != nil,
              bus.currentTripID == nil,
              bus.reservedTripKey == nil,
              bus.reservedUntil == nil,
              bus.activeMovementLeg == nil,
              plan.originBusID == bus.id,
              let depot = DepotCareerScope.depotReference(for: plan.depotID),
              plan.depotName == depot.name,
              plan.requestedDepotAddress == depot.address,
              !plan.resolvedDepotAddress.isEmpty,
              !plan.routingSourceTitle.isEmpty,
              plan.routeDistanceMeters.isFinite,
              plan.routeDistanceMeters > 0,
              plan.expectedTravelSeconds.isFinite,
              plan.expectedTravelSeconds > 0,
              plan.calculatedAt <= Date.now,
              Date.now.timeIntervalSince(plan.calculatedAt) <= 10 * 60,
              plan.routeCoordinates.count >= 2,
              let first = plan.routeCoordinates.first,
              let last = plan.routeCoordinates.last,
              let busLatitude = bus.latitude,
              let busLongitude = bus.longitude else { return false }
        let coordinates = plan.routeCoordinates + [plan.origin, plan.destination]
        guard coordinates.allSatisfy({ coordinate in
            coordinate.latitude.isFinite
                && coordinate.longitude.isFinite
                && (-90...90).contains(coordinate.latitude)
                && (-180...180).contains(coordinate.longitude)
        }) else { return false }
        return abs(plan.origin.latitude - busLatitude) < 0.0001
            && abs(plan.origin.longitude - busLongitude) < 0.0001
            && abs(first.latitude - plan.origin.latitude) < 0.0001
            && abs(first.longitude - plan.origin.longitude) < 0.0001
            && abs(last.latitude - plan.destination.latitude) < 0.0001
            && abs(last.longitude - plan.destination.longitude) < 0.0001
    }

    private static func coordinatesMatch(
        _ first: BusMovementCoordinate,
        _ second: BusMovementCoordinate
    ) -> Bool {
        abs(first.latitude - second.latitude) < 0.0001
            && abs(first.longitude - second.longitude) < 0.0001
    }

    func closeStop(
        stopID: String,
        stopName: String,
        routeIDs: [String],
        for duration: TimeInterval,
        replacementGuidesByRouteID: [String: StopClosureReplacementGuide] = [:],
        passengerInformationMessage: String? = nil
    ) throws {
        if isRunning { advanceFromRealtime() }
        guard var activeSession = session else { throw SimulationEngineError.marketUnavailable }
        guard activeSession.incidentAwaitingRepairResponse == nil else {
            throw SimulationEngineError.operationBlockedByIncident
        }
        guard duration.isFinite,
              duration > 0,
              let operatedRouteIDs = activeSession.operatedRouteIDs else {
            throw SimulationEngineError.stopClosureUnavailable
        }
        let impactedRouteIDs = Array(Set(routeIDs).intersection(operatedRouteIDs)).sorted()
        guard !impactedRouteIDs.isEmpty else { throw SimulationEngineError.stopClosureUnavailable }
        guard replacementGuidesByRouteID.isEmpty
                || (Set(replacementGuidesByRouteID.keys) == Set(impactedRouteIDs)
                    && replacementGuidesByRouteID.allSatisfy({ routeID, guide in
                        guide.routeID == routeID
                            && Self.validStopClosureReplacementGuide(guide, for: stopID)
                    })
                ) else {
            throw SimulationEngineError.invalidStopClosureReplacement
        }
        guard activeSession.activeStopClosure(stopID: stopID, routeIDs: impactedRouteIDs) == nil else {
            throw SimulationEngineError.stopAlreadyClosed
        }

        var redirectedWaitingCountByRouteID: [String: Int] = [:]
        if !replacementGuidesByRouteID.isEmpty {
            var queues = activeSession.passengerQueuesByRouteStopKey ?? [:]
            var queueUpdatedAt = activeSession.passengerQueueUpdatedAtByRouteStopKey ?? [:]
            for (routeID, guide) in replacementGuidesByRouteID {
                let closedStopQueueKey = Self.passengerQueueKey(routeID: routeID, stopID: stopID)
                let replacementQueueKey = Self.passengerQueueKey(
                    routeID: routeID,
                    stopID: guide.replacementStopID
                )
                let waitingCount = max(0, queues[closedStopQueueKey] ?? 0)
                redirectedWaitingCountByRouteID[routeID] = waitingCount
                guard waitingCount > 0 else { continue }

                queues[closedStopQueueKey] = 0
                queues[replacementQueueKey, default: 0] += waitingCount
                queueUpdatedAt[closedStopQueueKey] = activeSession.simulatedAt
                queueUpdatedAt[replacementQueueKey] = activeSession.simulatedAt
            }
            activeSession.passengerQueuesByRouteStopKey = queues
            activeSession.passengerQueueUpdatedAtByRouteStopKey = queueUpdatedAt
        }

        let closure = SimulatedStopClosure(
            id: UUID().uuidString,
            stopID: stopID,
            stopName: stopName,
            routeIDs: impactedRouteIDs,
            closedAt: activeSession.simulatedAt,
            scheduledOpenAt: activeSession.simulatedAt.addingTimeInterval(duration),
            replacementGuidesByRouteID: replacementGuidesByRouteID.isEmpty ? nil : replacementGuidesByRouteID,
            redirectedWaitingCountByRouteID: redirectedWaitingCountByRouteID.isEmpty ? nil : redirectedWaitingCountByRouteID,
            passengerInformationMessage: passengerInformationMessage
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .flatMap { $0.isEmpty ? nil : $0 }
        )
        activeSession.stopClosures = (activeSession.stopClosures ?? []) + [closure]
        activeSession.eventHistory.append(SimulationEvent(
            sequence: activeSession.nextEventSequence,
            simulatedAt: activeSession.simulatedAt,
            kind: .stopClosureStarted(closure)
        ))
        activeSession.nextEventSequence &+= 1
        let openingEventSequence = activeSession.nextEventSequence
        activeSession.nextEventSequence &+= 1
        activeSession.pendingEvents.append(SimulationEvent(
            sequence: openingEventSequence,
            simulatedAt: closure.scheduledOpenAt,
            kind: .stopClosureEnded(closureID: closure.id, stopID: stopID, stopName: stopName)
        ))
        activeSession.pendingEvents.sort(by: Self.eventOrder)
        session = activeSession
        save()
    }

    func suspendRoute(routeID: String, routeName: String, for duration: TimeInterval) throws {
        if isRunning { advanceFromRealtime() }
        guard var activeSession = session,
              activeSession.incidentAwaitingRepairResponse == nil,
              activeSession.allEffectiveOperatedRouteIDs.contains(routeID),
              duration.isFinite,
              (60...86_400).contains(duration) else {
            throw SimulationEngineError.routeClosureUnavailable
        }
        guard activeSession.activeRouteClosure(routeID: routeID, at: activeSession.simulatedAt) == nil else {
            throw SimulationEngineError.routeAlreadySuspended
        }

        let closure = SimulatedRouteClosure(
            id: UUID().uuidString,
            routeID: routeID,
            routeName: routeName,
            startsAt: activeSession.simulatedAt,
            scheduledEndAt: activeSession.simulatedAt.addingTimeInterval(duration)
        )
        let departureEvents = activeSession.pendingEvents.compactMap { event -> (SimulationEvent, MachinistServiceAssignment)? in
            guard case let .busDeparted(tripID, vehicleID, _, _, _, _) = event.kind,
                  event.simulatedAt >= closure.startsAt,
                  event.simulatedAt < closure.scheduledEndAt,
                  let assignment = activeSession.machinistServiceAssignments?.first(where: {
                      $0.tripID == tripID
                          && $0.vehicleID == vehicleID
                          && $0.routeID == routeID
                          && $0.actualEndAt == nil
                          && $0.plannedStartAt <= event.simulatedAt
                          && $0.plannedEndAt >= event.simulatedAt
                  }),
                  let bus = activeSession.ownedBuses?.first(where: { $0.id == vehicleID }),
                  bus.status == .assigned,
                  bus.reservedTripKey == assignment.id else { return nil }
            return (event, assignment)
        }

        var cancelledSequences = Set<UInt64>()
        var cancelledAssignments = Set<String>()
        var releasedVehicleIDs = Set<String>()
        var suspendedDepartureEvents: [SimulationEvent] = []
        for (departure, assignment) in departureEvents {
            cancelledAssignments.insert(assignment.id)
            releasedVehicleIDs.insert(assignment.vehicleID)
            for event in activeSession.pendingEvents where event.simulatedAt >= closure.startsAt {
                switch event.kind {
                case let .busDeparted(tripID, vehicleID, _, _, _, _),
                     let .busAtStop(tripID, vehicleID, _, _, _, _, _),
                     let .busServiceCompleted(tripID, vehicleID, _, _, _, _):
                    if tripID == assignment.tripID && vehicleID == assignment.vehicleID {
                        cancelledSequences.insert(event.sequence)
                    }
                case let .busDeadheadStarted(tripID, _, vehicleID, _, _, _, _, _),
                     let .busDeadheadArrived(tripID, _, vehicleID, _, _, _, _, _):
                    if tripID == assignment.tripID && vehicleID == assignment.vehicleID {
                        cancelledSequences.insert(event.sequence)
                    }
                case let .passengerDemand(demand):
                    if demand.tripID == assignment.tripID && demand.vehicleID == assignment.vehicleID {
                        cancelledSequences.insert(event.sequence)
                    }
                case let .passengersExchanged(exchange):
                    if exchange.tripID == assignment.tripID && exchange.vehicleID == assignment.vehicleID {
                        cancelledSequences.insert(event.sequence)
                    }
                case let .busMovementStarted(vehicleID, leg):
                    if vehicleID == assignment.vehicleID,
                       leg.startsAt >= departure.simulatedAt,
                       leg.startsAt <= assignment.plannedEndAt {
                        cancelledSequences.insert(event.sequence)
                    }
                default:
                    break
                }
            }
            suspendedDepartureEvents.append(SimulationEvent(
                sequence: departure.sequence,
                simulatedAt: departure.simulatedAt,
                kind: .routeServiceSuspended(
                    tripID: assignment.tripID,
                    routeID: routeID,
                    closureID: closure.id
                )
            ))
        }
        activeSession.pendingEvents.removeAll { cancelledSequences.contains($0.sequence) }
        activeSession.pendingEvents.append(contentsOf: suspendedDepartureEvents)

        if !cancelledAssignments.isEmpty {
            var assignments = activeSession.machinistServiceAssignments ?? []
            let cancelledDutyBlockIDs = Set(assignments.compactMap { assignment in
                cancelledAssignments.contains(assignment.id) ? assignment.dutyBlockID : nil
            })
            assignments.removeAll { cancelledAssignments.contains($0.id) }
            activeSession.machinistServiceAssignments = assignments
            activeSession.machinistDutyBlocks?.removeAll { block in
                cancelledDutyBlockIDs.contains(block.id)
                    && !assignments.contains(where: { $0.dutyBlockID == block.id })
            }
            if var dutyBlocks = activeSession.machinistDutyBlocks {
                for index in dutyBlocks.indices where cancelledDutyBlockIDs.contains(dutyBlocks[index].id) {
                    let remainingAssignments = assignments.filter { $0.dutyBlockID == dutyBlocks[index].id }
                    if let first = remainingAssignments.map(\.plannedStartAt).min(),
                       let last = remainingAssignments.map(\.plannedEndAt).max() {
                        dutyBlocks[index].plannedStartAt = first
                        dutyBlocks[index].plannedEndAt = last
                    }
                }
                activeSession.machinistDutyBlocks = dutyBlocks
            }
        }
        if var buses = activeSession.ownedBuses {
            for index in buses.indices where releasedVehicleIDs.contains(buses[index].id) {
                buses[index].status = buses[index].currentStopID == nil ? .atDepot : .atStop
                buses[index].currentTripID = nil
                buses[index].reservedTripKey = nil
                buses[index].reservedUntil = nil
                buses[index].activeMovementLeg = nil
            }
            activeSession.ownedBuses = buses
        }

        activeSession.routeClosures = (activeSession.routeClosures ?? []) + [closure]
        activeSession.eventHistory.append(SimulationEvent(
            sequence: activeSession.nextEventSequence,
            simulatedAt: activeSession.simulatedAt,
            kind: .routeClosureStarted(closure)
        ))
        activeSession.nextEventSequence &+= 1
        activeSession.pendingEvents.append(SimulationEvent(
            sequence: activeSession.nextEventSequence,
            simulatedAt: closure.scheduledEndAt,
            kind: .routeClosureEnded(
                closureID: closure.id,
                routeID: closure.routeID,
                routeName: closure.routeName
            )
        ))
        activeSession.nextEventSequence &+= 1
        activeSession.pendingEvents.sort(by: Self.eventOrder)
        session = activeSession
        save()
    }

    @discardableResult
    func scheduleRouteDetour(
        routeID: String,
        orderedRouteVisits: [ScheduledTripStopVisit],
        fromVisit: ScheduledTripStopVisit,
        toVisit: ScheduledTripStopVisit,
        startsAt: Date,
        endsAt: Date,
        replacementCoordinates: [BusMovementCoordinate],
        additionalTravelSeconds: TimeInterval,
        sourceObservation: PRIMTrafficObservation? = nil,
        passengerInformationMessage: String? = nil
    ) throws -> SimulatedRouteDetour {
        if isRunning { advanceFromRealtime() }
        let segmentDepartureAt = fromVisit.departureAt ?? fromVisit.scheduledAt
        guard var activeSession = session,
              activeSession.incidentAwaitingRepairResponse == nil,
              activeSession.allEffectiveOperatedRouteIDs.contains(routeID) else {
            throw SimulationEngineError.routeDetourUnavailable
        }
        guard !routeID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let fromIndex = orderedRouteVisits.firstIndex(of: fromVisit),
              fromIndex + 1 < orderedRouteVisits.count,
              orderedRouteVisits[fromIndex + 1] == toVisit,
              fromVisit.stopSequence < toVisit.stopSequence,
              segmentDepartureAt.timeIntervalSince1970.isFinite,
              segmentDepartureAt < toVisit.scheduledAt,
              startsAt.timeIntervalSince1970.isFinite,
              endsAt.timeIntervalSince1970.isFinite,
              startsAt >= activeSession.simulatedAt,
              endsAt > startsAt,
              additionalTravelSeconds.isFinite,
              additionalTravelSeconds >= 0,
              Self.validRouteDetourCoordinates(
                  replacementCoordinates,
                  from: fromVisit,
                  to: toVisit
              ) else {
            throw SimulationEngineError.invalidRouteDetour
        }
        if let sourceObservation = sourceObservation,
           let applicationEnd = sourceObservation.report.applicationEnd,
           applicationEnd < activeSession.simulatedAt {
            throw SimulationEngineError.invalidRouteDetour
        }

        let overlappingDetour = (activeSession.routeDetours ?? []).contains { detour in
            detour.endedAt == nil
                && detour.routeID == routeID
                && detour.fromStopID == fromVisit.stopID
                && detour.fromStopSequence == fromVisit.stopSequence
                && detour.toStopID == toVisit.stopID
                && detour.toStopSequence == toVisit.stopSequence
                && Self.periodsOverlap(startsAt, endsAt, detour.startsAt, detour.scheduledEndAt)
        }
        guard !overlappingDetour else { throw SimulationEngineError.routeDetourOverlap }

        let detour = SimulatedRouteDetour(
            id: UUID().uuidString,
            routeID: routeID,
            fromStopID: fromVisit.stopID,
            fromStopName: fromVisit.stopName,
            fromStopSequence: fromVisit.stopSequence,
            toStopID: toVisit.stopID,
            toStopName: toVisit.stopName,
            toStopSequence: toVisit.stopSequence,
            startsAt: startsAt,
            scheduledEndAt: endsAt,
            replacementCoordinates: replacementCoordinates,
            additionalTravelSeconds: additionalTravelSeconds,
            sourceObservation: sourceObservation,
            passengerInformationMessage: passengerInformationMessage
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .flatMap { $0.isEmpty ? nil : $0 }
        )
        activeSession.routeDetours = (activeSession.routeDetours ?? []) + [detour]
        if let sourceObservation,
           var alerts = activeSession.primTrafficAlerts,
           let alertIndex = alerts.firstIndex(where: {
               $0.id == PRIMTrafficAlert.identifier(
                   idfmLineID: sourceObservation.idfmLineID,
                   reportID: sourceObservation.report.id
               ) && $0.routeID == routeID
           }) {
            alerts[alertIndex].disposition = .detourPlanned
            alerts[alertIndex].plannedDetourID = detour.id
            activeSession.primTrafficAlerts = alerts
        }
        activeSession.eventHistory.append(SimulationEvent(
            sequence: activeSession.nextEventSequence,
            simulatedAt: activeSession.simulatedAt,
            kind: .routeDetourScheduled(RouteDetourEventDetails(detour), startsAt: startsAt)
        ))
        activeSession.nextEventSequence &+= 1
        activeSession.pendingEvents.append(SimulationEvent(
            sequence: activeSession.nextEventSequence,
            simulatedAt: startsAt,
            kind: .routeDetourStarted(RouteDetourEventDetails(detour))
        ))
        activeSession.nextEventSequence &+= 1
        activeSession.pendingEvents.append(SimulationEvent(
            sequence: activeSession.nextEventSequence,
            simulatedAt: endsAt,
            kind: .routeDetourEnded(RouteDetourEventDetails(detour))
        ))
        activeSession.nextEventSequence &+= 1
        guard Self.replanActiveDispatchedTrips(in: &activeSession) else {
            throw SimulationEngineError.routeDetourConflictsWithAssignment
        }
        activeSession.pendingEvents.sort(by: Self.eventOrder)
        session = activeSession
        save()
        return detour
    }

    @discardableResult
    func recordPRIMTrafficReports(_ observations: [PRIMTrafficObservation], routeID: String) -> Int {
        guard !observations.isEmpty,
              !routeID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              var activeSession = session,
              activeSession.allEffectiveOperatedRouteIDs.contains(routeID) else {
            return 0
        }

        var alerts = activeSession.primTrafficAlerts ?? []
        var addedCount = 0
        for observation in observations {
            let id = PRIMTrafficAlert.identifier(
                idfmLineID: observation.idfmLineID,
                reportID: observation.report.id
            )
            guard !LineReferenceMatcher.canonicalIdentifier(observation.idfmLineID).isEmpty,
                  !observation.report.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                continue
            }

            if let index = alerts.firstIndex(where: { $0.id == id }) {
                let previouslyObservedAt = alerts[index].observation.report.updatedAt
                let sourceHasNewerUpdate = observation.report.updatedAt.map { updatedAt in
                    previouslyObservedAt.map { updatedAt > $0 } ?? true
                } ?? false
                alerts[index].observation = observation
                alerts[index].lastSeenAt = observation.fetchedAt
                if alerts[index].disposition == .dismissed && sourceHasNewerUpdate {
                    alerts[index].disposition = .needsReview
                }
                if alerts[index].routeID != routeID {
                    alerts[index] = PRIMTrafficAlert(
                        routeID: routeID,
                        observation: observation,
                        firstSeenAt: alerts[index].firstSeenAt,
                        lastSeenAt: observation.fetchedAt,
                        disposition: alerts[index].disposition,
                        plannedDetourID: alerts[index].plannedDetourID
                    )
                }
            } else {
                alerts.append(PRIMTrafficAlert(
                    routeID: routeID,
                    observation: observation,
                    firstSeenAt: observation.fetchedAt,
                    lastSeenAt: observation.fetchedAt
                ))
                addedCount += 1
            }
        }

        activeSession.primTrafficAlerts = alerts
        session = activeSession
        save()
        return addedCount
    }

    func dismissPRIMTrafficAlert(id: String) {
        guard var activeSession = session,
              var alerts = activeSession.primTrafficAlerts,
              let index = alerts.firstIndex(where: { $0.id == id }) else {
            return
        }
        guard alerts[index].disposition != .dismissed else { return }
        alerts[index].disposition = .dismissed
        activeSession.primTrafficAlerts = alerts
        session = activeSession
        save()
    }

    @discardableResult
    func extendRouteDetour(id: String, to newEndAt: Date) throws -> SimulatedRouteDetour {
        if isRunning { advanceFromRealtime() }
        guard var activeSession = session,
              activeSession.incidentAwaitingRepairResponse == nil,
              var detours = activeSession.routeDetours,
              let detourIndex = detours.firstIndex(where: { $0.id == id }),
              detours[detourIndex].endedAt == nil else {
            throw SimulationEngineError.routeDetourUnavailable
        }

        let existingDetour = detours[detourIndex]
        guard newEndAt.timeIntervalSince1970.isFinite,
              newEndAt > existingDetour.scheduledEndAt,
              newEndAt > activeSession.simulatedAt else {
            throw SimulationEngineError.routeDetourUnavailable
        }
        let extensionOverlapsAnotherDetour = detours.enumerated().contains { index, other in
            index != detourIndex
                && other.endedAt == nil
                && other.routeID == existingDetour.routeID
                && other.fromStopID == existingDetour.fromStopID
                && other.fromStopSequence == existingDetour.fromStopSequence
                && other.toStopID == existingDetour.toStopID
                && other.toStopSequence == existingDetour.toStopSequence
                && Self.periodsOverlap(
                    existingDetour.startsAt,
                    newEndAt,
                    other.startsAt,
                    other.scheduledEndAt
                )
        }
        guard !extensionOverlapsAnotherDetour else { throw SimulationEngineError.routeDetourOverlap }

        var extendedDetour = existingDetour
        extendedDetour.scheduledEndAt = newEndAt
        detours[detourIndex] = extendedDetour
        activeSession.routeDetours = detours
        let updatedDetails = RouteDetourEventDetails(extendedDetour)
        let hadPendingStart = activeSession.pendingEvents.contains { event in
            guard case let .routeDetourStarted(details) = event.kind else { return false }
            return details.detourID == id
        }
        activeSession.pendingEvents.removeAll { event in
            switch event.kind {
            case let .routeDetourStarted(details), let .routeDetourEnded(details):
                return details.detourID == id
            default:
                return false
            }
        }
        if hadPendingStart {
            activeSession.pendingEvents.append(SimulationEvent(
                sequence: activeSession.nextEventSequence,
                simulatedAt: extendedDetour.startsAt,
                kind: .routeDetourStarted(updatedDetails)
            ))
            activeSession.nextEventSequence &+= 1
        }
        activeSession.pendingEvents.append(SimulationEvent(
            sequence: activeSession.nextEventSequence,
            simulatedAt: newEndAt,
            kind: .routeDetourEnded(updatedDetails)
        ))
        activeSession.nextEventSequence &+= 1
        activeSession.eventHistory.append(SimulationEvent(
            sequence: activeSession.nextEventSequence,
            simulatedAt: activeSession.simulatedAt,
            kind: .routeDetourExtended(updatedDetails)
        ))
        activeSession.nextEventSequence &+= 1
        guard Self.replanActiveDispatchedTrips(in: &activeSession) else {
            throw SimulationEngineError.routeDetourConflictsWithAssignment
        }
        activeSession.pendingEvents.sort(by: Self.eventOrder)
        session = activeSession
        save()
        return extendedDetour
    }

    func depotReturnStaffing(vehicleID: String, plan: VehicleDepotReturnPlan) -> MachinistDepotReturnStaffing? {
        guard let session,
              let returnPlan = Self.machinistDepotReturnAssignmentPlan(
                vehicleID: vehicleID,
                plan: plan,
                session: session
              ) else { return nil }
        return MachinistDepotReturnStaffing(
            machinist: returnPlan.machinist,
            estimatedLaborCostEuro: returnPlan.estimatedLaborCostEuro
        )
    }

    func scheduleReturnToDepot(vehicleID: String, plan: VehicleDepotReturnPlan) throws {
        if isRunning { advanceFromRealtime() }
        guard var activeSession = session,
              var buses = activeSession.ownedBuses,
              let busIndex = buses.firstIndex(where: { $0.id == vehicleID }) else {
            throw SimulationEngineError.marketUnavailable
        }
        guard activeSession.incidentAwaitingRepairResponse == nil else {
            throw SimulationEngineError.operationBlockedByIncident
        }
        let bus = buses[busIndex]
        guard Self.isValid(plan, for: bus, in: activeSession) else {
            throw SimulationEngineError.invalidDepotReturnRoute
        }
        guard let returnAssignmentPlan = Self.machinistDepotReturnAssignmentPlan(
            vehicleID: vehicleID,
            plan: plan,
            session: activeSession
        ) else {
            throw SimulationEngineError.machinistUnavailable
        }

        let startsAt = activeSession.simulatedAt
        let arrivesAt = startsAt.addingTimeInterval(plan.expectedTravelSeconds)
        let startSequence = activeSession.nextEventSequence
        activeSession.nextEventSequence &+= 1
        let returnTripID = "depot-return-\(vehicleID)-\(startSequence)"

        var dutyBlocks = activeSession.machinistDutyBlocks ?? []
        let dutyBlockID: String
        if let joiningID = returnAssignmentPlan.dutyBlockPlan.joiningDutyBlockID,
           let blockIndex = dutyBlocks.firstIndex(where: { $0.id == joiningID }) {
            dutyBlockID = joiningID
            Self.reopenAndExtendMachinistDutyBlock(
                &dutyBlocks[blockIndex],
                from: startsAt,
                to: arrivesAt
            )
        } else {
            dutyBlockID = UUID().uuidString
            dutyBlocks.append(MachinistDutyBlock(
                id: dutyBlockID,
                machinistID: returnAssignmentPlan.machinist.id,
                plannedStartAt: startsAt,
                plannedEndAt: arrivesAt
            ))
        }
        activeSession.machinistDutyBlocks = dutyBlocks
        var assignments = activeSession.machinistServiceAssignments ?? []
        assignments.append(MachinistServiceAssignment(
            id: returnTripID,
            machinistID: returnAssignmentPlan.machinist.id,
            dutyBlockID: dutyBlockID,
            vehicleID: vehicleID,
            vehicleModelID: bus.modelID,
            tripID: returnTripID,
            routeID: "RETOUR-DEPOT",
            serviceDateKey: returnAssignmentPlan.previousCourse.serviceDateKey,
            plannedStartAt: startsAt,
            plannedEndAt: arrivesAt
        ))
        activeSession.machinistServiceAssignments = assignments

        buses[busIndex].status = .returningToDepot
        buses[busIndex].currentStopID = nil
        buses[busIndex].currentStopName = bus.currentStopName
        buses[busIndex].currentTripID = nil
        buses[busIndex].reservedTripKey = nil
        buses[busIndex].reservedUntil = nil
        buses[busIndex].latitude = plan.origin.latitude
        buses[busIndex].longitude = plan.origin.longitude
        buses[busIndex].activeMovementLeg = ScheduledBusMovementLeg(
            startsAt: startsAt,
            endsAt: arrivesAt,
            coordinates: plan.routeCoordinates,
            depotReturnDestination: plan.destinationSnapshot
        )
        activeSession.ownedBuses = buses

        activeSession.pendingEvents.append(SimulationEvent(
            sequence: startSequence,
            simulatedAt: startsAt,
            kind: .busDepotReturnStarted(vehicleID: vehicleID, plan: plan)
        ))
        let arrivalSequence = activeSession.nextEventSequence
        activeSession.nextEventSequence &+= 1
        activeSession.pendingEvents.append(SimulationEvent(
            sequence: arrivalSequence,
            simulatedAt: arrivesAt,
            kind: .busDepotReturnArrivedWithMachinist(
                tripID: returnTripID,
                vehicleID: vehicleID,
                depotID: plan.depotID,
                depotName: plan.depotName,
                latitude: plan.destination.latitude,
                longitude: plan.destination.longitude,
                distanceMeters: plan.routeDistanceMeters
            )
        ))
        activeSession.pendingEvents.sort(by: Self.eventOrder)
        session = activeSession
        save()
    }

    @discardableResult
    func dispatchIncidentReplacement(
        incidentID: String,
        vehicleID: String,
        machinistID: String,
        stopVisits: [ScheduledTripStopVisit],
        deadheadPlan: VehicleDeadheadPlan? = nil
    ) throws -> VehicleIncident {
        guard let originalSession = session,
              let incident = originalSession.vehicleIncidents?.first(where: { $0.id == incidentID }),
              !incident.isResolved,
              !incident.requiresDiagnosis || incident.diagnosisCompletedAt != nil,
              incident.repairResponse == nil,
              incident.replacementVehicleID == nil,
              originalSession.incidentAwaitingRepairResponse?.id == incidentID,
              let serviceDateKey = incident.serviceDateKey,
              let stopSequence = incident.stopSequence,
              stopVisits.count >= 2,
              stopVisits[0].stopID == incident.stopID,
              stopVisits[0].stopSequence == stopSequence,
              stopVisits[0].scheduledAt >= originalSession.simulatedAt else {
            throw SimulationEngineError.replacementDispatchUnavailable
        }

        var dispatchSession = originalSession
        let eventSequence = dispatchSession.nextEventSequence
        dispatchSession.nextEventSequence &+= 1
        dispatchSession.pendingEvents.append(SimulationEvent(
            sequence: eventSequence,
            simulatedAt: stopVisits[0].scheduledAt,
            kind: .scheduledServiceDeparture(
                tripID: incident.tripID,
                routeID: incident.routeID,
                serviceDateKey: serviceDateKey
            )
        ))
        dispatchSession.pendingEvents.sort(by: Self.eventOrder)
        session = dispatchSession

        do {
            try dispatchScheduledDeparture(
                eventSequence: eventSequence,
                vehicleID: vehicleID,
                machinistID: machinistID,
                stopVisits: stopVisits,
                deadheadPlan: deadheadPlan,
                replacementIncidentID: incidentID
            )
        } catch {
            session = originalSession
            throw error
        }

        guard let updatedIncident = session?.vehicleIncidents?.first(where: { $0.id == incidentID }) else {
            throw SimulationEngineError.replacementDispatchUnavailable
        }
        return updatedIncident
    }

    func dispatchScheduledDeparture(
        eventSequence: UInt64,
        vehicleID: String,
        machinistID: String,
        stopVisits sourceStopVisits: [ScheduledTripStopVisit],
        deadheadPlan: VehicleDeadheadPlan? = nil,
        replacementIncidentID: String? = nil
    ) throws {
        guard var activeSession = session,
              var buses = activeSession.ownedBuses,
              let operatedRouteIDs = activeSession.operatedRouteIDs,
              let eventIndex = activeSession.pendingEvents.firstIndex(where: { $0.sequence == eventSequence }),
              let busIndex = buses.firstIndex(where: { $0.id == vehicleID }) else {
            throw SimulationEngineError.scheduledDepartureUnavailable
        }
        guard case let .scheduledServiceDeparture(tripID, routeID, serviceDateKey) = activeSession.pendingEvents[eventIndex].kind else {
            throw SimulationEngineError.scheduledDepartureUnavailable
        }
        let scheduledDeparture = activeSession.pendingEvents[eventIndex]
        guard operatedRouteIDs.contains(routeID) else { throw SimulationEngineError.scheduledDepartureUnavailable }
        guard activeSession.activeRouteClosure(routeID: routeID, at: scheduledDeparture.simulatedAt) == nil else {
            throw SimulationEngineError.routeClosureActive
        }
        guard !sourceStopVisits.isEmpty,
              sourceStopVisits.count >= 2,
              sourceStopVisits.allSatisfy({
                  $0.latitude.isFinite && $0.longitude.isFinite
                      && (-90...90).contains($0.latitude)
                      && (-180...180).contains($0.longitude)
              }),
              abs(sourceStopVisits[0].scheduledAt.timeIntervalSince(scheduledDeparture.simulatedAt)) <= 1 else {
            throw SimulationEngineError.invalidTripSchedule
        }
        for index in sourceStopVisits.indices.dropFirst() {
            guard sourceStopVisits[index].stopSequence > sourceStopVisits[index - 1].stopSequence,
                  sourceStopVisits[index].scheduledAt >= sourceStopVisits[index - 1].scheduledAt else {
                throw SimulationEngineError.invalidTripSchedule
            }
            if let departureAt = sourceStopVisits[index - 1].departureAt,
               departureAt > sourceStopVisits[index].scheduledAt {
                throw SimulationEngineError.invalidTripSchedule
            }
            if let coordinates = sourceStopVisits[index - 1].movementToNext,
               (coordinates.count < 2 || coordinates.contains(where: {
                   !$0.latitude.isFinite || !$0.longitude.isFinite
                       || !(-90...90).contains($0.latitude)
                       || !(-180...180).contains($0.longitude)
               })) {
                throw SimulationEngineError.invalidTripSchedule
            }
        }
        guard scheduledDeparture.simulatedAt >= activeSession.simulatedAt else {
            throw SimulationEngineError.scheduledDepartureUnavailable
        }

        let detourApplication = RouteDetourSchedulePlanner.applying(
            detours: (activeSession.routeDetours ?? []).filter { $0.routeID == routeID },
            to: sourceStopVisits
        )
        let stopVisits = detourApplication.visits

        var bus = buses[busIndex]
        guard (bus.status == .atDepot || bus.status == .atStop),
              bus.reservedTripKey == nil,
              bus.rechargePlanID == nil else {
            throw SimulationEngineError.vehicleUnavailable
        }
        if let model = VehicleMarketCatalog.model(id: bus.modelID) {
            let infrastructure = model.energy.depotInfrastructure
            guard activeSession.depotEnergyReadiness(for: infrastructure, depotID: bus.depotID).isReady else {
                throw SimulationEngineError.depotEnergyInfrastructureRequired(infrastructure)
            }
            if activeSession.energySimulationVersion != nil,
               model.energy == .electric,
               activeSession.installedChargingPointCount(for: bus.depotID) < 1 {
                throw SimulationEngineError.electricChargingPointRequired
            }
        }
        if bus.status == .atStop, bus.currentStopID != sourceStopVisits[0].stopID {
            throw SimulationEngineError.vehicleNotAtTripStart
        }
        if bus.status == .atDepot {
            guard let deadheadPlan,
                  Self.isValid(
                    deadheadPlan,
                    for: bus,
                    firstStop: stopVisits[0],
                    serviceStartAt: stopVisits[0].scheduledAt,
                    session: activeSession
                  ) else {
                throw SimulationEngineError.invalidDeadheadRoute
            }
        } else if deadheadPlan != nil {
            throw SimulationEngineError.invalidDeadheadRoute
        }

        if activeSession.energySimulationVersion != nil,
           let capacity = bus.batteryCapacityKWh,
           let charge = bus.batteryChargeKWh,
           let model = VehicleMarketCatalog.model(id: bus.modelID), model.energy == .electric {
            let serviceMeters = zip(stopVisits, stopVisits.dropFirst()).reduce(into: 0.0) { total, pair in
                if let coordinates = pair.0.movementToNext, coordinates.count >= 2 {
                    total += Self.pathDistance(coordinates)
                } else {
                    total += Self.pathDistance([
                        BusMovementCoordinate(latitude: pair.0.latitude, longitude: pair.0.longitude),
                        BusMovementCoordinate(latitude: pair.1.latitude, longitude: pair.1.longitude)
                    ])
                }
            }
            let deadheadMeters = bus.status == .atDepot ? (deadheadPlan?.routeDistanceMeters ?? 0) : 0
            let consumption = (serviceMeters + deadheadMeters) / 100_000
                * VehicleMarketCatalog.energyEstimate(for: model).quantityPer100Kilometers
            guard charge - consumption >= capacity * 0.15 else {
                throw SimulationEngineError.insufficientBatteryReserve
            }
        }

        guard let machinist = activeSession.machinists?.first(where: { $0.id == machinistID }) else {
            throw SimulationEngineError.unknownMachinist
        }
        guard (machinist.depotID ?? activeSession.depotID) == bus.depotID else {
            throw SimulationEngineError.machinistUnavailable
        }
        let vehicleClass = VehicleMarketCatalog.model(id: bus.modelID)?.vehicleClass ?? .standard
        guard machinist.qualification.canDrive(vehicleClass) else {
            throw SimulationEngineError.machinistNotQualified
        }
        let serviceStartAt = stopVisits[0].scheduledAt
        let serviceEndAt = stopVisits[stopVisits.count - 1].scheduledAt
        let dutyStartAt = deadheadPlan.map {
            serviceStartAt.addingTimeInterval(-$0.expectedTravelSeconds)
        } ?? serviceStartAt
        let machinistAssignments = activeSession.machinistServiceAssignments ?? []
        let machinistDutyPlan = Self.machinistDutyBlockAssignmentPlan(
            machinistID,
            from: dutyStartAt,
            to: serviceEndAt,
            assignments: machinistAssignments,
            dutyBlocks: activeSession.machinistDutyBlocks ?? [],
            breaks: activeSession.machinistBreaks ?? [],
            absences: activeSession.machinistAbsences ?? [],
            trainings: activeSession.machinistTrainings ?? [],
            allowReopeningSettledBlocks: true
        )
        guard let machinistDutyPlan else { throw SimulationEngineError.machinistUnavailable }

        let tripKey = replacementIncidentID.map {
            "replacement|\($0)|\(tripID)|\(routeID)|\(serviceDateKey)"
        } ?? "\(tripID)|\(routeID)|\(serviceDateKey)"
        let vehicleModel = VehicleMarketCatalog.model(id: bus.modelID)
        let passengerCapacity = vehicleModel.map(VehicleMarketCatalog.passengerCapacity(for:)) ?? 85
        let capacityIsEstimated = vehicleModel.map(VehicleMarketCatalog.usesEstimatedPassengerCapacity(for:)) ?? true
        let passengerDemands = Self.estimatedPassengerDemands(
            tripID: tripID,
            routeID: routeID,
            vehicleID: vehicleID,
            serviceDateKey: serviceDateKey,
            stopVisits: stopVisits,
            capacity: passengerCapacity,
            capacityIsEstimated: capacityIsEstimated,
            randomSeed: activeSession.randomSeed
        )
        bus.status = .assigned
        bus.reservedTripKey = tripKey
        bus.reservedUntil = stopVisits[stopVisits.count - 1].scheduledAt
        buses[busIndex] = bus
        activeSession.ownedBuses = buses
        var machinistDutyBlocks = activeSession.machinistDutyBlocks ?? []
        let dutyBlockID: String
        if let joiningDutyBlockID = machinistDutyPlan.joiningDutyBlockID,
           let dutyBlockIndex = machinistDutyBlocks.firstIndex(where: { $0.id == joiningDutyBlockID }) {
            dutyBlockID = joiningDutyBlockID
            Self.reopenAndExtendMachinistDutyBlock(
                &machinistDutyBlocks[dutyBlockIndex],
                from: dutyStartAt,
                to: serviceEndAt
            )
        } else {
            dutyBlockID = UUID().uuidString
            machinistDutyBlocks.append(MachinistDutyBlock(
                id: dutyBlockID,
                machinistID: machinist.id,
                plannedStartAt: dutyStartAt,
                plannedEndAt: serviceEndAt
            ))
        }
        activeSession.machinistDutyBlocks = machinistDutyBlocks
        var updatedMachinistAssignments = machinistAssignments
        updatedMachinistAssignments.append(MachinistServiceAssignment(
            id: tripKey,
            machinistID: machinist.id,
            dutyBlockID: dutyBlockID,
            vehicleID: bus.id,
            vehicleModelID: bus.modelID,
            tripID: tripID,
            routeID: routeID,
            serviceDateKey: serviceDateKey,
            plannedStartAt: dutyStartAt,
            plannedEndAt: serviceEndAt
        ))
        activeSession.machinistServiceAssignments = updatedMachinistAssignments
        activeSession.pendingEvents.remove(at: eventIndex)

        let firstStop = stopVisits[0]
        if let deadheadPlan {
            let deadheadStartsAt = serviceStartAt.addingTimeInterval(-deadheadPlan.expectedTravelSeconds)
            activeSession.pendingEvents.append(SimulationEvent(
                sequence: activeSession.nextEventSequence,
                simulatedAt: deadheadStartsAt,
                kind: .busDeadheadStarted(
                    tripID: tripID,
                    routeID: routeID,
                    vehicleID: vehicleID,
                    stopID: firstStop.stopID,
                    stopName: firstStop.stopName,
                    latitude: firstStop.latitude,
                    longitude: firstStop.longitude,
                    plan: deadheadPlan
                )
            ))
            activeSession.nextEventSequence &+= 1
            activeSession.pendingEvents.append(SimulationEvent(
                sequence: activeSession.nextEventSequence,
                simulatedAt: serviceStartAt,
                kind: .busDeadheadArrived(
                    tripID: tripID,
                    routeID: routeID,
                    vehicleID: vehicleID,
                    stopID: firstStop.stopID,
                    stopName: firstStop.stopName,
                    latitude: firstStop.latitude,
                    longitude: firstStop.longitude,
                    distanceMeters: deadheadPlan.routeDistanceMeters
                )
            ))
            activeSession.nextEventSequence &+= 1
        }
        let departureKind: SimulationEventKind
        if let replacementIncidentID {
            guard var incidents = activeSession.vehicleIncidents,
                  let incidentIndex = incidents.firstIndex(where: {
                      $0.id == replacementIncidentID && !$0.isResolved
                          && $0.repairResponse == nil && $0.replacementVehicleID == nil
                  }),
                  incidents[incidentIndex].tripID == tripID,
                  incidents[incidentIndex].routeID == routeID,
                  incidents[incidentIndex].serviceDateKey == serviceDateKey,
                  incidents[incidentIndex].stopID == firstStop.stopID,
                  incidents[incidentIndex].stopSequence == firstStop.stopSequence else {
                throw SimulationEngineError.replacementDispatchUnavailable
            }
            incidents[incidentIndex].replacementVehicleID = vehicleID
            incidents[incidentIndex].replacementVehicleModelName = vehicleModel?.displayName ?? bus.modelID
            incidents[incidentIndex].replacementMachinistID = machinistID
            incidents[incidentIndex].replacementServiceStartsAt = serviceStartAt
            incidents[incidentIndex].replacementDelaySeconds = max(0, serviceStartAt.timeIntervalSince(incidents[incidentIndex].occurredAt))
            activeSession.vehicleIncidents = incidents
            departureKind = .vehicleReplacementDeparted(
                incidentID: replacementIncidentID,
                tripID: tripID,
                vehicleID: vehicleID,
                stopID: firstStop.stopID,
                stopName: firstStop.stopName,
                latitude: firstStop.latitude,
                longitude: firstStop.longitude,
                delaySeconds: max(0, serviceStartAt.timeIntervalSince(incidents[incidentIndex].occurredAt))
            )
        } else {
            departureKind = .busDeparted(
                tripID: tripID,
                vehicleID: vehicleID,
                stopID: firstStop.stopID,
                stopName: firstStop.stopName,
                latitude: firstStop.latitude,
                longitude: firstStop.longitude
            )
        }
        let departureEvent = SimulationEvent(
            sequence: activeSession.nextEventSequence,
            simulatedAt: scheduledDeparture.simulatedAt,
            kind: departureKind
        )
        activeSession.nextEventSequence &+= 1
        activeSession.pendingEvents.append(departureEvent)

        var stopEventSequencesByStopSequence: [Int: UInt64] = [:]
        var demandEventSequencesByStopSequence: [Int: UInt64] = [:]
        var movementEventSequencesByFromStopSequence: [Int: UInt64] = [:]

        demandEventSequencesByStopSequence[firstStop.stopSequence] = activeSession.nextEventSequence
        activeSession.pendingEvents.append(SimulationEvent(
            sequence: activeSession.nextEventSequence,
            simulatedAt: passengerDemands[0].occurredAt,
            kind: .passengerDemand(passengerDemands[0])
        ))
        activeSession.nextEventSequence &+= 1

        if let firstLeg = Self.movementLeg(from: firstStop, to: stopVisits[1]) {
            movementEventSequencesByFromStopSequence[firstStop.stopSequence] = activeSession.nextEventSequence
            activeSession.pendingEvents.append(SimulationEvent(
                sequence: activeSession.nextEventSequence,
                simulatedAt: firstLeg.startsAt,
                kind: .busMovementStarted(vehicleID: vehicleID, leg: firstLeg)
            ))
            activeSession.nextEventSequence &+= 1
        }

        for index in stopVisits.indices.dropFirst() {
            let visit = stopVisits[index]
            stopEventSequencesByStopSequence[visit.stopSequence] = activeSession.nextEventSequence
            activeSession.pendingEvents.append(SimulationEvent(
                sequence: activeSession.nextEventSequence,
                simulatedAt: visit.scheduledAt,
                kind: .busAtStop(
                    tripID: tripID,
                    vehicleID: vehicleID,
                    stopID: visit.stopID,
                    stopName: visit.stopName,
                    stopSequence: visit.stopSequence,
                    latitude: visit.latitude,
                    longitude: visit.longitude
                )
            ))
            activeSession.nextEventSequence &+= 1

            let demand = passengerDemands[index]
            demandEventSequencesByStopSequence[visit.stopSequence] = activeSession.nextEventSequence
            activeSession.pendingEvents.append(SimulationEvent(
                sequence: activeSession.nextEventSequence,
                simulatedAt: demand.occurredAt,
                kind: .passengerDemand(demand)
            ))
            activeSession.nextEventSequence &+= 1

            if index < stopVisits.count - 1,
               let nextLeg = Self.movementLeg(from: visit, to: stopVisits[index + 1]) {
                movementEventSequencesByFromStopSequence[visit.stopSequence] = activeSession.nextEventSequence
                activeSession.pendingEvents.append(SimulationEvent(
                    sequence: activeSession.nextEventSequence,
                    simulatedAt: nextLeg.startsAt,
                    kind: .busMovementStarted(vehicleID: vehicleID, leg: nextLeg)
                ))
                activeSession.nextEventSequence &+= 1
            }
        }

        let lastStop = stopVisits[stopVisits.count - 1]
        let completionEventSequence = activeSession.nextEventSequence
        activeSession.pendingEvents.append(SimulationEvent(
            sequence: activeSession.nextEventSequence,
            simulatedAt: lastStop.scheduledAt,
            kind: .busServiceCompleted(
                tripID: tripID,
                vehicleID: vehicleID,
                stopID: lastStop.stopID,
                stopName: lastStop.stopName,
                latitude: lastStop.latitude,
                longitude: lastStop.longitude
            )
        ))
        activeSession.nextEventSequence &+= 1

        if let incident = Self.plannedVehicleIncident(
            bus: bus,
            model: vehicleModel,
            tripID: tripID,
            routeID: routeID,
            serviceDateKey: serviceDateKey,
            stopVisits: stopVisits,
            randomSeed: activeSession.randomSeed,
            frequency: activeSession.effectiveBreakdownFrequency
        ) {
            activeSession.pendingEvents.append(SimulationEvent(
                sequence: activeSession.nextEventSequence,
                simulatedAt: incident.occurredAt,
                kind: .vehicleBreakdown(incident)
            ))
            activeSession.nextEventSequence &+= 1
        }
        var routePlans = activeSession.dispatchedTripRoutePlans ?? []
        routePlans.removeAll { $0.tripKey == tripKey }
        routePlans.append(DispatchedTripRoutePlan(
            tripKey: tripKey,
            tripID: tripID,
            routeID: routeID,
            serviceDateKey: serviceDateKey,
            vehicleID: vehicleID,
            machinistID: machinistID,
            passengerCapacity: passengerCapacity,
            capacityIsEstimated: capacityIsEstimated,
            stopVisits: stopVisits,
            appliedDetourIDs: detourApplication.appliedDetourIDs,
            stopEventSequencesByStopSequence: stopEventSequencesByStopSequence,
            demandEventSequencesByStopSequence: demandEventSequencesByStopSequence,
            movementEventSequencesByFromStopSequence: movementEventSequencesByFromStopSequence,
            completionEventSequence: completionEventSequence
        ))
        activeSession.dispatchedTripRoutePlans = routePlans
        activeSession.pendingEvents.sort(by: Self.eventOrder)
        session = activeSession
        save()
    }

    @discardableResult
    func advanceToNextEvent() -> Bool {
        pause()
        guard var activeSession = session,
              let nextEvent = activeSession.pendingEvents.first(where: {
                  !Self.requiresRepairResponseBeforeProcessing($0, in: activeSession)
              }) else { return false }
        advance(&activeSession, through: max(activeSession.simulatedAt, nextEvent.simulatedAt))
        session = activeSession
        save()
        return true
    }

    func save() {
        guard var activeSession = session else { return }
        let now = Date()
        CareerProgressionCatalog.reconcile(session: &activeSession)
        activeSession.updatedAt = now
        do {
            try SimulationSaveStore.save(activeSession)
            session = activeSession
            lastSavedAt = now
            errorMessage = nil
        } catch {
            errorMessage = "La partie continue, mais sa sauvegarde a échoué : \(error.localizedDescription)"
        }
    }

    func exportSaveData() throws -> Data {
        if isRunning { advanceFromRealtime() }
        guard var exportSession = session else { throw SimulationEngineError.noSessionToExport }
        let now = Date()
        CareerProgressionCatalog.reconcile(session: &exportSession)
        exportSession.updatedAt = now
        if exportSession.speed != .paused {
            exportSession.resumeSpeed = exportSession.speed
            exportSession.speed = .paused
        }
        return try SimulationSaveStore.encodedData(for: exportSession)
    }

    func importSaveData(_ data: Data) throws {
        var importedSession = try SimulationSaveStore.decode(data)
        let pendingSequences = importedSession.pendingEvents.map(\.sequence)
        guard !importedSession.id.isEmpty,
              !importedSession.scenarioID.isEmpty,
              !importedSession.depotID.isEmpty,
              !importedSession.networkVersions.gtfsID.isEmpty,
              !importedSession.networkVersions.routeGeometryID.isEmpty,
              !importedSession.networkVersions.contractID.isEmpty,
              !importedSession.networkVersions.lineReferenceID.isEmpty,
              Set(pendingSequences).count == pendingSequences.count,
              pendingSequences.allSatisfy({ $0 < importedSession.nextEventSequence }) else {
            throw SimulationEngineError.invalidImportedSave
        }

        pause()
        let now = Date()
        let savedResumeSpeed = importedSession.speed == .paused
            ? importedSession.resumeSpeed
            : importedSession.speed
        importedSession.speed = .paused
        importedSession.resumeSpeed = savedResumeSpeed == .paused ? .x1 : savedResumeSpeed
        importedSession.updatedAt = now
        CareerProgressionCatalog.reconcile(session: &importedSession)
        try SimulationSaveStore.save(importedSession)
        session = importedSession
        lastSavedAt = now
        errorMessage = nil
    }

    func clearError() {
        errorMessage = nil
    }

    func clearRecoveryNotice() {
        recoveryNotice = nil
    }

    private func startClockLoop() {
        guard !isRunning, session != nil else { return }
        let now = ProcessInfo.processInfo.systemUptime
        lastTickUptime = now
        lastAutosaveUptime = now
        isRunning = true
        clockTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: self?.tickIntervalNanoseconds ?? 200_000_000)
                } catch {
                    break
                }
                guard !Task.isCancelled, let self else { break }
                self.advanceFromRealtime()
            }
        }
    }

    private func advanceFromRealtime() {
        guard isRunning,
              let lastTickUptime,
              var activeSession = session else { return }
        let now = ProcessInfo.processInfo.systemUptime
        let elapsed = max(0, now - lastTickUptime)
        self.lastTickUptime = now
        guard elapsed > 0, activeSession.speed != .paused else { return }

        let target = activeSession.simulatedAt.addingTimeInterval(elapsed * Double(activeSession.speed.rawValue))
        advance(&activeSession, through: target)
        session = activeSession

        if let lastAutosaveUptime, now - lastAutosaveUptime >= autosaveInterval {
            self.lastAutosaveUptime = now
            save()
        }
    }

    private func advance(_ activeSession: inout SimulationSession, through target: Date) {
        var processedCount = 0
        var eventIndex = 0
        var cancelledEventSequences = Set<UInt64>()
        var deferredEvents: [SimulationEvent] = []
        let effectiveTarget = target
        while eventIndex < activeSession.pendingEvents.count {
            let event = activeSession.pendingEvents[eventIndex]
            guard event.simulatedAt <= effectiveTarget else { break }
            if Self.requiresRepairResponseBeforeProcessing(event, in: activeSession) {
                deferredEvents.append(event)
                activeSession.pendingEvents.remove(at: eventIndex)
                continue
            }
            if cancelledEventSequences.contains(event.sequence) {
                Self.discardCancelledMachinistRelief(eventSequence: event.sequence, in: &activeSession)
                processedCount += 1
                eventIndex += 1
                continue
            }
            activeSession.simulatedAt = max(activeSession.simulatedAt, event.simulatedAt)
            if case let .routeDetourEnded(details) = event.kind {
                let currentDetour = activeSession.routeDetours?.first { $0.id == details.detourID }
                guard currentDetour?.scheduledEndAt == details.scheduledEndAt,
                      currentDetour?.endedAt == nil else {
                    processedCount += 1
                    eventIndex += 1
                    continue
                }
            }
            if let reliefPlan = activeSession.plannedMachinistReliefs?.first(where: {
                $0.eventSequence == event.sequence
            }) {
                if reliefPlan.cancelledAt != nil {
                    Self.discardCancelledMachinistRelief(eventSequence: event.sequence, in: &activeSession)
                    processedCount += 1
                    eventIndex += 1
                    continue
                }
                let busAtReliefStop = activeSession.ownedBuses?.first(where: {
                    $0.id == (activeSession.machinistServiceAssignments ?? []).first(where: {
                        $0.id == reliefPlan.outgoingAssignmentID
                    })?.vehicleID
                })
                guard busAtReliefStop?.status == .inService,
                      busAtReliefStop?.currentTripID == (activeSession.machinistServiceAssignments ?? []).first(where: {
                          $0.id == reliefPlan.outgoingAssignmentID
                      })?.tripID,
                      busAtReliefStop?.currentStopID == reliefPlan.stopID,
                      busAtReliefStop?.activeMovementLeg == nil else {
                    Self.cancelPlannedMachinistRelief(reliefPlan, at: event.simulatedAt, in: &activeSession)
                    Self.discardCancelledMachinistRelief(eventSequence: event.sequence, in: &activeSession)
                    processedCount += 1
                    eventIndex += 1
                    continue
                }
            }
            var eventForHistory = event
            if case let .busAtStop(tripID, vehicleID, stopID, stopName, stopSequence, _, _) = event.kind,
               let routeID = activeSession.machinistServiceAssignments?.last(where: {
                   $0.vehicleID == vehicleID
                       && $0.tripID == tripID
                       && $0.actualEndAt == nil
                       && $0.plannedStartAt <= event.simulatedAt
                       && $0.plannedEndAt >= event.simulatedAt
               })?.routeID,
               let bypass = Self.bypassEventForClosedStop(
                   sequence: event.sequence,
                   simulatedAt: event.simulatedAt,
                   tripID: tripID,
                   vehicleID: vehicleID,
                   routeID: routeID,
                   stopID: stopID,
                   stopName: stopName,
                   stopSequence: stopSequence,
                   closures: activeSession.stopClosures ?? [],
                   pendingEvents: activeSession.pendingEvents,
                   currentEventIndex: processedCount
               ) {
                eventForHistory = bypass.event
                if let movementSequence = bypass.cancelledMovementSequence {
                    cancelledEventSequences.insert(movementSequence)
                }
            } else if case .passengerDemand = event.kind,
               let resolvedEvent = Self.resolvePassengerDemand(event, in: activeSession) {
                eventForHistory = resolvedEvent
            } else if case let .scheduledServiceDeparture(tripID, routeID, _) = event.kind {
                let suspension = activeSession.activeRouteClosure(routeID: routeID, at: event.simulatedAt)
                eventForHistory = SimulationEvent(
                    sequence: event.sequence,
                    simulatedAt: event.simulatedAt,
                    kind: suspension.map {
                        .routeServiceSuspended(tripID: tripID, routeID: routeID, closureID: $0.id)
                    } ?? .missedServiceDeparture(tripID: tripID, routeID: routeID)
                )
            } else if case let .busServiceCompleted(tripID, vehicleID, stopID, stopName, latitude, longitude) = event.kind,
                      let routeID = activeSession.machinistServiceAssignments?.last(where: {
                          $0.vehicleID == vehicleID
                              && $0.tripID == tripID
                              && $0.actualEndAt == nil
                              && $0.plannedStartAt <= event.simulatedAt
                              && $0.plannedEndAt >= event.simulatedAt
                      })?.routeID,
                      let activeClosure = (activeSession.stopClosures ?? []).first(where: {
                          $0.affects(stopID: stopID, routeID: routeID, at: event.simulatedAt)
                      }),
                      let strandedPassengerCount = activeSession.ownedBuses?.first(where: { $0.id == vehicleID })?.onboardPassengerCount,
                      strandedPassengerCount > 0 {
                if let replacementGuide = activeClosure.replacementGuidesByRouteID?[routeID] {
                    eventForHistory = SimulationEvent(
                        sequence: event.sequence,
                        simulatedAt: event.simulatedAt,
                        kind: .busServiceCompletedAtClosedStopWithPassengerRedirect(
                            tripID: tripID,
                            vehicleID: vehicleID,
                            routeID: routeID,
                            stopID: stopID,
                            stopName: stopName,
                            latitude: latitude,
                            longitude: longitude,
                            passengerCount: strandedPassengerCount,
                            replacementStopID: replacementGuide.replacementStopID,
                            replacementStopName: replacementGuide.replacementStopName
                        )
                    )
                } else {
                    eventForHistory = SimulationEvent(
                        sequence: event.sequence,
                        simulatedAt: event.simulatedAt,
                        kind: .busServiceCompletedAtClosedStop(
                            tripID: tripID,
                            vehicleID: vehicleID,
                            routeID: routeID,
                            stopID: stopID,
                            stopName: stopName,
                            latitude: latitude,
                            longitude: longitude,
                            strandedPassengerCount: strandedPassengerCount
                        )
                    )
                }
            }
            activeSession.eventHistory.append(eventForHistory)
            if case let .routeDetourEnded(details) = event.kind,
               var detours = activeSession.routeDetours,
               let detourIndex = detours.firstIndex(where: { $0.id == details.detourID }),
               detours[detourIndex].scheduledEndAt == details.scheduledEndAt,
               detours[detourIndex].endedAt == nil {
                detours[detourIndex].endedAt = event.simulatedAt
                activeSession.routeDetours = detours
            }
            if case let .routeClosureEnded(closureID, _, _) = event.kind,
               var closures = activeSession.routeClosures,
               let closureIndex = closures.firstIndex(where: { $0.id == closureID }),
               closures[closureIndex].endedAt == nil {
                closures[closureIndex].endedAt = event.simulatedAt
                activeSession.routeClosures = closures
            }
            if case let .vehicleBreakdown(incident) = event.kind {
                Self.cancelPlannedMachinistReliefs(for: incident, in: &activeSession)
                cancelledEventSequences.formUnion(Self.remainingTripEventSequences(
                    for: incident,
                    after: processedCount,
                    in: activeSession.pendingEvents
                ))
            }
            Self.recordTripDistance(for: event, in: &activeSession)
            if case let .vehicleDelivered(vehicleID) = event.kind,
               let index = activeSession.ownedBuses?.firstIndex(where: { $0.id == vehicleID }) {
                activeSession.ownedBuses?[index].status = .atDepot
            }
            Self.applyVehicleEvent(eventForHistory, to: &activeSession)
            Self.applyMachinistEvent(eventForHistory, to: &activeSession)
            Self.applyLoanEvent(event, to: &activeSession)
            Self.applyInvoiceSettlementEvent(event, to: &activeSession)
            Self.finalizeMachinistService(for: event, in: &activeSession)
            Self.completeMachinistRelief(eventSequence: event.sequence, in: &activeSession)
            Self.discardCancelledMachinistRelief(eventSequence: event.sequence, in: &activeSession)
            switch event.kind {
            case let .busServiceCompleted(tripID, vehicleID, _, _, _, _):
                activeSession.dispatchedTripRoutePlans?.removeAll {
                    $0.tripID == tripID && $0.vehicleID == vehicleID
                }
            case let .vehicleBreakdown(incident):
                activeSession.dispatchedTripRoutePlans?.removeAll {
                    $0.tripID == incident.tripID && $0.vehicleID == incident.vehicleID
                }
            default:
                break
            }
            if case let .dailySettlement(dateKey) = event.kind {
                let contractSettlement = Self.recordContractPerformanceSettlement(
                    for: dateKey,
                    settledAt: event.simulatedAt,
                    in: &activeSession
                )
                let invoiceSettlementEvents = Self.issueDailyInvoices(
                    for: dateKey,
                    issuedAt: event.simulatedAt,
                    in: &activeSession
                )
                activeSession.pendingEvents.append(contentsOf: invoiceSettlementEvents)
                activeSession.pendingEvents.sort(by: Self.eventOrder)
                Self.recordDailyOperationsReport(
                    for: dateKey,
                    contractCompletionRate: contractSettlement?.completionRate,
                    contractQualityAdjustmentEuro: contractSettlement?.adjustmentEuro,
                    in: &activeSession
                )
            }
            processedCount += 1
            eventIndex += 1
        }
        if processedCount > 0 {
            activeSession.pendingEvents.removeFirst(processedCount)
        }
        if !cancelledEventSequences.isEmpty {
            activeSession.pendingEvents.removeAll { cancelledEventSequences.contains($0.sequence) }
        }
        activeSession.pendingEvents.append(contentsOf: deferredEvents)
        activeSession.pendingEvents.sort(by: Self.eventOrder)
        activeSession.simulatedAt = max(activeSession.simulatedAt, effectiveTarget)
        Self.updateVehiclePositions(in: &activeSession, through: effectiveTarget)
        CareerProgressionCatalog.reconcile(session: &activeSession)
    }

    private static func movementLeg(
        from start: ScheduledTripStopVisit,
        to end: ScheduledTripStopVisit
    ) -> ScheduledBusMovementLeg? {
        guard let startsAt = start.departureAt,
              let coordinates = start.movementToNext,
              coordinates.count >= 2,
              end.scheduledAt > startsAt else { return nil }
        return ScheduledBusMovementLeg(
            startsAt: startsAt,
            endsAt: end.scheduledAt,
            coordinates: coordinates,
            geometrySource: start.movementGeometrySource
        )
    }

    private static func bypassEventForClosedStop(
        sequence: UInt64,
        simulatedAt: Date,
        tripID: String,
        vehicleID: String,
        routeID: String,
        stopID: String,
        stopName: String,
        stopSequence: Int,
        closures: [SimulatedStopClosure],
        pendingEvents: [SimulationEvent],
        currentEventIndex: Int
    ) -> (event: SimulationEvent, cancelledMovementSequence: UInt64?)? {
        guard closures.contains(where: { $0.affects(stopID: stopID, routeID: routeID, at: simulatedAt) }) else {
            return nil
        }

        let eventsAfterCurrent = pendingEvents.dropFirst(currentEventIndex + 1)
        guard let nextStopEvent = eventsAfterCurrent.first(where: { candidate in
            guard case let .busAtStop(candidateTripID, candidateVehicleID, _, _, candidateStopSequence, _, _) = candidate.kind else {
                return false
            }
            return candidateTripID == tripID
                && candidateVehicleID == vehicleID
                && candidateStopSequence > stopSequence
        }), nextStopEvent.simulatedAt > simulatedAt else {
            return nil
        }

        let outgoingMovementEvent = eventsAfterCurrent.first { candidate in
            guard candidate.simulatedAt <= nextStopEvent.simulatedAt,
                  case let .busMovementStarted(candidateVehicleID, leg) = candidate.kind else {
                return false
            }
            return candidateVehicleID == vehicleID
                && leg.startsAt >= simulatedAt
                && abs(leg.endsAt.timeIntervalSince(nextStopEvent.simulatedAt)) <= 1
        }

        let movementLeg: ScheduledBusMovementLeg?
        if let outgoingMovementEvent,
           case let .busMovementStarted(_, leg) = outgoingMovementEvent.kind {
            movementLeg = ScheduledBusMovementLeg(
                startsAt: simulatedAt,
                endsAt: leg.endsAt,
                coordinates: leg.coordinates,
                geometrySource: leg.geometrySource
            )
        } else {
            movementLeg = nil
        }

        return (
            SimulationEvent(
                sequence: sequence,
                simulatedAt: simulatedAt,
                kind: .busStopBypassed(
                    tripID: tripID,
                    vehicleID: vehicleID,
                    routeID: routeID,
                    stopID: stopID,
                    stopName: stopName,
                    movementLeg: movementLeg
                )
            ),
            outgoingMovementEvent?.sequence
        )
    }

    private static func plannedVehicleIncident(
        bus: PurchasedBus,
        model: VehicleMarketModel?,
        tripID: String,
        routeID: String,
        serviceDateKey: Int,
        stopVisits: [ScheduledTripStopVisit],
        randomSeed: UInt64,
        frequency: VehicleIncidentFrequency
    ) -> VehicleIncident? {
        guard let model, stopVisits.count >= 3 else { return nil }
        let distanceMeters = stopVisits.indices.dropLast().reduce(into: 0.0) { total, index in
            let start = stopVisits[index]
            let end = stopVisits[index + 1]
            if let shapeCoordinates = start.movementToNext, shapeCoordinates.count >= 2 {
                total += pathDistance(shapeCoordinates)
            } else {
                total += pathDistance([
                    BusMovementCoordinate(latitude: start.latitude, longitude: start.longitude),
                    BusMovementCoordinate(latitude: end.latitude, longitude: end.longitude)
                ])
            }
        }
        let distanceKilometers = distanceMeters / 1_000
        guard distanceKilometers.isFinite, distanceKilometers > 0 else { return nil }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = GTFSServiceDate.parisTimeZone
        let simulatedYear = calendar.component(.year, from: stopVisits[0].scheduledAt)
        let ageYears = max(0, simulatedYear - bus.modelYear)
        let ageFactor = 1 + Double(ageYears) * 0.045
        let mileageFactor = 1 + Double(max(0, bus.odometerKilometers)) / 500_000 * 0.45
        let condition = min(100, max(0, bus.conditionPercent))
        let conditionFactor = 1 + Double(100 - condition) / 100 * 1.4
        let energyFactor: Double = switch model.energy {
        case .diesel: 1
        case .dieselHybrid: 1.03
        case .gnv: 1.05
        case .gnvHybrid: 1.08
        case .electric: 1
        }
        let hazard = 0.00025
            * frequency.hazardMultiplier
            * ageFactor
            * mileageFactor
            * conditionFactor
            * energyFactor
            * distanceKilometers
        let probability = min(0.5, 1 - exp(-hazard))
        let key = "\(randomSeed)|\(bus.id)|\(tripID)|\(routeID)|\(serviceDateKey)|breakdown"
        let roll = deterministicDemandHash(seed: randomSeed, key: key) % 1_000_000
        guard Double(roll) / 1_000_000 < probability else { return nil }

        let stopChoice = deterministicDemandHash(seed: randomSeed, key: key + "|stop")
        let stopIndex = 1 + Int(stopChoice % UInt64(stopVisits.count - 2))
        let severityChoice = deterministicDemandHash(seed: randomSeed, key: key + "|severity") % 100
        let severity: VehicleIncidentSeverity = switch severityChoice {
        case 0..<78: .minor
        case 78..<97: .major
        default: .immobilizing
        }
        let stop = stopVisits[stopIndex]
        return VehicleIncident(
            id: "incident-\(bus.id)-\(tripID)-\(serviceDateKey)-\(stop.stopSequence)",
            vehicleID: bus.id,
            vehicleModelName: model.displayName,
            tripID: tripID,
            routeID: routeID,
            stopID: stop.stopID,
            stopName: stop.stopName,
            latitude: stop.latitude,
            longitude: stop.longitude,
            occurredAt: stop.scheduledAt,
            severity: severity,
            serviceDateKey: serviceDateKey,
            stopSequence: stop.stopSequence,
            repairCompletedAt: stop.scheduledAt.addingTimeInterval(severity.repairDuration),
            repairCostEuro: severity.repairCostEuro,
            displacedPassengerCount: 0,
            repairResponse: nil,
            diagnosisRequired: true,
            resolvedAt: nil
        )
    }

    private static func dailySettlementEvents(
        from start: Date,
        through end: Date,
        nextSequence: inout UInt64
    ) -> [SimulationEvent] {
        guard start < end else { return [] }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = GTFSServiceDate.parisTimeZone
        guard let firstMidnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: start)) else {
            return []
        }
        var settlementAt = firstMidnight
        var events: [SimulationEvent] = []
        while settlementAt <= end {
            let closedDate = settlementAt.addingTimeInterval(-1)
            guard let dateKey = GTFSServiceDate.key(for: closedDate, timeZone: calendar.timeZone) else { break }
            events.append(SimulationEvent(
                sequence: nextSequence,
                simulatedAt: settlementAt,
                kind: .dailySettlement(dateKey: dateKey)
            ))
            nextSequence &+= 1
            guard let nextMidnight = calendar.date(byAdding: .day, value: 1, to: settlementAt) else { break }
            settlementAt = nextMidnight
        }
        return events
    }

    private static func cancelPlannedMachinistReliefs(for incident: VehicleIncident, in session: inout SimulationSession) {
        let assignmentIDs = Set((session.machinistServiceAssignments ?? []).filter {
            $0.vehicleID == incident.vehicleID && $0.tripID == incident.tripID
        }.map(\.id))
        let plans = (session.plannedMachinistReliefs ?? []).filter { plan in
            assignmentIDs.contains(plan.outgoingAssignmentID)
                && (session.pendingEvents.first(where: { $0.sequence == plan.eventSequence })?.simulatedAt ?? .distantPast) >= incident.occurredAt
        }
        for plan in plans {
            cancelPlannedMachinistRelief(plan, at: incident.occurredAt, in: &session)
        }
    }

    private static func cancelPlannedMachinistRelief(
        _ plan: MachinistReliefPlan,
        at date: Date,
        in session: inout SimulationSession
    ) {
        if var assignments = session.machinistServiceAssignments,
           let incomingIndex = assignments.firstIndex(where: { $0.id == plan.incomingAssignmentID }) {
            let dutyBlockID = assignments[incomingIndex].dutyBlockID
            assignments.remove(at: incomingIndex)
            session.machinistServiceAssignments = assignments
            if let dutyBlockID, var dutyBlocks = session.machinistDutyBlocks,
               let blockIndex = dutyBlocks.firstIndex(where: { $0.id == dutyBlockID }) {
                let remaining = assignments.filter { $0.dutyBlockID == dutyBlockID }
                if remaining.isEmpty, dutyBlocks[blockIndex].laborCostEuro == nil {
                    dutyBlocks.remove(at: blockIndex)
                } else if !remaining.isEmpty {
                    dutyBlocks[blockIndex].plannedStartAt = remaining.map(\.plannedStartAt).min() ?? dutyBlocks[blockIndex].plannedStartAt
                    dutyBlocks[blockIndex].plannedEndAt = remaining.map(\.plannedEndAt).max() ?? dutyBlocks[blockIndex].plannedEndAt
                }
                session.machinistDutyBlocks = dutyBlocks
            }
        }
        guard var plans = session.plannedMachinistReliefs,
              let planIndex = plans.firstIndex(where: { $0.eventSequence == plan.eventSequence }) else { return }
        plans[planIndex].cancelledAt = date
        session.plannedMachinistReliefs = plans
    }

    private static func completeMachinistRelief(eventSequence: UInt64, in session: inout SimulationSession) {
        guard var plans = session.plannedMachinistReliefs else { return }
        plans.removeAll { $0.eventSequence == eventSequence && $0.cancelledAt == nil }
        session.plannedMachinistReliefs = plans
    }

    private static func discardCancelledMachinistRelief(eventSequence: UInt64, in session: inout SimulationSession) {
        guard var plans = session.plannedMachinistReliefs else { return }
        plans.removeAll { $0.eventSequence == eventSequence && $0.cancelledAt != nil }
        session.plannedMachinistReliefs = plans
    }

    private static func remainingTripEventSequences(
        for incident: VehicleIncident,
        after currentIndex: Int,
        in events: [SimulationEvent]
    ) -> Set<UInt64> {
        Set(events.enumerated().dropFirst(currentIndex + 1).compactMap { _, event in
            guard event.simulatedAt >= incident.occurredAt else { return nil }
            switch event.kind {
            case let .busDeparted(tripID, _, _, _, _, _),
                 let .busAtStop(tripID, _, _, _, _, _, _),
                 let .busServiceCompleted(tripID, _, _, _, _, _):
                return tripID == incident.tripID ? event.sequence : nil
            case let .vehicleReplacementDeparted(_, tripID, _, _, _, _, _, _):
                return tripID == incident.tripID ? event.sequence : nil
            case let .passengerDemand(demand):
                return demand.tripID == incident.tripID ? event.sequence : nil
            case let .passengersExchanged(exchange):
                return exchange.tripID == incident.tripID ? event.sequence : nil
            case let .machinistRelieved(tripID, vehicleID, _, _, _, _):
                return tripID == incident.tripID && vehicleID == incident.vehicleID ? event.sequence : nil
            case let .busMovementStarted(vehicleID, _):
                return vehicleID == incident.vehicleID ? event.sequence : nil
            default:
                return nil
            }
        })
    }

    private static func requiresRepairResponseBeforeProcessing(
        _ event: SimulationEvent,
        in session: SimulationSession
    ) -> Bool {
        let incidentID: String
        switch event.kind {
        case let .vehicleTowTeamArrived(id),
             let .vehicleTowStarted(id),
             let .vehicleTowArrived(id),
             let .vehicleWorkshopWorkStarted(id),
             let .vehicleRepairCompleted(id):
            incidentID = id
        default:
            return false
        }

        guard let incident = session.vehicleIncidents?.first(where: { $0.id == incidentID }) else {
            return false
        }
        return !incident.isResolved && incident.repairResponse == nil
    }

    private static func estimatedPassengerDemands(
        tripID: String,
        routeID: String,
        vehicleID: String,
        serviceDateKey: Int,
        stopVisits: [ScheduledTripStopVisit],
        capacity: Int,
        capacityIsEstimated: Bool,
        randomSeed: UInt64
    ) -> [PassengerStopDemand] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = GTFSServiceDate.parisTimeZone
        let loadProfileHash = deterministicDemandHash(
            seed: randomSeed,
            key: "\(tripID)|\(routeID)|\(serviceDateKey)|load-profile"
        )
        let loadProfileMultiplier: Double
        switch loadProfileHash % 100 {
        case 0..<20: loadProfileMultiplier = 2.4
        case 20..<65: loadProfileMultiplier = 1.25
        default: loadProfileMultiplier = 0.72
        }
        return stopVisits.enumerated().map { index, visit in
            let isFirstStop = index == 0
            let isTerminal = index == stopVisits.count - 1
            let key = "\(tripID)|\(routeID)|\(serviceDateKey)|\(visit.stopID)|\(visit.stopSequence)"
            let hash = deterministicDemandHash(seed: randomSeed, key: key)
            let hour = calendar.component(.hour, from: visit.scheduledAt)
            let isWeekend = calendar.isDateInWeekend(visit.scheduledAt)
            let periodMultiplier: Double
            switch hour {
            case 6...9: periodMultiplier = isWeekend ? 0.95 : 1.45
            case 16...19: periodMultiplier = isWeekend ? 0.9 : 1.35
            case 10...15: periodMultiplier = isWeekend ? 0.85 : 0.95
            case 20...22: periodMultiplier = 0.55
            default: periodMultiplier = 0.3
            }
            let baseWaiting = isFirstStop ? 10 + Int(hash % 16) : 2 + Int(hash % 10)
            let estimatedWaiting = Int((Double(baseWaiting) * periodMultiplier * loadProfileMultiplier).rounded())
            let alightingShare = 0.15 + Double((hash >> 8) % 10_000) / 10_000 * 0.30
            return PassengerStopDemand(
                tripID: tripID,
                vehicleID: vehicleID,
                routeID: routeID,
                stopID: visit.stopID,
                stopName: visit.stopName,
                occurredAt: visit.scheduledAt,
                estimatedArrivalsCount: estimatedWaiting,
                alightingShare: isFirstStop ? 0 : alightingShare,
                isTerminal: isTerminal,
                capacity: capacity,
                capacityIsEstimated: capacityIsEstimated
            )
        }
    }

    private static func resolvePassengerDemand(
        _ event: SimulationEvent,
        in session: SimulationSession
    ) -> SimulationEvent? {
        guard case let .passengerDemand(demand) = event.kind,
              let bus = session.ownedBuses?.first(where: { $0.id == demand.vehicleID }) else { return nil }
        let queueKey = passengerQueueKey(routeID: demand.routeID, stopID: demand.stopID)
        let waitingBefore = max(0, session.passengerQueuesByRouteStopKey?[queueKey] ?? 0)
        let elapsedSinceLastVisit = session.passengerQueueUpdatedAtByRouteStopKey?[queueKey]
            .map { demand.occurredAt.timeIntervalSince($0) }
            .map { min(10_800.0, max(300.0, $0)) }
            ?? 1_800.0
        let baselineEstimatedArrivals = Int((Double(demand.estimatedArrivalsCount) * elapsedSinceLastVisit / 1_800.0).rounded())
        let hasPublishedDetourMessage = (session.routeDetours ?? []).contains { detour in
            detour.routeID == demand.routeID
                && detour.isActive(at: demand.occurredAt)
                && detour.passengerInformationMessage?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .isEmpty == false
        }
        let informedPassengersAvoidingRouteCount = hasPublishedDetourMessage
            ? PassengerInformationRules.avoidedArrivals(from: baselineEstimatedArrivals)
            : 0
        let estimatedArrivals = max(0, baselineEstimatedArrivals - informedPassengersAvoidingRouteCount)
        let waitingIncludingArrivals = waitingBefore + estimatedArrivals
        let onboardBefore = max(0, bus.onboardPassengerCount ?? 0)
        let activeClosure = session.stopClosures?.first(where: {
            $0.affects(stopID: demand.stopID, routeID: demand.routeID, at: demand.occurredAt)
        })
        let replacementGuide = activeClosure?.replacementGuidesByRouteID?[demand.routeID]
        let stopWasClosed = activeClosure != nil
        let alighted = stopWasClosed
            ? 0
            : (demand.isTerminal
                ? onboardBefore
                : min(onboardBefore, Int((Double(onboardBefore) * demand.alightingShare).rounded())))
        let onboardAfterAlighting = max(0, onboardBefore - alighted)
        let remainingCapacity = max(0, demand.capacity - onboardAfterAlighting)
        let boarded = (stopWasClosed || demand.isTerminal) ? 0 : min(waitingIncludingArrivals, remainingCapacity)
        var queueAfter = waitingIncludingArrivals - boarded
        var replacementWaitingAfter: Int?
        let informationWasPublished = activeClosure?.passengerInformationMessage != nil
        let passengerCanFollowReplacement = stopWasClosed && informationWasPublished && replacementGuide != nil
        if passengerCanFollowReplacement, let replacementGuide {
            let replacementQueueKey = passengerQueueKey(
                routeID: demand.routeID,
                stopID: replacementGuide.replacementStopID
            )
            let waitingAtReplacement = max(0, session.passengerQueuesByRouteStopKey?[replacementQueueKey] ?? 0)
            replacementWaitingAfter = waitingAtReplacement + waitingIncludingArrivals
            queueAfter = 0
        }
        let boardedFromPreviousQueue = min(waitingBefore, boarded)
        let newlyBoarded = boarded - boardedFromPreviousQueue
        let newlyLeftBehind = stopWasClosed
            ? (passengerCanFollowReplacement ? 0 : estimatedArrivals)
            : (demand.isTerminal ? 0 : max(0, estimatedArrivals - newlyBoarded))
        let exchange = PassengerStopExchange(
            tripID: demand.tripID,
            vehicleID: demand.vehicleID,
            routeID: demand.routeID,
            stopID: demand.stopID,
            stopName: demand.stopName,
            occurredAt: demand.occurredAt,
            boardedCount: boarded,
            alightedCount: alighted,
            leftBehindCount: queueAfter,
            onboardAfterExchange: (demand.isTerminal && !stopWasClosed) ? 0 : onboardAfterAlighting + boarded,
            capacity: demand.capacity,
            capacityIsEstimated: demand.capacityIsEstimated,
            estimatedArrivalsCount: estimatedArrivals,
            waitingBeforeCount: waitingBefore,
            waitingAfterCount: queueAfter,
            newlyLeftBehindCount: newlyLeftBehind,
            stopWasClosed: stopWasClosed,
            redirectedPassengerCount: passengerCanFollowReplacement ? waitingIncludingArrivals : nil,
            replacementStopID: passengerCanFollowReplacement ? replacementGuide?.replacementStopID : nil,
            replacementStopName: passengerCanFollowReplacement ? replacementGuide?.replacementStopName : nil,
            replacementWaitingAfterCount: replacementWaitingAfter,
            informedPassengersAvoidingRouteCount: informedPassengersAvoidingRouteCount > 0
                ? informedPassengersAvoidingRouteCount
                : nil
        )
        let resolvedEvent = SimulationEvent(
            sequence: event.sequence,
            simulatedAt: event.simulatedAt,
            kind: .passengersExchanged(exchange)
        )
        return resolvedEvent
    }

    private static func deterministicDemandHash(seed: UInt64, key: String) -> UInt64 {
        var hash = seed ^ 14_695_981_039_346_656_037
        for byte in key.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        hash ^= hash >> 30
        hash &*= 0xbf58_476d_1ce4_e5b9
        hash ^= hash >> 27
        hash &*= 0x94d0_49bb_1331_11eb
        return hash ^ (hash >> 31)
    }

    private static func passengerQueueKey(routeID: String, stopID: String) -> String {
        "\(routeID)|\(stopID)"
    }

    private static func recordTripDistance(for event: SimulationEvent, in session: inout SimulationSession) {
        let tripID: String
        let vehicleID: String
        let meters: Double
        let isServiceDistance: Bool
        let distanceContext: String
        let serviceGeometrySource: ServiceMovementGeometrySource?
        switch event.kind {
        case let .busAtStop(id, vehicle, _, _, _, _, _):
            guard let leg = session.ownedBuses?.first(where: { $0.id == vehicle })?.activeMovementLeg else { return }
            tripID = id
            vehicleID = vehicle
            meters = pathDistance(leg.coordinates)
            isServiceDistance = true
            serviceGeometrySource = leg.geometrySource
            switch leg.geometrySource {
            case .gtfsShape, nil:
                distanceContext = "en ligne"
            case .stopCoordinateEstimate:
                distanceContext = "en ligne · estimation entre coordonnées d’arrêts faute de forme GTFS raccordable"
            case .temporaryRouteDetour:
                distanceContext = "en ligne · détour MapKit temporaire, estimation de jeu"
            }
        case let .busDeadheadArrived(id, _, vehicle, _, _, _, _, distanceMeters):
            tripID = id
            vehicleID = vehicle
            meters = distanceMeters
            isServiceDistance = false
            distanceContext = "acheminement à vide vers le premier arrêt"
            serviceGeometrySource = nil
        case let .busDepotReturnArrived(vehicle, _, _, _, _, distanceMeters):
            tripID = "retour-depot-\(vehicle)-\(event.sequence)"
            vehicleID = vehicle
            meters = distanceMeters
            isServiceDistance = false
            distanceContext = "retour à vide au dépôt"
            serviceGeometrySource = nil
        case let .busDepotReturnArrivedWithMachinist(returnTripID, vehicle, _, _, _, _, distanceMeters):
            tripID = returnTripID
            vehicleID = vehicle
            meters = distanceMeters
            isServiceDistance = false
            distanceContext = "retour à vide au dépôt"
            serviceGeometrySource = nil
        default:
            return
        }
        guard var buses = session.ownedBuses,
              let busIndex = buses.firstIndex(where: { $0.id == vehicleID }) else { return }
        guard meters.isFinite, meters > 0 else { return }
        let model = VehicleMarketCatalog.model(id: buses[busIndex].modelID)
        let estimate = model.map(VehicleMarketCatalog.energyEstimate(for:))
        let previousEnergyUnits = buses[busIndex].energyConsumedUnits ?? 0
        let energyUnits = estimate.map { meters / 100_000 * $0.quantityPer100Kilometers }
        let accumulatedEnergyUnits = energyUnits.map { previousEnergyUnits + $0 }
        let energyCost = estimate.flatMap { energyEstimate -> Int? in
            guard session.cashBalance != nil else { return nil }
            let previousTotal = Int((previousEnergyUnits * energyEstimate.pricePerUnitEuro).rounded())
            let accumulatedTotal = Int(((accumulatedEnergyUnits ?? previousEnergyUnits) * energyEstimate.pricePerUnitEuro).rounded())
            return max(0, accumulatedTotal - previousTotal)
        }
        var records = session.tripDistanceRecords ?? []
        let tripInstanceID = buses[busIndex].reservedTripKey
        let previousTripDistanceMeters = records.reduce(into: 0.0) { total, record in
            guard record.tripID == tripID,
                  record.vehicleID == vehicleID,
                  record.tripInstanceID == tripInstanceID,
                  record.isServiceDistance != false else { return }
            total += record.distanceMeters
        }
        let rate = VehicleMarketCatalog.estimatedServiceRevenuePerVehicleKilometerEuro
        let previousServiceRevenue = Int((previousTripDistanceMeters / 1_000 * rate).rounded())
        let accumulatedServiceRevenue = Int(((previousTripDistanceMeters + meters) / 1_000 * rate).rounded())
        let serviceRevenue = (!isServiceDistance || session.cashBalance == nil)
            ? nil
            : max(0, accumulatedServiceRevenue - previousServiceRevenue)
        records.append(TripDistanceRecord(
            eventSequence: event.sequence,
            tripID: tripID,
            tripInstanceID: tripInstanceID,
            vehicleID: vehicleID,
            occurredAt: event.simulatedAt,
            distanceMeters: meters,
            energyConsumedUnits: energyUnits,
            estimatedEnergyCostEuro: energyCost,
            estimatedServiceRevenueEuro: serviceRevenue,
            isServiceDistance: isServiceDistance,
            serviceGeometrySource: serviceGeometrySource
        ))
        session.tripDistanceRecords = records
        let previousVehicleDistanceMeters = max(0, buses[busIndex].distanceTravelledMeters ?? 0)
        let accumulatedVehicleDistanceMeters = previousVehicleDistanceMeters + meters
        let kilometersBeforeSegment = Int((previousVehicleDistanceMeters / 1_000).rounded(.down))
        let kilometersAfterSegment = Int((accumulatedVehicleDistanceMeters / 1_000).rounded(.down))
        let conditionIntervalMeters = Double(VehicleMarketCatalog.conditionWearIntervalKilometers) * 1_000
        let maintenanceDistanceMeters = max(0, buses[busIndex].lastPreventiveMaintenanceDistanceMeters ?? 0)
        let distanceSinceMaintenanceBefore = max(0, previousVehicleDistanceMeters - maintenanceDistanceMeters)
        let distanceSinceMaintenanceAfter = max(0, accumulatedVehicleDistanceMeters - maintenanceDistanceMeters)
        let wearIntervalsBeforeSegment = Int((distanceSinceMaintenanceBefore / conditionIntervalMeters).rounded(.down))
        let wearIntervalsAfterSegment = Int((distanceSinceMaintenanceAfter / conditionIntervalMeters).rounded(.down))
        let conditionLoss = (wearIntervalsAfterSegment - wearIntervalsBeforeSegment)
            * VehicleMarketCatalog.conditionWearPercentPerInterval
        buses[busIndex].distanceTravelledMeters = accumulatedVehicleDistanceMeters
        buses[busIndex].odometerKilometers += max(0, kilometersAfterSegment - kilometersBeforeSegment)
        buses[busIndex].conditionPercent = max(0, min(100, buses[busIndex].conditionPercent - conditionLoss))
        if let accumulatedEnergyUnits {
            buses[busIndex].energyConsumedUnits = accumulatedEnergyUnits
        }
        if session.energySimulationVersion != nil,
           let capacity = buses[busIndex].batteryCapacityKWh,
           let charge = buses[busIndex].batteryChargeKWh,
           model?.energy == .electric,
           let energyUnits {
            buses[busIndex].batteryChargeKWh = min(capacity, max(0, charge - energyUnits))
        }
        session.ownedBuses = buses

        var ledgerEntries = session.ledgerEntries ?? []
        if let energyCost,
           energyCost > 0,
           let model,
           let estimate {
            ledgerEntries.append(SimulationLedgerEntry(
                id: "energy-\(event.sequence)",
                occurredAt: event.simulatedAt,
                category: "Énergie estimée",
                description: "\(model.displayName) · \(distanceContext) · \((meters / 1_000).formatted(.number.precision(.fractionLength(1)))) km · \(estimate.assumptionDescription)",
                amount: -energyCost,
                cashDeltaEuro: 0
            ))
        }
        if let serviceRevenue, serviceRevenue > 0 {
            ledgerEntries.append(SimulationLedgerEntry(
                id: "service-revenue-\(event.sequence)",
                occurredAt: event.simulatedAt,
                category: "Contribution contractuelle estimée (jeu)",
                description: "Course \(tripID) · \((meters / 1_000).formatted(.number.precision(.fractionLength(1)))) véhicule-km\(serviceGeometrySource == .stopCoordinateEstimate ? " · distance estimée entre coordonnées d’arrêts" : serviceGeometrySource == .temporaryRouteDetour ? " · détour MapKit temporaire, estimation de jeu" : "") · hypothèse de jeu \(rate.formatted(.currency(code: "EUR").precision(.fractionLength(2))))/km",
                amount: serviceRevenue,
                cashDeltaEuro: 0
            ))
        }
        session.ledgerEntries = ledgerEntries
    }

    private static func recordContractPerformanceSettlement(
        for dateKey: Int,
        settledAt: Date,
        in session: inout SimulationSession
    ) -> (completionRate: Double, adjustmentEuro: Int)? {
        guard session.scenarioID == ScenarioDefinition.bordsDeMarne.id,
              ScenarioDefinition.bordsDeMarne.isContractActive(onServiceDateKey: dateKey),
              session.cashBalance != nil else { return nil }

        let dayEvents = session.eventHistory.filter {
            GTFSServiceDate.key(for: $0.simulatedAt, timeZone: GTFSServiceDate.parisTimeZone) == dateKey
        }
        let publishedDepartureCount = dayEvents.reduce(into: 0) { count, event in
            if case .scheduledServiceDeparture = event.kind { count += 1 }
        }
        let recordedDepartureCount = dayEvents.reduce(into: 0) { count, event in
            switch event.kind {
            case .busDeparted, .missedServiceDeparture, .routeServiceSuspended:
                count += 1
            default:
                break
            }
        }
        let completedCount = dayEvents.reduce(into: 0) { count, event in
            switch event.kind {
            case .busServiceCompleted, .busServiceCompletedAtClosedStop, .busServiceCompletedAtClosedStopWithPassengerRedirect:
                count += 1
            default:
                break
            }
        }
        let plannedDepartureCount = max(publishedDepartureCount, recordedDepartureCount)
        guard plannedDepartureCount > 0 else { return nil }
        let completionRate = min(1, Double(completedCount) / Double(plannedDepartureCount))
        let contributionCategories: Set<String> = [
            "Contribution contractuelle estimée (jeu)",
            "Recette de service estimée"
        ]
        let contributionEuro = (session.ledgerEntries ?? []).reduce(into: 0) { total, entry in
            if contributionCategories.contains(entry.category),
               entry.amount > 0,
               GTFSServiceDate.key(for: entry.occurredAt, timeZone: GTFSServiceDate.parisTimeZone) == dateKey {
                total += entry.amount
            }
        }
        let entryID = "contract-quality-\(dateKey)"
        let existingAdjustment = session.ledgerEntries?.first(where: { $0.id == entryID })
        let adjustmentEuro = existingAdjustment?.amount
            ?? ContractEconomicsRules.productionAdjustmentEuro(
                contributionEuro: contributionEuro,
                completionRate: completionRate
            )

        if existingAdjustment == nil, adjustmentEuro != 0 {
            let category = adjustmentEuro > 0
                ? "Bonus de production contractuelle (jeu)"
                : "Malus de production contractuelle (jeu)"
            let sign = adjustmentEuro > 0 ? "+" : "−"
            session.ledgerEntries = (session.ledgerEntries ?? []) + [SimulationLedgerEntry(
                id: entryID,
                occurredAt: settledAt.addingTimeInterval(-1),
                category: category,
                description: "DSP 45 · production \((completionRate * 100).formatted(.number.precision(.fractionLength(1)))) % · ajustement de jeu \(sign)\(abs(adjustmentEuro).formatted()) €",
                amount: adjustmentEuro,
                cashDeltaEuro: 0
            )]
        }
        return (completionRate, adjustmentEuro)
    }

    private static func issueDailyInvoices(
        for dateKey: Int,
        issuedAt: Date,
        in session: inout SimulationSession
    ) -> [SimulationEvent] {
        guard session.cashBalance != nil else { return [] }

        let contractCategories: Set<String> = [
            "Contribution contractuelle estimée (jeu)",
            "Recette de service estimée",
            "Bonus de production contractuelle (jeu)",
            "Malus de production contractuelle (jeu)"
        ]
        let invoicedEntryIDs = Set((session.invoices ?? []).flatMap(\.lineItems).map(\.ledgerEntryID))
        let newAccruals = (session.ledgerEntries ?? []).filter { entry in
            entry.cashDeltaEuro == 0
                && !invoicedEntryIDs.contains(entry.id)
                && GTFSServiceDate.key(for: entry.occurredAt, timeZone: GTFSServiceDate.parisTimeZone) == dateKey
        }
        let contractEntries = newAccruals.filter { contractCategories.contains($0.category) }
        let energyEntries = newAccruals.filter { $0.category == "Énergie estimée" }
        let payrollEntries = newAccruals.filter { $0.category == "Rémunération machinistes" }
        let workshopCategories: Set<String> = [
            "Entretien préventif",
            "Réparation",
            "Diagnostic de panne",
            "Pièces d’atelier"
        ]
        let workshopEntries = newAccruals.filter { workshopCategories.contains($0.category) }
        var invoices = session.invoices ?? []
        var newInvoices: [SimulationInvoice] = []

        let contractNet = contractEntries.reduce(into: 0) { $0 += $1.amount }
        let contractInvoiceID = "invoice-contract-\(dateKey)"
        let contractCounterparty = ScenarioDefinition.contractDisplayName(forScenarioID: session.scenarioID)
            ?? "Contrat du scénario"
        if contractNet != 0,
           !invoices.contains(where: { $0.id == contractInvoiceID }) {
            let direction: SimulationInvoiceDirection = contractNet > 0 ? .receivable : .payable
            newInvoices.append(SimulationInvoice(
                id: contractInvoiceID,
                title: "Prestation contractuelle",
                counterparty: "\(contractCounterparty) · estimation de jeu",
                direction: direction,
                issuedAt: issuedAt,
                dueAt: SimulationInvoiceRules.dueDate(for: issuedAt),
                lineItems: contractEntries.sorted { $0.occurredAt < $1.occurredAt }.map {
                    SimulationInvoiceLineItem(
                        ledgerEntryID: $0.id,
                        category: $0.category,
                        description: $0.description,
                        amountEuro: $0.amount
                    )
                }
            ))
        }

        let energyNet = energyEntries.reduce(into: 0) { $0 += $1.amount }
        let energyInvoiceID = "invoice-energy-\(dateKey)"
        if energyNet != 0,
           !invoices.contains(where: { $0.id == energyInvoiceID }) {
            let direction: SimulationInvoiceDirection = energyNet > 0 ? .receivable : .payable
            newInvoices.append(SimulationInvoice(
                id: energyInvoiceID,
                title: "Énergie du parc",
                counterparty: "Fournisseurs d’énergie · estimation de jeu",
                direction: direction,
                issuedAt: issuedAt,
                dueAt: SimulationInvoiceRules.dueDate(for: issuedAt),
                lineItems: energyEntries.sorted { $0.occurredAt < $1.occurredAt }.map {
                    SimulationInvoiceLineItem(
                        ledgerEntryID: $0.id,
                        category: $0.category,
                        description: $0.description,
                        amountEuro: $0.amount
                    )
                }
            ))
        }

        let payrollNet = payrollEntries.reduce(into: 0) { $0 += $1.amount }
        let payrollInvoiceID = "invoice-payroll-\(dateKey)"
        if payrollNet != 0,
           !invoices.contains(where: { $0.id == payrollInvoiceID }) {
            newInvoices.append(SimulationInvoice(
                id: payrollInvoiceID,
                title: "Rémunération des machinistes",
                counterparty: "Personnel · estimation de jeu",
                direction: payrollNet > 0 ? .receivable : .payable,
                issuedAt: issuedAt,
                dueAt: SimulationInvoiceRules.dueDate(for: issuedAt),
                lineItems: payrollEntries.sorted { $0.occurredAt < $1.occurredAt }.map {
                    SimulationInvoiceLineItem(
                        ledgerEntryID: $0.id,
                        category: $0.category,
                        description: $0.description,
                        amountEuro: $0.amount
                    )
                }
            ))
        }

        let workshopNet = workshopEntries.reduce(into: 0) { $0 += $1.amount }
        let workshopInvoiceID = "invoice-workshop-\(dateKey)"
        if workshopNet != 0,
           !invoices.contains(where: { $0.id == workshopInvoiceID }) {
            newInvoices.append(SimulationInvoice(
                id: workshopInvoiceID,
                title: "Atelier, réparations et pièces",
                counterparty: "Fournisseurs atelier · estimation de jeu",
                direction: workshopNet > 0 ? .receivable : .payable,
                issuedAt: issuedAt,
                dueAt: SimulationInvoiceRules.dueDate(for: issuedAt),
                lineItems: workshopEntries.sorted { $0.occurredAt < $1.occurredAt }.map {
                    SimulationInvoiceLineItem(
                        ledgerEntryID: $0.id,
                        category: $0.category,
                        description: $0.description,
                        amountEuro: $0.amount
                    )
                }
            ))
        }

        guard !newInvoices.isEmpty else { return [] }
        invoices.append(contentsOf: newInvoices)
        session.invoices = invoices

        return newInvoices.map { invoice in
            let event = SimulationEvent(
                sequence: session.nextEventSequence,
                simulatedAt: invoice.dueAt,
                kind: .invoiceSettlementDue(invoiceID: invoice.id)
            )
            session.nextEventSequence &+= 1
            return event
        }
    }

    private static func recordDailyOperationsReport(
        for dateKey: Int,
        contractCompletionRate: Double? = nil,
        contractQualityAdjustmentEuro: Int? = nil,
        in session: inout SimulationSession
    ) {
        var reports = session.dailyOperationsReports ?? []
        guard !reports.contains(where: { $0.dateKey == dateKey }) else { return }
        let events = session.eventHistory.filter {
            GTFSServiceDate.key(for: $0.simulatedAt, timeZone: GTFSServiceDate.parisTimeZone) == dateKey
        }
        let served = events.reduce(into: 0) { count, event in
            if case .busDeparted = event.kind { count += 1 }
        }
        let missed = events.reduce(into: 0) { count, event in
            switch event.kind {
            case .missedServiceDeparture, .routeServiceSuspended:
                count += 1
            default:
                break
            }
        }
        let completed = events.reduce(into: 0) { count, event in
            switch event.kind {
            case .busServiceCompleted, .busServiceCompletedAtClosedStop, .busServiceCompletedAtClosedStopWithPassengerRedirect:
                count += 1
            default:
                break
            }
        }
        let incidents = events.reduce(into: 0) { count, event in
            if case .vehicleBreakdown = event.kind { count += 1 }
        }
        let distance = (session.tripDistanceRecords ?? []).reduce(into: 0.0) { total, record in
            if GTFSServiceDate.key(for: record.occurredAt, timeZone: GTFSServiceDate.parisTimeZone) == dateKey {
                total += record.distanceMeters
            }
        }
        let estimatedStopConnectorDistance = (session.tripDistanceRecords ?? []).reduce(into: 0.0) { total, record in
            guard record.serviceGeometrySource == .stopCoordinateEstimate,
                  GTFSServiceDate.key(for: record.occurredAt, timeZone: GTFSServiceDate.parisTimeZone) == dateKey else { return }
            total += record.distanceMeters
        }
        let temporaryDetourDistance = (session.tripDistanceRecords ?? []).reduce(into: 0.0) { total, record in
            guard record.serviceGeometrySource == .temporaryRouteDetour,
                  GTFSServiceDate.key(for: record.occurredAt, timeZone: GTFSServiceDate.parisTimeZone) == dateKey else { return }
            total += record.distanceMeters
        }
        let purchases = (session.ledgerEntries ?? []).reduce(into: 0) { total, entry in
            if entry.category == "Achat de véhicule",
               entry.amount < 0,
               GTFSServiceDate.key(for: entry.occurredAt, timeZone: GTFSServiceDate.parisTimeZone) == dateKey {
                total += -entry.amount
            }
        }
        let vehicleSaleRevenue = session.ledgerEntries.map { entries in
            entries.reduce(into: 0) { total, entry in
                if entry.category == "Revente de véhicule",
                   entry.amount > 0,
                   GTFSServiceDate.key(for: entry.occurredAt, timeZone: GTFSServiceDate.parisTimeZone) == dateKey {
                    total += entry.amount
                }
            }
        }
        let machinistLaborExpenses = session.ledgerEntries.map { entries in
            entries.reduce(into: 0) { total, entry in
                if entry.category == "Rémunération machinistes",
                   entry.amount < 0,
                   GTFSServiceDate.key(for: entry.occurredAt, timeZone: GTFSServiceDate.parisTimeZone) == dateKey {
                    total += -entry.amount
                }
            }
        }
        let energyExpenses = session.ledgerEntries.map { entries in
            entries.reduce(into: 0) { total, entry in
                if entry.category == "Énergie estimée",
                   entry.amount < 0,
                   GTFSServiceDate.key(for: entry.occurredAt, timeZone: GTFSServiceDate.parisTimeZone) == dateKey {
                    total += -entry.amount
                }
            }
        }
        let repairExpenses = session.ledgerEntries.map { entries in
            entries.reduce(into: 0) { total, entry in
                if (entry.category == "Réparation" || entry.category == "Diagnostic de panne"),
                   entry.amount < 0,
                   GTFSServiceDate.key(for: entry.occurredAt, timeZone: GTFSServiceDate.parisTimeZone) == dateKey {
                    total += -entry.amount
                }
            }
        }
        let serviceRevenue = session.ledgerEntries.map { entries in
            entries.reduce(into: 0) { total, entry in
                if entry.category == "Contribution contractuelle estimée (jeu)"
                    || entry.category == "Recette de service estimée",
                   entry.amount > 0,
                   GTFSServiceDate.key(for: entry.occurredAt, timeZone: GTFSServiceDate.parisTimeZone) == dateKey {
                    total += entry.amount
                }
            }
        }
        let maintenanceExpenses = session.ledgerEntries.map { entries in
            entries.reduce(into: 0) { total, entry in
                if entry.category == "Entretien préventif",
                   entry.amount < 0,
                   GTFSServiceDate.key(for: entry.occurredAt, timeZone: GTFSServiceDate.parisTimeZone) == dateKey {
                    total += -entry.amount
                }
            }
        }
        let passengerExchanges = session.passengerExchangeRecords?.map(\.exchange).filter {
            GTFSServiceDate.key(for: $0.occurredAt, timeZone: GTFSServiceDate.parisTimeZone) == dateKey
        }
        let passengerBoardings = passengerExchanges?.reduce(into: 0) { total, exchange in
            total += exchange.boardedCount
        }
        let strandedPassengerTotal = events.reduce(into: 0) { total, event in
            if case let .busServiceCompletedAtClosedStop(_, _, _, _, _, _, _, strandedCount) = event.kind {
                total += strandedCount
            }
        }
        let passengersLeftBehind: Int?
        if let passengerExchanges {
            passengersLeftBehind = passengerExchanges.reduce(into: strandedPassengerTotal) { total, exchange in
                total += exchange.newlyLeftBehindCount ?? exchange.leftBehindCount
            }
        } else {
            passengersLeftBehind = strandedPassengerTotal > 0 ? strandedPassengerTotal : nil
        }
        let depotSummaries = Self.dailyDepotOperationsSummaries(
            dateKey: dateKey,
            events: events,
            session: session
        )
        reports.append(DailyOperationsReport(
            dateKey: dateKey,
            servedDepartureCount: served,
            missedDepartureCount: missed,
            completedTripCount: completed,
            tracedDistanceMeters: distance,
            recordedPurchaseExpenses: purchases,
            recordedVehicleSaleRevenue: vehicleSaleRevenue,
            machinistLaborExpensesEuro: machinistLaborExpenses,
            estimatedEnergyExpenses: energyExpenses,
            estimatedPassengerBoardings: passengerBoardings,
            estimatedPassengersLeftBehind: passengersLeftBehind,
            incidentCount: incidents,
            interruptedTripCount: incidents,
            repairExpenses: repairExpenses,
            estimatedServiceRevenueEuro: serviceRevenue,
            contractCompletionRate: contractCompletionRate,
            contractQualityAdjustmentEuro: contractQualityAdjustmentEuro,
            preventiveMaintenanceExpenses: maintenanceExpenses,
            closingCashBalance: session.cashBalance,
            estimatedStopConnectorDistanceMeters: estimatedStopConnectorDistance,
            temporaryDetourDistanceMeters: temporaryDetourDistance,
            depotSummaries: depotSummaries
        ))
        reports.sort { $0.dateKey < $1.dateKey }
        session.dailyOperationsReports = reports
    }

    private static func dailyDepotOperationsSummaries(
        dateKey: Int,
        events: [SimulationEvent],
        session: SimulationSession
    ) -> [DailyDepotOperationsSummary] {
        let depotIDs = session.effectiveManagedDepotIDs.sorted()
        guard depotIDs.count > 1 else { return [] }

        let vehicleDepotIDs = Dictionary(
            (session.ownedBuses ?? []).map { ($0.id, $0.depotID) },
            uniquingKeysWith: { first, _ in first }
        )
        var depotsByRoute: [String: Set<String>] = [:]
        for depotID in depotIDs {
            for routeID in session.effectiveOperatedRouteIDs(for: depotID) {
                depotsByRoute[routeID, default: []].insert(depotID)
            }
        }
        func depotForRoute(_ routeID: String) -> String? {
            guard let matches = depotsByRoute[routeID], matches.count == 1 else { return nil }
            return matches.first
        }

        var served: [String: Int] = [:]
        var missed: [String: Int] = [:]
        var completed: [String: Int] = [:]
        var distance: [String: Double] = [:]
        var expenses: [String: Int] = [:]

        for event in events {
            switch event.kind {
            case let .busDeparted(_, vehicleID, _, _, _, _):
                if let depotID = vehicleDepotIDs[vehicleID] { served[depotID, default: 0] += 1 }
            case let .missedServiceDeparture(_, routeID):
                if let depotID = depotForRoute(routeID) { missed[depotID, default: 0] += 1 }
            case let .routeServiceSuspended(_, routeID, _):
                if let depotID = depotForRoute(routeID) { missed[depotID, default: 0] += 1 }
            case let .busServiceCompleted(_, vehicleID, _, _, _, _),
                 let .busServiceCompletedAtClosedStop(_, vehicleID, _, _, _, _, _, _),
                 let .busServiceCompletedAtClosedStopWithPassengerRedirect(_, vehicleID, _, _, _, _, _, _, _, _):
                if let depotID = vehicleDepotIDs[vehicleID] { completed[depotID, default: 0] += 1 }
            default:
                break
            }
        }

        for record in session.tripDistanceRecords ?? [] where GTFSServiceDate.key(
            for: record.occurredAt,
            timeZone: GTFSServiceDate.parisTimeZone
        ) == dateKey {
            if let depotID = vehicleDepotIDs[record.vehicleID] {
                distance[depotID, default: 0] += record.distanceMeters
            }
        }
        for entry in session.ledgerEntries ?? [] where entry.amount < 0
            && GTFSServiceDate.key(for: entry.occurredAt, timeZone: GTFSServiceDate.parisTimeZone) == dateKey {
            if let depotID = entry.depotID, depotIDs.contains(depotID) {
                expenses[depotID, default: 0] += -entry.amount
            }
        }

        return depotIDs.map { depotID in
            DailyDepotOperationsSummary(
                depotID: depotID,
                servedDepartureCount: served[depotID, default: 0],
                missedDepartureCount: missed[depotID, default: 0],
                completedTripCount: completed[depotID, default: 0],
                tracedDistanceMeters: distance[depotID, default: 0],
                recordedDepotExpensesEuro: expenses[depotID, default: 0]
            )
        }
    }

    private static func finalizeMachinistService(for event: SimulationEvent, in session: inout SimulationSession) {
        let vehicleID: String
        let tripID: String
        switch event.kind {
        case let .busServiceCompleted(id, vehicle, _, _, _, _):
            tripID = id
            vehicleID = vehicle
        case let .busDepotReturnArrivedWithMachinist(id, vehicle, _, _, _, _, _):
            tripID = id
            vehicleID = vehicle
        case let .vehicleBreakdown(incident):
            tripID = incident.tripID
            vehicleID = incident.vehicleID
        case let .vehicleRepairCompleted(incidentID):
            guard let incident = session.vehicleIncidents?.first(where: { $0.id == incidentID }) else { return }
            tripID = incident.tripID
            vehicleID = incident.vehicleID
        case let .machinistRelieved(relievedTripID, relievedVehicleID, _, _, _, _):
            tripID = relievedTripID
            vehicleID = relievedVehicleID
        default:
            return
        }

        guard var assignments = session.machinistServiceAssignments else { return }
        let plannedOutgoingAssignmentID = session.plannedMachinistReliefs?.first(where: {
            $0.eventSequence == event.sequence
        })?.outgoingAssignmentID
        guard let assignmentIndex = plannedOutgoingAssignmentID.flatMap({ assignmentID in
            assignments.firstIndex(where: { $0.id == assignmentID })
        }) ?? assignments.lastIndex(where: {
            $0.vehicleID == vehicleID
                && $0.tripID == tripID
                && $0.actualEndAt == nil
                && $0.plannedStartAt <= event.simulatedAt
        }) else { return }
        let assignment = assignments[assignmentIndex]
        assignments[assignmentIndex].actualEndAt = event.simulatedAt
        session.machinistServiceAssignments = assignments

        if let dutyBlockID = assignment.dutyBlockID,
           var dutyBlocks = session.machinistDutyBlocks,
           let dutyBlockIndex = dutyBlocks.firstIndex(where: { $0.id == dutyBlockID }) {
            guard !assignments.contains(where: { $0.dutyBlockID == dutyBlockID && $0.actualEndAt == nil }) else { return }
            let block = dutyBlocks[dutyBlockIndex]
            let priorBlockAssignments = assignments.filter {
                $0.dutyBlockID == dutyBlockID && $0.id != assignment.id
            }
            let previousSettlementAt = block.lastSettledAt
                ?? (block.laborCostEuro == nil ? nil : priorBlockAssignments.compactMap(\.actualEndAt).max())
            let blockEndAt = assignments
                .filter { $0.dutyBlockID == dutyBlockID }
                .compactMap(\.actualEndAt)
                .max() ?? event.simulatedAt
            let presenceDuration = max(0, blockEndAt.timeIntervalSince(block.plannedStartAt))
            let unpaidBreakDuration = (session.machinistBreaks ?? []).reduce(into: 0.0) { duration, scheduledBreak in
                guard scheduledBreak.dutyBlockID == dutyBlockID,
                      scheduledBreak.cancelledAt == nil else { return }
                let overlapStart = max(block.plannedStartAt, scheduledBreak.startsAt)
                let overlapEnd = min(blockEndAt, scheduledBreak.endsAt)
                duration += max(0, overlapEnd.timeIntervalSince(overlapStart))
            }
            let durationHours = max(0, presenceDuration - unpaidBreakDuration) / 3_600
            let hourlyCost = session.machinists?.first(where: { $0.id == block.machinistID })?
                .estimatedLoadedCostPerServiceHourEuro ?? 0
            let laborCost = Int((durationHours * Double(hourlyCost)).rounded())
            let previousLaborCost = previousSettlementAt == nil ? nil : block.laborCostEuro
            let breakHours = unpaidBreakDuration / 3_600
            let blockAssignments = assignments.filter { $0.dutyBlockID == dutyBlockID }
            let courseRouteIDs = Array(Set(blockAssignments
                .filter { $0.routeID != "RETOUR-DEPOT" }
                .map(\.routeID))).sorted().joined(separator: ", ")
            let includesDepotReturn = blockAssignments.contains { $0.routeID == "RETOUR-DEPOT" }
            let routeDescription = [
                courseRouteIDs.isEmpty ? nil : "ligne(s) \(courseRouteIDs)",
                includesDepotReturn ? "retour à vide vers le dépôt" : nil
            ].compactMap { $0 }.joined(separator: " · ")
            if let previousSettlementAt, let previousLaborCost {
                let extensionBreakDuration = (session.machinistBreaks ?? []).reduce(into: 0.0) { duration, scheduledBreak in
                    guard scheduledBreak.dutyBlockID == dutyBlockID,
                          scheduledBreak.cancelledAt == nil else { return }
                    let overlapStart = max(previousSettlementAt, scheduledBreak.startsAt)
                    let overlapEnd = min(blockEndAt, scheduledBreak.endsAt)
                    duration += max(0, overlapEnd.timeIntervalSince(overlapStart))
                }
                let extensionHours = max(
                    0,
                    blockEndAt.timeIntervalSince(previousSettlementAt) - extensionBreakDuration
                ) / 3_600
                let incrementalLaborCost = max(0, laborCost - previousLaborCost)
                dutyBlocks[dutyBlockIndex].actualEndAt = blockEndAt
                dutyBlocks[dutyBlockIndex].laborCostEuro = laborCost
                dutyBlocks[dutyBlockIndex].lastSettledAt = blockEndAt
                session.machinistDutyBlocks = dutyBlocks
                guard incrementalLaborCost > 0 else { return }
                let extensionRoutes = routeDescription.isEmpty
                    ? "prolongation du bloc"
                    : "prolongation du bloc · \(routeDescription)"
                Self.recordMachinistPayroll(
                    id: "machinist-duty-extension-\(dutyBlockID)-\(assignment.id)",
                    machinistID: block.machinistID,
                    kind: .service,
                    machinistName: session.machinists?.first(where: { $0.id == block.machinistID })?.displayName ?? "Machiniste",
                    routeDescription: extensionRoutes,
                    durationText: extensionHours.formatted(.number.precision(.fractionLength(1))),
                    workHours: extensionHours,
                    laborCost: incrementalLaborCost,
                    occurredAt: blockEndAt,
                    session: &session,
                    workDescription: "de prolongation du bloc, incluant le retour à vide"
                )
                return
            }

            let workDescription: String
            if includesDepotReturn {
                workDescription = breakHours > 0
                    ? "de service, battements et retour à vide · pause non rémunérée de \(breakHours.formatted(.number.precision(.fractionLength(1)))) h déduite"
                    : "de service, battements et retour à vide"
            } else {
                workDescription = breakHours > 0
                    ? "de service, battements et attente · pause non rémunérée de \(breakHours.formatted(.number.precision(.fractionLength(1)))) h déduite"
                    : "de service, battements et attente"
            }
            dutyBlocks[dutyBlockIndex].actualEndAt = blockEndAt
            dutyBlocks[dutyBlockIndex].laborCostEuro = laborCost
            dutyBlocks[dutyBlockIndex].lastSettledAt = blockEndAt
            session.machinistDutyBlocks = dutyBlocks

            guard laborCost > 0 else { return }
            let durationText = durationHours.formatted(.number.precision(.fractionLength(1)))
            Self.recordMachinistPayroll(
                id: "machinist-duty-\(dutyBlockID)",
                machinistID: block.machinistID,
                kind: .service,
                machinistName: session.machinists?.first(where: { $0.id == block.machinistID })?.displayName ?? "Machiniste",
                routeDescription: "\(blockAssignments.count) mission(s) · \(routeDescription.isEmpty ? "service" : routeDescription)",
                durationText: durationText,
                workHours: durationHours,
                laborCost: laborCost,
                occurredAt: blockEndAt,
                session: &session,
                workDescription: workDescription
            )
            return
        }

        let durationHours = max(0, event.simulatedAt.timeIntervalSince(assignment.plannedStartAt)) / 3_600
        let hourlyCost = session.machinists?.first(where: { $0.id == assignment.machinistID })?
            .estimatedLoadedCostPerServiceHourEuro ?? 0
        let laborCost = Int((durationHours * Double(hourlyCost)).rounded())
        let routeDescription: String
        if case .vehicleBreakdown = event.kind {
            routeDescription = "ligne \(assignment.routeID) · course interrompue par panne"
        } else if case let .machinistRelieved(_, _, _, _, _, stopName) = event.kind {
            routeDescription = "ligne \(assignment.routeID) · relève à \(stopName)"
        } else {
            routeDescription = "ligne \(assignment.routeID)"
        }
        assignments[assignmentIndex].laborCostEuro = laborCost
        session.machinistServiceAssignments = assignments
        guard laborCost > 0 else { return }
        Self.recordMachinistPayroll(
            id: "machinist-\(assignment.id)",
            machinistID: assignment.machinistID,
            kind: .service,
            machinistName: session.machinists?.first(where: { $0.id == assignment.machinistID })?.displayName ?? "Machiniste",
            routeDescription: routeDescription,
            durationText: durationHours.formatted(.number.precision(.fractionLength(1))),
            workHours: durationHours,
            laborCost: laborCost,
            occurredAt: event.simulatedAt,
            session: &session
        )
    }

    private static func recordMachinistPayroll(
        id: String,
        machinistID: String,
        kind: MachinistPayrollKind,
        machinistName: String,
        routeDescription: String,
        durationText: String,
        workHours: Double,
        laborCost: Int,
        occurredAt: Date,
        session: inout SimulationSession,
        workDescription: String = "de service, battement et attente"
    ) {
        guard laborCost >= 0, workHours.isFinite, workHours >= 0 else { return }
        var payrollRecords = session.machinistPayrollRecords ?? []
        guard !payrollRecords.contains(where: { $0.id == id }) else { return }
        let details = "\(routeDescription) · \(durationText) h \(workDescription)"
        payrollRecords.append(MachinistPayrollRecord(
            id: id,
            machinistID: machinistID,
            occurredAt: occurredAt,
            kind: kind,
            workHours: workHours,
            amountEuro: laborCost,
            details: details
        ))
        session.machinistPayrollRecords = payrollRecords
        guard laborCost > 0 else { return }
        var entries = session.ledgerEntries ?? []
        entries.append(SimulationLedgerEntry(
            id: id,
            occurredAt: occurredAt,
            category: "Rémunération machinistes",
            description: "\(machinistName) · \(details)",
            amount: -laborCost,
            nature: .operating,
            cashDeltaEuro: 0
        ))
        session.ledgerEntries = entries
    }

    private static func machinistBreakWindows(
        machinistID: String,
        simulatedAt: Date,
        assignments: [MachinistServiceAssignment],
        dutyBlocks: [MachinistDutyBlock],
        breaks: [MachinistBreak],
        absences: [MachinistAbsence],
        trainings: [MachinistTrainingRecord]
    ) -> [MachinistBreakWindow] {
        let activeBreaks = breaks.filter { $0.machinistID == machinistID && $0.cancelledAt == nil }
        let activeAbsences = absences.filter { $0.machinistID == machinistID }
        let activeTrainings = trainings.filter { $0.machinistID == machinistID && $0.cancelledAt == nil }
        var windows: [MachinistBreakWindow] = []

        for block in dutyBlocks where block.machinistID == machinistID && block.actualEndAt == nil {
            let blockAssignments = assignments
                .filter { $0.dutyBlockID == block.id }
                .sorted { $0.plannedStartAt < $1.plannedStartAt }
            guard blockAssignments.count > 1 else { continue }
            for index in 1..<blockAssignments.count {
                let previous = blockAssignments[index - 1]
                let following = blockAssignments[index]
                let startsAt = max(previous.actualEndAt ?? previous.plannedEndAt, simulatedAt)
                let endsAt = startsAt.addingTimeInterval(MachinistWorkRules.scheduledBreakDuration)
                guard startsAt < following.plannedStartAt,
                      endsAt <= following.plannedStartAt else { continue }
                guard !activeBreaks.contains(where: {
                    $0.dutyBlockID == block.id && Self.periodsOverlap(startsAt, endsAt, $0.startsAt, $0.endsAt)
                }),
                !activeAbsences.contains(where: {
                    Self.periodsOverlap(startsAt, endsAt, $0.startsAt, $0.endsAt)
                }),
                !activeTrainings.contains(where: {
                    Self.periodsOverlap(startsAt, endsAt, $0.startsAt, $0.endsAt)
                }) else { continue }

                windows.append(MachinistBreakWindow(
                    id: "\(block.id)|\(previous.id)|\(following.id)",
                    dutyBlockID: block.id,
                    startsAt: startsAt,
                    endsAt: endsAt,
                    nextCourseStartsAt: following.plannedStartAt
                ))
            }
        }
        return windows.sorted { $0.startsAt < $1.startsAt }
    }

    private static func machinistDepotReturnAssignmentPlan(
        vehicleID: String,
        plan: VehicleDepotReturnPlan,
        session: SimulationSession
    ) -> MachinistDepotReturnAssignmentPlan? {
        guard let bus = session.ownedBuses?.first(where: { $0.id == vehicleID }),
              bus.status == .atStop,
              Self.isValid(plan, for: bus, in: session) else { return nil }
        let startsAt = session.simulatedAt
        let endsAt = startsAt.addingTimeInterval(plan.expectedTravelSeconds)
        guard plan.expectedTravelSeconds.isFinite,
              plan.expectedTravelSeconds > 0,
              endsAt >= startsAt else { return nil }

        let assignments = session.machinistServiceAssignments ?? []
        let previousCourse = assignments
            .filter {
                $0.vehicleID == vehicleID
                    && $0.routeID != "RETOUR-DEPOT"
                    && $0.actualEndAt != nil
                    && ($0.actualEndAt ?? .distantFuture) <= startsAt
            }
            .max(by: { ($0.actualEndAt ?? .distantPast) < ($1.actualEndAt ?? .distantPast) })
        guard let previousCourse,
              let machinist = session.machinists?.first(where: { $0.id == previousCourse.machinistID }),
              machinist.hiredAt <= startsAt else { return nil }

        let vehicleClass = VehicleMarketCatalog.model(id: bus.modelID)?.vehicleClass ?? .standard
        guard machinist.qualification.canDrive(vehicleClass) else { return nil }
        let dutyBlocks = session.machinistDutyBlocks ?? []
        let dutyBlockPlan = Self.machinistDutyBlockAssignmentPlan(
            machinist.id,
            from: startsAt,
            to: endsAt,
            assignments: assignments,
            dutyBlocks: dutyBlocks,
            breaks: session.machinistBreaks ?? [],
            absences: session.machinistAbsences ?? [],
            trainings: session.machinistTrainings ?? [],
            reopeningDutyBlockID: previousCourse.dutyBlockID
        )
        guard let dutyBlockPlan else { return nil }

        let hourlyCost = machinist.estimatedLoadedCostPerServiceHourEuro
        let estimatedLaborCost: Int
        if let joinedID = dutyBlockPlan.joiningDutyBlockID,
           let block = dutyBlocks.first(where: { $0.id == joinedID }) {
            let blockAssignments = assignments.filter { $0.dutyBlockID == joinedID }
            let baselineEnd = blockAssignments
                .map { $0.actualEndAt ?? $0.plannedEndAt }
                .max() ?? startsAt
            let projectedEnd = max(baselineEnd, endsAt)
            let unpaidBreaks = (session.machinistBreaks ?? []).filter {
                $0.dutyBlockID == joinedID && $0.cancelledAt == nil
            }
            func laborCost(until end: Date) -> Int {
                let presenceSeconds: TimeInterval = max(0.0, end.timeIntervalSince(block.plannedStartAt))
                let unpaid = unpaidBreaks.reduce(into: 0.0) { total, scheduledBreak in
                    let overlapStart = max(block.plannedStartAt, scheduledBreak.startsAt)
                    let overlapEnd = min(end, scheduledBreak.endsAt)
                    total += max(0, overlapEnd.timeIntervalSince(overlapStart))
                }
                return Int((max(0.0, presenceSeconds - unpaid) / 3_600 * Double(hourlyCost)).rounded())
            }
            let baselineCost = block.lastSettledAt != nil
                ? (block.laborCostEuro ?? laborCost(until: baselineEnd))
                : laborCost(until: baselineEnd)
            estimatedLaborCost = max(0, laborCost(until: projectedEnd) - baselineCost)
        } else {
            let durationHours = max(0, endsAt.timeIntervalSince(startsAt)) / 3_600
            estimatedLaborCost = Int((durationHours * Double(hourlyCost)).rounded())
        }

        return MachinistDepotReturnAssignmentPlan(
            machinist: machinist,
            previousCourse: previousCourse,
            dutyBlockPlan: dutyBlockPlan,
            estimatedLaborCostEuro: estimatedLaborCost
        )
    }

    private static func canCorrectMachinistDutyBlock(
        _ block: MachinistDutyBlock,
        to candidate: Machinist,
        in session: SimulationSession
    ) -> Bool {
        guard block.machinistID != candidate.id,
              let settledAt = block.lastSettledAt,
              let actualEndAt = block.actualEndAt,
              block.laborCostEuro != nil,
              actualEndAt <= session.simulatedAt,
              settledAt <= session.simulatedAt,
              let previousMachinist = session.machinists?.first(where: { $0.id == block.machinistID }),
              (previousMachinist.depotID ?? session.depotID) == (candidate.depotID ?? session.depotID),
              candidate.hiredAt <= block.plannedStartAt else { return false }

        let assignments = session.machinistServiceAssignments ?? []
        let blockAssignments = assignments.filter { $0.dutyBlockID == block.id }
        guard !blockAssignments.isEmpty,
              blockAssignments.allSatisfy({ assignment in
                  guard let actualEndAt = assignment.actualEndAt else { return false }
                  return actualEndAt <= session.simulatedAt
              }) else {
            return false
        }
        let vehicleClasses = blockAssignments.compactMap { assignment -> BusVehicleClass? in
            let modelID = assignment.vehicleModelID
                ?? session.ownedBuses?.first(where: { $0.id == assignment.vehicleID })?.modelID
            guard let modelID else { return nil }
            return VehicleMarketCatalog.model(id: modelID)?.vehicleClass
        }
        guard vehicleClasses.count == blockAssignments.count,
              vehicleClasses.allSatisfy(candidate.qualification.canDrive) else { return false }

        let remainingAssignments = assignments.filter { $0.dutyBlockID != block.id }
        let remainingBlocks = (session.machinistDutyBlocks ?? []).filter { $0.id != block.id }
        let remainingBreaks = (session.machinistBreaks ?? []).filter { $0.dutyBlockID != block.id }
        guard let plan = machinistDutyBlockAssignmentPlan(
            candidate.id,
            from: block.plannedStartAt,
            to: actualEndAt,
            assignments: remainingAssignments,
            dutyBlocks: remainingBlocks,
            breaks: remainingBreaks,
            absences: session.machinistAbsences ?? [],
            trainings: session.machinistTrainings ?? []
        ) else { return false }
        return plan.joiningDutyBlockID == nil
    }

    private static func machinistDutyBlockAssignmentPlan(
        _ machinistID: String,
        from start: Date,
        to end: Date,
        assignments: [MachinistServiceAssignment],
        dutyBlocks: [MachinistDutyBlock],
        breaks: [MachinistBreak],
        absences: [MachinistAbsence],
        trainings: [MachinistTrainingRecord],
        reopeningDutyBlockID: String? = nil,
        allowReopeningSettledBlocks: Bool = false
    ) -> MachinistDutyBlockAssignmentPlan? {
        guard start <= end,
              !breaks.contains(where: {
                  $0.machinistID == machinistID
                      && $0.cancelledAt == nil
                      && Self.periodsOverlap(start, end, $0.startsAt, $0.endsAt)
              }),
              !absences.contains(where: {
                  $0.machinistID == machinistID && Self.periodsOverlap(start, end, $0.startsAt, $0.endsAt)
              }),
              !trainings.contains(where: { training in
                  training.machinistID == machinistID
                      && training.cancelledAt == nil
                      && !Self.hasMinimumRest(
                          between: start,
                          and: end,
                          and: training.startsAt,
                          training.endsAt
                      )
              }) else { return nil }

        let machinistAssignments = assignments.filter { $0.machinistID == machinistID }
        let blockIDs = Set(dutyBlocks.filter { $0.machinistID == machinistID }.map(\.id))
        for assignment in machinistAssignments {
            let existingEnd = assignment.actualEndAt ?? assignment.plannedEndAt
            if Self.periodsOverlap(start, end, assignment.plannedStartAt, existingEnd) { return nil }
        }

        let machinistBlocks = dutyBlocks.filter { block in
            block.machinistID == machinistID
                && machinistAssignments.contains(where: { $0.dutyBlockID == block.id })
        }
        let joinableBlocks = machinistBlocks.compactMap { block -> String? in
            let isReopeningSettledBlock = (block.id == reopeningDutyBlockID || allowReopeningSettledBlocks)
                && block.actualEndAt != nil
                && block.laborCostEuro != nil
            guard block.actualEndAt == nil || isReopeningSettledBlock else { return nil }
            let blockAssignments = machinistAssignments.filter { $0.dutyBlockID == block.id }
            let intervals = (blockAssignments.map { ($0.plannedStartAt, $0.actualEndAt ?? $0.plannedEndAt) } + [(start, end)])
                .sorted { $0.0 < $1.0 }
            guard let firstStart = intervals.first?.0,
                  let lastEnd = intervals.map({ $0.1 }).max(),
                  lastEnd.timeIntervalSince(firstStart) <= MachinistWorkRules.maximumServiceBlockDuration else {
                return nil
            }
            for index in intervals.indices.dropFirst() {
                let previousEnd = intervals[index - 1].1
                let nextStart = intervals[index].0
                guard nextStart >= previousEnd,
                      nextStart.timeIntervalSince(previousEnd) <= MachinistWorkRules.maximumGapWithinServiceBlock else {
                    return nil
                }
            }
            guard !absences.contains(where: {
                $0.machinistID == machinistID && Self.periodsOverlap(firstStart, lastEnd, $0.startsAt, $0.endsAt)
            }) else { return nil }
            return block.id
        }
        guard joinableBlocks.count <= 1 else { return nil }

        let joiningBlockID = joinableBlocks.first
        let proposedStart: Date
        let proposedEnd: Date
        if let joiningBlockID,
           let block = machinistBlocks.first(where: { $0.id == joiningBlockID }) {
            proposedStart = min(start, block.plannedStartAt)
            proposedEnd = max(end, block.actualEndAt ?? block.plannedEndAt)
        } else {
            proposedStart = start
            proposedEnd = end
            guard end.timeIntervalSince(start) <= MachinistWorkRules.maximumServiceBlockDuration else { return nil }
        }

        let unlinkedAssignments = machinistAssignments.filter {
            $0.dutyBlockID == nil || !blockIDs.contains($0.dutyBlockID ?? "")
        }
        for block in machinistBlocks where block.id != joiningBlockID {
            let blockEnd = block.actualEndAt ?? block.plannedEndAt
            guard Self.hasMinimumRest(
                between: proposedStart,
                and: proposedEnd,
                and: block.plannedStartAt,
                blockEnd
            ) else { return nil }
        }
        for assignment in unlinkedAssignments {
            let assignmentEnd = assignment.actualEndAt ?? assignment.plannedEndAt
            guard Self.hasMinimumRest(
                between: proposedStart,
                and: proposedEnd,
                and: assignment.plannedStartAt,
                assignmentEnd
            ) else { return nil }
        }
        return MachinistDutyBlockAssignmentPlan(joiningDutyBlockID: joiningBlockID)
    }

    private static func reopenAndExtendMachinistDutyBlock(
        _ block: inout MachinistDutyBlock,
        from start: Date,
        to end: Date
    ) {
        let priorEnd = block.actualEndAt ?? block.plannedEndAt
        block.plannedStartAt = min(block.plannedStartAt, start)
        block.plannedEndAt = max(priorEnd, end)
        block.actualEndAt = nil
    }

    private static func hasMinimumRest(
        between firstStart: Date,
        and firstEnd: Date,
        and secondStart: Date,
        _ secondEnd: Date
    ) -> Bool {
        if firstStart >= secondEnd {
            return firstStart.timeIntervalSince(secondEnd) >= MachinistWorkRules.minimumRestBetweenDutyBlocks
        }
        if firstEnd <= secondStart {
            return secondStart.timeIntervalSince(firstEnd) >= MachinistWorkRules.minimumRestBetweenDutyBlocks
        }
        return false
    }

    private static func periodsOverlap(_ firstStart: Date, _ firstEnd: Date, _ secondStart: Date, _ secondEnd: Date) -> Bool {
        firstStart < secondEnd && firstEnd > secondStart
    }

    private static func validRouteDetourCoordinates(
        _ coordinates: [BusMovementCoordinate],
        from start: ScheduledTripStopVisit,
        to end: ScheduledTripStopVisit
    ) -> Bool {
        guard coordinates.count >= 2,
              coordinates.allSatisfy({ coordinate in
                  coordinate.latitude.isFinite
                      && coordinate.longitude.isFinite
                      && (-90...90).contains(coordinate.latitude)
                      && (-180...180).contains(coordinate.longitude)
              }),
              let first = coordinates.first,
              let last = coordinates.last else { return false }
        return abs(first.latitude - start.latitude) <= 0.00001
            && abs(first.longitude - start.longitude) <= 0.00001
            && abs(last.latitude - end.latitude) <= 0.00001
            && abs(last.longitude - end.longitude) <= 0.00001
    }

    private static func validStopClosureReplacementGuide(
        _ guide: StopClosureReplacementGuide,
        for closedStopID: String
    ) -> Bool {
        let closedStopID = closedStopID.trimmingCharacters(in: .whitespacesAndNewlines)
        let replacementStopID = guide.replacementStopID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !closedStopID.isEmpty,
              !replacementStopID.isEmpty,
              replacementStopID != closedStopID,
              !guide.replacementStopName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !guide.routeID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              guide.walkingDistanceMeters.isFinite,
              guide.walkingDistanceMeters > 0,
              guide.expectedWalkingSeconds.isFinite,
              guide.expectedWalkingSeconds > 0,
              guide.accessibilityEvidence == .unknown,
              guide.walkingCoordinates.count >= 2,
              guide.walkingCoordinates.allSatisfy({ coordinate in
                  coordinate.latitude.isFinite
                      && coordinate.longitude.isFinite
                      && (-90...90).contains(coordinate.latitude)
                      && (-180...180).contains(coordinate.longitude)
              }),
              zip(guide.walkingCoordinates, guide.walkingCoordinates.dropFirst()).contains(where: { start, end in
                  start.latitude != end.latitude || start.longitude != end.longitude
              }),
              let first = guide.walkingCoordinates.first,
              let last = guide.walkingCoordinates.last else { return false }
        return abs(first.latitude - guide.closedStopLatitude) <= 0.00001
            && abs(first.longitude - guide.closedStopLongitude) <= 0.00001
            && abs(last.latitude - guide.latitude) <= 0.00001
            && abs(last.longitude - guide.longitude) <= 0.00001
            && guide.closedStopLatitude.isFinite
            && guide.closedStopLongitude.isFinite
            && (-90...90).contains(guide.closedStopLatitude)
            && (-180...180).contains(guide.closedStopLongitude)
            && guide.latitude.isFinite
            && guide.longitude.isFinite
            && (-90...90).contains(guide.latitude)
            && (-180...180).contains(guide.longitude)
    }

    static func replanActiveDispatchedTrips(in session: inout SimulationSession) -> Bool {
        guard var plans = session.dispatchedTripRoutePlans, !plans.isEmpty else { return true }
        var pendingEvents = session.pendingEvents
        var assignments = session.machinistServiceAssignments ?? []
        var buses = session.ownedBuses ?? []
        var dutyBlocks = session.machinistDutyBlocks ?? []
        var incidents = session.vehicleIncidents ?? []
        var eventHistory = session.eventHistory
        var nextEventSequence = session.nextEventSequence

        for planIndex in plans.indices {
            var plan = plans[planIndex]
            let applicableDetours = (session.routeDetours ?? []).filter { $0.routeID == plan.routeID }
            let application = RouteDetourSchedulePlanner.applying(
                detours: applicableDetours,
                to: plan.stopVisits,
                alreadyAppliedDetourIDs: plan.appliedDetourIDs
            )
            guard application.visits != plan.stopVisits else {
                plans[planIndex].appliedDetourIDs = application.appliedDetourIDs
                continue
            }
            guard let assignmentIndex = assignments.firstIndex(where: {
                $0.id == plan.tripKey && $0.actualEndAt == nil
            }),
            let busIndex = buses.firstIndex(where: {
                $0.id == plan.vehicleID && $0.reservedTripKey == plan.tripKey
            }),
            let newLastStop = application.visits.last,
            newLastStop.scheduledAt >= session.simulatedAt else {
                return false
            }

            let assignment = assignments[assignmentIndex]
            let activeReliefs = (session.plannedMachinistReliefs ?? []).filter {
                $0.outgoingAssignmentID == plan.tripKey && $0.cancelledAt == nil
            }
            let relatedAssignmentIDs = Set([plan.tripKey] + activeReliefs.map(\.incomingAssignmentID))
            let newServiceEndAt = newLastStop.scheduledAt
            guard Self.propagateDetourDelay(
                from: assignment,
                newEndAt: newServiceEndAt,
                simulatedAt: session.simulatedAt,
                plans: &plans,
                pendingEvents: &pendingEvents,
                assignments: &assignments,
                buses: &buses,
                dutyBlocks: &dutyBlocks,
                reliefs: session.plannedMachinistReliefs ?? [],
                incidents: &incidents,
                eventHistory: &eventHistory,
                nextEventSequence: &nextEventSequence
            ) else { return false }
            let reservationsConflict = assignments.enumerated().contains { index, other in
                guard index != assignmentIndex,
                      !relatedAssignmentIDs.contains(other.id),
                      other.actualEndAt == nil,
                      other.vehicleID == plan.vehicleID || other.machinistID == plan.machinistID else {
                    return false
                }
                let otherEnd = other.actualEndAt ?? other.plannedEndAt
                return Self.periodsOverlap(
                    assignment.plannedStartAt,
                    newServiceEndAt,
                    other.plannedStartAt,
                    otherEnd
                )
            }
            guard !reservationsConflict,
                  Self.machinistDutyBlockAssignmentPlan(
                      plan.machinistID,
                      from: assignment.plannedStartAt,
                      to: newServiceEndAt,
                      assignments: assignments.filter { !relatedAssignmentIDs.contains($0.id) },
                      dutyBlocks: dutyBlocks,
                      breaks: session.machinistBreaks ?? [],
                      absences: session.machinistAbsences ?? [],
                      trainings: session.machinistTrainings ?? [],
                      allowReopeningSettledBlocks: true
                  ) != nil,
                  Self.hasBatteryReserveAfterDetour(
                      from: plan.stopVisits,
                      to: application.visits,
                      bus: buses[busIndex]
                  ) else {
                return false
            }

            let newDemands = Self.estimatedPassengerDemands(
                tripID: plan.tripID,
                routeID: plan.routeID,
                vehicleID: plan.vehicleID,
                serviceDateKey: plan.serviceDateKey,
                stopVisits: application.visits,
                capacity: plan.passengerCapacity,
                capacityIsEstimated: plan.capacityIsEstimated,
                randomSeed: session.randomSeed
            )
            let newDemandsBySequence = Dictionary(uniqueKeysWithValues: zip(application.visits, newDemands).map {
                ($0.0.stopSequence, $0.1)
            })

            for visit in application.visits.dropFirst() {
                guard let sequence = plan.stopEventSequencesByStopSequence[visit.stopSequence],
                      let eventIndex = pendingEvents.firstIndex(where: { $0.sequence == sequence }),
                      case .busAtStop = pendingEvents[eventIndex].kind else { continue }
                guard visit.scheduledAt >= session.simulatedAt else { return false }
                pendingEvents[eventIndex] = SimulationEvent(
                    sequence: sequence,
                    simulatedAt: visit.scheduledAt,
                    kind: .busAtStop(
                        tripID: plan.tripID,
                        vehicleID: plan.vehicleID,
                        stopID: visit.stopID,
                        stopName: visit.stopName,
                        stopSequence: visit.stopSequence,
                        latitude: visit.latitude,
                        longitude: visit.longitude
                    )
                )
            }

            for (stopSequence, sequence) in plan.demandEventSequencesByStopSequence {
                guard let demand = newDemandsBySequence[stopSequence],
                      let eventIndex = pendingEvents.firstIndex(where: { $0.sequence == sequence }),
                      case .passengerDemand = pendingEvents[eventIndex].kind else { continue }
                guard demand.occurredAt >= session.simulatedAt else { return false }
                pendingEvents[eventIndex] = SimulationEvent(
                    sequence: sequence,
                    simulatedAt: demand.occurredAt,
                    kind: .passengerDemand(demand)
                )
            }

            for (fromStopSequence, sequence) in Array(plan.movementEventSequencesByFromStopSequence) {
                guard let startIndex = application.visits.firstIndex(where: { $0.stopSequence == fromStopSequence }),
                      startIndex + 1 < application.visits.count else { continue }
                let leg = Self.movementLeg(from: application.visits[startIndex], to: application.visits[startIndex + 1])
                guard let eventIndex = pendingEvents.firstIndex(where: { $0.sequence == sequence }) else { continue }
                guard let leg else {
                    pendingEvents.remove(at: eventIndex)
                    plan.movementEventSequencesByFromStopSequence.removeValue(forKey: fromStopSequence)
                    continue
                }
                guard leg.startsAt >= session.simulatedAt else { return false }
                pendingEvents[eventIndex] = SimulationEvent(
                    sequence: sequence,
                    simulatedAt: leg.startsAt,
                    kind: .busMovementStarted(vehicleID: plan.vehicleID, leg: leg)
                )
            }

            for startIndex in application.visits.indices.dropLast() {
                let startVisit = application.visits[startIndex]
                guard plan.movementEventSequencesByFromStopSequence[startVisit.stopSequence] == nil,
                      let leg = Self.movementLeg(from: startVisit, to: application.visits[startIndex + 1]),
                      leg.startsAt >= session.simulatedAt else { continue }
                let sequence = nextEventSequence
                nextEventSequence &+= 1
                plan.movementEventSequencesByFromStopSequence[startVisit.stopSequence] = sequence
                pendingEvents.append(SimulationEvent(
                    sequence: sequence,
                    simulatedAt: leg.startsAt,
                    kind: .busMovementStarted(vehicleID: plan.vehicleID, leg: leg)
                ))
            }

            if let sequence = plan.completionEventSequence,
               let eventIndex = pendingEvents.firstIndex(where: { $0.sequence == sequence }),
               case .busServiceCompleted = pendingEvents[eventIndex].kind {
                guard newLastStop.scheduledAt >= session.simulatedAt else { return false }
                pendingEvents[eventIndex] = SimulationEvent(
                    sequence: sequence,
                    simulatedAt: newLastStop.scheduledAt,
                    kind: .busServiceCompleted(
                        tripID: plan.tripID,
                        vehicleID: plan.vehicleID,
                        stopID: newLastStop.stopID,
                        stopName: newLastStop.stopName,
                        latitude: newLastStop.latitude,
                        longitude: newLastStop.longitude
                    )
                )
            }

            for relief in activeReliefs {
                guard let visit = application.visits.first(where: { $0.stopSequence == relief.stopSequence }),
                      let eventIndex = pendingEvents.firstIndex(where: { $0.sequence == relief.eventSequence }),
                      case let .machinistRelieved(tripID, vehicleID, routeID, outgoingName, incomingName, _) = pendingEvents[eventIndex].kind else {
                    continue
                }
                guard visit.scheduledAt >= session.simulatedAt else { return false }
                pendingEvents[eventIndex] = SimulationEvent(
                    sequence: relief.eventSequence,
                    simulatedAt: visit.scheduledAt,
                    kind: .machinistRelieved(
                        tripID: tripID,
                        vehicleID: vehicleID,
                        routeID: routeID,
                        outgoingMachinistName: outgoingName,
                        incomingMachinistName: incomingName,
                        stopName: visit.stopName
                    )
                )
            }

            for eventIndex in pendingEvents.indices {
                guard case .vehicleBreakdown(var incident) = pendingEvents[eventIndex].kind,
                      incident.tripID == plan.tripID,
                      incident.vehicleID == plan.vehicleID,
                      let oldVisit = plan.stopVisits.first(where: { $0.stopSequence == incident.stopSequence }),
                      let newVisit = application.visits.first(where: { $0.stopSequence == incident.stopSequence }) else {
                    continue
                }
                let scheduleShift = newVisit.scheduledAt.timeIntervalSince(oldVisit.scheduledAt)
                incident.occurredAt = incident.occurredAt.addingTimeInterval(scheduleShift)
                incident.repairCompletedAt = incident.repairCompletedAt.addingTimeInterval(scheduleShift)
                if let incidentIndex = incidents.firstIndex(where: { $0.id == incident.id }) {
                    incidents[incidentIndex].occurredAt = incident.occurredAt
                    incidents[incidentIndex].repairCompletedAt = incident.repairCompletedAt
                }
                pendingEvents[eventIndex] = SimulationEvent(
                    sequence: pendingEvents[eventIndex].sequence,
                    simulatedAt: incident.occurredAt,
                    kind: .vehicleBreakdown(incident)
                )
            }

            let previousEndAt = assignment.plannedEndAt
            let previousDistance = Self.scheduledServiceDistance(plan.stopVisits)
            let updatedDistance = Self.scheduledServiceDistance(application.visits)
            for relatedIndex in assignments.indices where relatedAssignmentIDs.contains(assignments[relatedIndex].id) {
                assignments[relatedIndex].plannedEndAt = newServiceEndAt
            }
            buses[busIndex].reservedUntil = assignments
                .filter { $0.vehicleID == plan.vehicleID && $0.actualEndAt == nil }
                .map(\.plannedEndAt)
                .max() ?? newServiceEndAt
            let affectedDutyBlockIDs = Set(assignments.filter {
                relatedAssignmentIDs.contains($0.id)
            }.compactMap(\.dutyBlockID))
            for dutyBlockIndex in dutyBlocks.indices where affectedDutyBlockIDs.contains(dutyBlocks[dutyBlockIndex].id) {
                let dutyBlockID = dutyBlocks[dutyBlockIndex].id
                let blockEnd = assignments
                    .filter { $0.dutyBlockID == dutyBlockID }
                    .map { $0.actualEndAt ?? $0.plannedEndAt }
                    .max() ?? newServiceEndAt
                dutyBlocks[dutyBlockIndex].plannedEndAt = blockEnd
            }
            eventHistory.append(SimulationEvent(
                sequence: nextEventSequence,
                simulatedAt: session.simulatedAt,
                kind: .routeDetourReplanned(
                    tripID: plan.tripID,
                    routeID: plan.routeID,
                    addedDelaySeconds: max(0, newServiceEndAt.timeIntervalSince(previousEndAt)),
                    addedDistanceMeters: max(0, updatedDistance - previousDistance)
                )
            ))
            nextEventSequence &+= 1
            plan.stopVisits = application.visits
            plan.appliedDetourIDs = application.appliedDetourIDs
            plans[planIndex] = plan
        }

        session.dispatchedTripRoutePlans = plans
        session.pendingEvents = pendingEvents
        session.nextEventSequence = nextEventSequence
        session.machinistServiceAssignments = assignments
        session.ownedBuses = buses
        session.machinistDutyBlocks = dutyBlocks
        session.eventHistory = eventHistory
        if !incidents.isEmpty { session.vehicleIncidents = incidents }
        return true
    }

    private static func propagateDetourDelay(
        from sourceAssignment: MachinistServiceAssignment,
        newEndAt: Date,
        simulatedAt: Date,
        plans: inout [DispatchedTripRoutePlan],
        pendingEvents: inout [SimulationEvent],
        assignments: inout [MachinistServiceAssignment],
        buses: inout [PurchasedBus],
        dutyBlocks: inout [MachinistDutyBlock],
        reliefs: [MachinistReliefPlan],
        incidents: inout [VehicleIncident],
        eventHistory: inout [SimulationEvent],
        nextEventSequence: inout UInt64
    ) -> Bool {
        let sourceDelay = newEndAt.timeIntervalSince(sourceAssignment.plannedEndAt)
        guard sourceDelay.isFinite, sourceDelay >= 0 else { return false }
        guard sourceDelay > 0 else { return true }

        let originalAssignments = assignments
        guard let sourceIndex = assignments.firstIndex(where: { $0.id == sourceAssignment.id }) else { return false }
        assignments[sourceIndex].plannedEndAt = newEndAt
        var totalShiftByAssignmentID: [String: TimeInterval] = [:]
        var queue = [sourceAssignment.id]
        var queuedIDs: Set<String> = [sourceAssignment.id]

        while !queue.isEmpty {
            let parentID = queue.removeFirst()
            queuedIDs.remove(parentID)
            guard let originalParent = originalAssignments.first(where: { $0.id == parentID }),
                  let parentIndex = assignments.firstIndex(where: { $0.id == parentID }) else {
                return false
            }
            let parent = assignments[parentIndex]
            let parentDelay = max(0, parent.plannedEndAt.timeIntervalSince(originalParent.plannedEndAt))
            guard parentDelay > 0 else { continue }

            for originalChild in originalAssignments where originalChild.id != parentID {
                guard originalChild.actualEndAt == nil,
                      originalChild.plannedStartAt >= originalParent.plannedEndAt,
                      parent.plannedEndAt > originalChild.plannedStartAt,
                      originalChild.vehicleID == originalParent.vehicleID
                          || originalChild.machinistID == originalParent.machinistID else {
                    continue
                }
                let existingShift = totalShiftByAssignmentID[originalChild.id] ?? 0
                let originalGap = max(0, originalChild.plannedStartAt.timeIntervalSince(originalParent.plannedEndAt))
                let desiredStart = parent.plannedEndAt.addingTimeInterval(originalGap)
                let requiredTotalShift = max(0, desiredStart.timeIntervalSince(originalChild.plannedStartAt))
                guard requiredTotalShift > existingShift + 0.001 else { continue }
                guard let childPlanIndex = plans.firstIndex(where: { $0.tripKey == originalChild.id }) else {
                    return false
                }
                guard let parentPlan = plans.first(where: { $0.tripKey == parentID }) else { return false }

                let incrementalShift = requiredTotalShift - existingShift
                guard Self.shiftDispatchedTripPlan(
                    at: childPlanIndex,
                    by: incrementalShift,
                    simulatedAt: simulatedAt,
                    plans: &plans,
                    pendingEvents: &pendingEvents,
                    incidents: &incidents
                ) else { return false }

                let relatedAssignmentIDs = Set([originalChild.id] + reliefs.filter {
                    $0.outgoingAssignmentID == originalChild.id && $0.cancelledAt == nil
                }.map(\.incomingAssignmentID))
                for assignmentIndex in assignments.indices where relatedAssignmentIDs.contains(assignments[assignmentIndex].id) {
                    assignments[assignmentIndex].plannedStartAt = assignments[assignmentIndex].plannedStartAt.addingTimeInterval(incrementalShift)
                    assignments[assignmentIndex].plannedEndAt = assignments[assignmentIndex].plannedEndAt.addingTimeInterval(incrementalShift)
                }
                totalShiftByAssignmentID[originalChild.id] = requiredTotalShift
                eventHistory.append(SimulationEvent(
                    sequence: nextEventSequence,
                    simulatedAt: simulatedAt,
                    kind: .followingServiceDelayed(
                        fromTripID: parentPlan.tripID,
                        toTripID: plans[childPlanIndex].tripID,
                        routeID: plans[childPlanIndex].routeID,
                        delaySeconds: incrementalShift
                    )
                ))
                nextEventSequence &+= 1

                let affectedDutyBlockIDs = Set(assignments.filter {
                    relatedAssignmentIDs.contains($0.id)
                }.compactMap(\.dutyBlockID))
                for blockIndex in dutyBlocks.indices where affectedDutyBlockIDs.contains(dutyBlocks[blockIndex].id) {
                    let blockID = dutyBlocks[blockIndex].id
                    let blockAssignments = assignments.filter { $0.dutyBlockID == blockID }
                    if let firstStart = blockAssignments.map(\.plannedStartAt).min() {
                        dutyBlocks[blockIndex].plannedStartAt = firstStart
                    }
                    if let lastEnd = blockAssignments.map({ $0.actualEndAt ?? $0.plannedEndAt }).max() {
                        dutyBlocks[blockIndex].plannedEndAt = lastEnd
                    }
                }
                for busIndex in buses.indices where buses[busIndex].id == originalChild.vehicleID {
                    guard let childAssignmentIndex = assignments.firstIndex(where: { $0.id == originalChild.id }) else {
                        return false
                    }
                    buses[busIndex].reservedUntil = assignments
                        .filter { $0.vehicleID == originalChild.vehicleID && $0.actualEndAt == nil }
                        .map(\.plannedEndAt)
                        .max() ?? assignments[childAssignmentIndex].plannedEndAt
                }
                if queuedIDs.insert(originalChild.id).inserted {
                    queue.append(originalChild.id)
                }
            }
        }
        return true
    }

    private static func shiftDispatchedTripPlan(
        at planIndex: Int,
        by interval: TimeInterval,
        simulatedAt: Date,
        plans: inout [DispatchedTripRoutePlan],
        pendingEvents: inout [SimulationEvent],
        incidents: inout [VehicleIncident]
    ) -> Bool {
        guard interval.isFinite, interval > 0, plans.indices.contains(planIndex) else { return false }
        var plan = plans[planIndex]
        guard let firstVisit = plan.stopVisits.first, firstVisit.scheduledAt >= simulatedAt else { return false }
        let shiftedVisits = plan.stopVisits.map { visit in
            ScheduledTripStopVisit(
                stopID: visit.stopID,
                stopName: visit.stopName,
                stopSequence: visit.stopSequence,
                latitude: visit.latitude,
                longitude: visit.longitude,
                scheduledAt: visit.scheduledAt.addingTimeInterval(interval),
                departureAt: visit.departureAt?.addingTimeInterval(interval),
                movementToNext: visit.movementToNext,
                movementGeometrySource: visit.movementGeometrySource
            )
        }
        guard shiftedVisits.allSatisfy({
            $0.scheduledAt.timeIntervalSince1970.isFinite
                && ($0.departureAt?.timeIntervalSince1970.isFinite ?? true)
        }) else { return false }
        plan.stopVisits = shiftedVisits

        var eventSequences = Set(plan.stopEventSequencesByStopSequence.values)
        eventSequences.formUnion(plan.demandEventSequencesByStopSequence.values)
        eventSequences.formUnion(plan.movementEventSequencesByFromStopSequence.values)
        if let completionEventSequence = plan.completionEventSequence {
            eventSequences.insert(completionEventSequence)
        }
        for eventIndex in pendingEvents.indices where eventSequences.contains(pendingEvents[eventIndex].sequence) {
            let event = pendingEvents[eventIndex]
            let shiftedAt = event.simulatedAt.addingTimeInterval(interval)
            guard shiftedAt.timeIntervalSince1970.isFinite else { return false }
            let shiftedKind: SimulationEventKind
            switch event.kind {
            case var .passengerDemand(demand):
                demand.occurredAt = demand.occurredAt.addingTimeInterval(interval)
                shiftedKind = .passengerDemand(demand)
            case let .busMovementStarted(vehicleID, leg):
                shiftedKind = .busMovementStarted(
                    vehicleID: vehicleID,
                    leg: ScheduledBusMovementLeg(
                        startsAt: leg.startsAt.addingTimeInterval(interval),
                        endsAt: leg.endsAt.addingTimeInterval(interval),
                        coordinates: leg.coordinates,
                        geometrySource: leg.geometrySource,
                        depotReturnDestination: leg.depotReturnDestination
                    )
                )
            default:
                shiftedKind = event.kind
            }
            pendingEvents[eventIndex] = SimulationEvent(
                sequence: event.sequence,
                simulatedAt: shiftedAt,
                kind: shiftedKind
            )
        }

        for incidentIndex in incidents.indices where incidents[incidentIndex].tripID == plan.tripID
            && incidents[incidentIndex].vehicleID == plan.vehicleID
            && incidents[incidentIndex].occurredAt >= simulatedAt {
            incidents[incidentIndex].occurredAt = incidents[incidentIndex].occurredAt.addingTimeInterval(interval)
            incidents[incidentIndex].repairCompletedAt = incidents[incidentIndex].repairCompletedAt.addingTimeInterval(interval)
        }
        for eventIndex in pendingEvents.indices {
            guard case var .vehicleBreakdown(incident) = pendingEvents[eventIndex].kind,
                  incident.tripID == plan.tripID,
                  incident.vehicleID == plan.vehicleID,
                  incident.occurredAt >= simulatedAt else { continue }
            incident.occurredAt = incident.occurredAt.addingTimeInterval(interval)
            incident.repairCompletedAt = incident.repairCompletedAt.addingTimeInterval(interval)
            pendingEvents[eventIndex] = SimulationEvent(
                sequence: pendingEvents[eventIndex].sequence,
                simulatedAt: incident.occurredAt,
                kind: .vehicleBreakdown(incident)
            )
        }
        plans[planIndex] = plan
        return true
    }

    private static func hasBatteryReserveAfterDetour(
        from oldVisits: [ScheduledTripStopVisit],
        to newVisits: [ScheduledTripStopVisit],
        bus: PurchasedBus
    ) -> Bool {
        guard let capacity = bus.batteryCapacityKWh,
              let charge = bus.batteryChargeKWh,
              let model = VehicleMarketCatalog.model(id: bus.modelID),
              model.energy == .electric else { return true }
        let oldDistance = scheduledServiceDistance(oldVisits)
        let newDistance = scheduledServiceDistance(newVisits)
        let extraMeters = max(0, newDistance - oldDistance)
        let extraConsumption = extraMeters / 100_000
            * VehicleMarketCatalog.energyEstimate(for: model).quantityPer100Kilometers
        return charge - extraConsumption >= capacity * 0.15
    }

    private static func scheduledServiceDistance(_ visits: [ScheduledTripStopVisit]) -> Double {
        zip(visits, visits.dropFirst()).reduce(into: 0.0) { total, pair in
            if let coordinates = pair.0.movementToNext, coordinates.count >= 2 {
                total += pathDistance(coordinates)
            } else {
                total += pathDistance([
                    BusMovementCoordinate(latitude: pair.0.latitude, longitude: pair.0.longitude),
                    BusMovementCoordinate(latitude: pair.1.latitude, longitude: pair.1.longitude)
                ])
            }
        }
    }

    private static func eventOrder(_ left: SimulationEvent, _ right: SimulationEvent) -> Bool {
        if left.simulatedAt != right.simulatedAt { return left.simulatedAt < right.simulatedAt }
        return left.sequence < right.sequence
    }

    private static func pathDistance(_ coordinates: [BusMovementCoordinate]) -> Double {
        zip(coordinates, coordinates.dropFirst()).reduce(into: 0.0) { total, segment in
            let meanLatitude = (segment.0.latitude + segment.1.latitude) / 2 * .pi / 180
            let deltaX = (segment.1.longitude - segment.0.longitude) * cos(meanLatitude) * 111_320
            let deltaY = (segment.1.latitude - segment.0.latitude) * 111_320
            total += hypot(deltaX, deltaY)
        }
    }

    private static func applyVehicleEvent(_ event: SimulationEvent, to session: inout SimulationSession) {
        if case let .batteryRechargeCompleted(planID, vehicleID, chargeKWh) = event.kind {
            guard var buses = session.ownedBuses,
                  let index = buses.firstIndex(where: { $0.id == vehicleID }),
                  buses[index].rechargePlanID == planID,
                  let capacity = buses[index].batteryCapacityKWh else { return }
            buses[index].batteryChargeKWh = min(capacity, max(0, chargeKWh))
            buses[index].rechargePlanID = nil
            session.ownedBuses = buses
            return
        }
        if case .workshopExpansionCompleted = event.kind {
            guard session.workshopExpansionCompletesAt == event.simulatedAt else { return }
            session.workshopBayCount = VehicleWorkshopRules.maximumRepairBayCount
            session.workshopExpansionCompletesAt = nil
            return
        }
        if case let .workshopExpansionCompletedAtDepot(depotID) = event.kind {
            guard session.workshopExpansionCompletionDate(for: depotID) == event.simulatedAt else { return }
            var expansionDates = session.workshopExpansionCompletesAtByDepot ?? [:]
            expansionDates.removeValue(forKey: depotID)
            session.workshopExpansionCompletesAtByDepot = expansionDates
            var bayCounts = session.workshopBayCountsByDepot ?? [:]
            bayCounts[depotID] = VehicleWorkshopRules.maximumRepairBayCount
            session.workshopBayCountsByDepot = bayCounts
            if depotID == session.depotID {
                session.workshopExpansionCompletesAt = nil
                session.workshopBayCount = VehicleWorkshopRules.maximumRepairBayCount
            }
            return
        }
        if case let .depotEnergyInfrastructureCompleted(projectID, infrastructure) = event.kind {
            guard var projects = session.depotEnergyInfrastructureProjects,
                  let projectIndex = projects.firstIndex(where: {
                      $0.id == projectID
                          && $0.infrastructure == infrastructure
                          && $0.isPending
                          && $0.completesAt <= event.simulatedAt
                  }) else { return }
            projects[projectIndex].completedAt = event.simulatedAt
            session.depotEnergyInfrastructureProjects = projects
            return
        }
        if case let .workshopPartsDelivered(orderID) = event.kind {
            guard var orders = session.workshopPartOrders,
                  let orderIndex = orders.firstIndex(where: {
                      $0.id == orderID && $0.pending && $0.deliveryAt <= event.simulatedAt
                  }) else { return }
            let order = orders[orderIndex]
            orders[orderIndex].deliveredAt = event.simulatedAt
            session.workshopPartOrders = orders
            let deliveredQuantity = max(0, order.quantity - order.reservedQuantity)
            if deliveredQuantity > 0 {
                var stock = session.workshopPartsStock ?? []
                let depotID = order.depotID ?? session.depotID
                if let stockIndex = stock.firstIndex(where: {
                    $0.part == order.part && $0.vehicleModelID == order.vehicleModelID
                        && ($0.depotID ?? session.depotID) == depotID
                }) {
                    stock[stockIndex].quantity += deliveredQuantity
                } else {
                    stock.append(VehicleWorkshopPartStock(
                        part: order.part,
                        quantity: deliveredQuantity,
                        vehicleModelID: order.vehicleModelID,
                        depotID: depotID
                    ))
                }
                session.workshopPartsStock = stock
            }
            return
        }
        if case let .vehicleDiagnosticCompleted(incidentID, finding) = event.kind {
            guard var incidents = session.vehicleIncidents,
                  let incidentIndex = incidents.firstIndex(where: {
                      $0.id == incidentID && !$0.isResolved && $0.diagnosisStartedAt != nil
                  }) else { return }
            incidents[incidentIndex].diagnosisCompletedAt = event.simulatedAt
            incidents[incidentIndex].diagnosticFinding = finding
            session.vehicleIncidents = incidents
            return
        }
        guard var buses = session.ownedBuses else { return }
        if case let .vehicleBreakdown(plannedIncident) = event.kind {
            guard let busIndex = buses.firstIndex(where: { $0.id == plannedIncident.vehicleID }) else { return }
            guard !(session.vehicleIncidents ?? []).contains(where: { $0.id == plannedIncident.id }) else { return }
            let displacedPassengers = max(0, buses[busIndex].onboardPassengerCount ?? 0)
            buses[busIndex].status = .outOfService
            buses[busIndex].currentTripID = nil
            buses[busIndex].reservedTripKey = nil
            buses[busIndex].reservedUntil = nil
            buses[busIndex].activeMovementLeg = nil
            buses[busIndex].onboardPassengerCount = 0
            buses[busIndex].passengersLeftBehindCount = (buses[busIndex].passengersLeftBehindCount ?? 0) + displacedPassengers
            buses[busIndex].currentStopID = plannedIncident.stopID
            buses[busIndex].currentStopName = plannedIncident.stopName
            buses[busIndex].latitude = plannedIncident.latitude
            buses[busIndex].longitude = plannedIncident.longitude
            session.ownedBuses = buses

            if displacedPassengers > 0 {
                let queueKey = passengerQueueKey(routeID: plannedIncident.routeID, stopID: plannedIncident.stopID)
                var queues = session.passengerQueuesByRouteStopKey ?? [:]
                queues[queueKey, default: 0] += displacedPassengers
                session.passengerQueuesByRouteStopKey = queues
                var queueUpdatedAt = session.passengerQueueUpdatedAtByRouteStopKey ?? [:]
                queueUpdatedAt[queueKey] = event.simulatedAt
                session.passengerQueueUpdatedAtByRouteStopKey = queueUpdatedAt
            }

            var incident = plannedIncident
            incident.displacedPassengerCount = displacedPassengers
            incident.machinistID = session.machinistServiceAssignments?.last(where: {
                $0.vehicleID == incident.vehicleID && $0.tripID == incident.tripID
            })?.machinistID
            var incidents = session.vehicleIncidents ?? []
            incidents.append(incident)
            session.vehicleIncidents = incidents
            return
        }
        if case let .vehicleTowTeamArrived(incidentID) = event.kind {
            guard var incidents = session.vehicleIncidents,
                  let incidentIndex = incidents.firstIndex(where: { $0.id == incidentID && !$0.isResolved }),
                  incidents[incidentIndex].repairResponse == .towToDepot else { return }
            incidents[incidentIndex].recoveryTeamArrivedAt = event.simulatedAt
            session.vehicleIncidents = incidents
            return
        }
        if case let .vehicleTowStarted(incidentID) = event.kind {
            guard var incidents = session.vehicleIncidents,
                  let incidentIndex = incidents.firstIndex(where: { $0.id == incidentID }) else { return }
            let incident = incidents[incidentIndex]
            guard !incident.isResolved,
                  incident.repairResponse == .towToDepot,
                  incident.recoveryTeamArrivedAt != nil,
                  let plan = incident.towPlan,
                  let busIndex = buses.firstIndex(where: { $0.id == incident.vehicleID }) else { return }
            incidents[incidentIndex].busTowStartedAt = event.simulatedAt
            session.vehicleIncidents = incidents
            let arrivalAt = event.simulatedAt.addingTimeInterval(plan.expectedTravelSeconds)
            buses[busIndex].status = .beingTowed
            buses[busIndex].currentStopID = nil
            buses[busIndex].currentStopName = plan.depotName
            buses[busIndex].currentTripID = nil
            buses[busIndex].reservedTripKey = nil
            buses[busIndex].reservedUntil = nil
            buses[busIndex].activeMovementLeg = ScheduledBusMovementLeg(
                startsAt: event.simulatedAt,
                endsAt: arrivalAt,
                coordinates: plan.routeCoordinates
            )
            session.ownedBuses = buses
            return
        }
        if case let .vehicleTowArrived(incidentID) = event.kind {
            guard var incidents = session.vehicleIncidents,
                  let incidentIndex = incidents.firstIndex(where: { $0.id == incidentID && !$0.isResolved }),
                  let plan = incidents[incidentIndex].towPlan else { return }
            incidents[incidentIndex].towArrivedAt = event.simulatedAt
            incidents[incidentIndex].depotArrivedAt = event.simulatedAt
            session.vehicleIncidents = incidents
            if let busIndex = buses.firstIndex(where: { $0.id == incidents[incidentIndex].vehicleID }) {
                let workshopStartedAt = incidents[incidentIndex].workshopStartedAt ?? event.simulatedAt
                buses[busIndex].status = workshopStartedAt > event.simulatedAt ? .waitingForWorkshop : .inMaintenance
                buses[busIndex].depotID = plan.depotID
                buses[busIndex].currentStopID = nil
                buses[busIndex].currentStopName = plan.depotName
                buses[busIndex].latitude = plan.destination.latitude
                buses[busIndex].longitude = plan.destination.longitude
                buses[busIndex].currentTripID = nil
                buses[busIndex].reservedTripKey = nil
                buses[busIndex].reservedUntil = nil
                buses[busIndex].activeMovementLeg = nil
                session.ownedBuses = buses
            }
            return
        }
        if case let .vehicleWorkshopWorkStarted(incidentID) = event.kind {
            guard let incident = session.vehicleIncidents?.first(where: {
                $0.id == incidentID && !$0.isResolved && $0.repairResponse == .towToDepot
            }), incident.depotArrivedAt != nil || incident.towArrivedAt != nil,
                  let busIndex = buses.firstIndex(where: { $0.id == incident.vehicleID }) else { return }
            buses[busIndex].status = .inMaintenance
            session.ownedBuses = buses
            return
        }
        if case let .vehicleRepairCompleted(incidentID) = event.kind {
            guard var incidents = session.vehicleIncidents,
                  let incidentIndex = incidents.firstIndex(where: { $0.id == incidentID && !$0.isResolved }) else { return }
            incidents[incidentIndex].resolvedAt = event.simulatedAt
            let incident = incidents[incidentIndex]
            session.vehicleIncidents = incidents
            if let busIndex = buses.firstIndex(where: { $0.id == incident.vehicleID }) {
                if let plan = incident.towPlan {
                    buses[busIndex].status = .atDepot
                    buses[busIndex].depotID = plan.depotID
                    buses[busIndex].currentStopID = nil
                    buses[busIndex].currentStopName = plan.depotName
                    buses[busIndex].latitude = plan.destination.latitude
                    buses[busIndex].longitude = plan.destination.longitude
                } else {
                    buses[busIndex].status = .atStop
                    buses[busIndex].currentStopID = incident.stopID
                    buses[busIndex].currentStopName = incident.stopName
                    buses[busIndex].latitude = incident.latitude
                    buses[busIndex].longitude = incident.longitude
                }
                buses[busIndex].currentTripID = nil
                buses[busIndex].reservedTripKey = nil
                buses[busIndex].reservedUntil = nil
                buses[busIndex].activeMovementLeg = nil
                buses[busIndex].onboardPassengerCount = 0
                session.ownedBuses = buses
            }
            return
        }
        if case let .vehicleMaintenanceStarted(maintenanceID) = event.kind {
            guard let maintenance = session.vehicleMaintenanceRecords?.first(where: {
                $0.id == maintenanceID && !$0.isResolved
            }), maintenance.workshopStartedAt != nil,
                  let busIndex = buses.firstIndex(where: { $0.id == maintenance.vehicleID }) else { return }
            buses[busIndex].status = .inMaintenance
            session.ownedBuses = buses
            return
        }
        if case let .vehicleMaintenanceCompleted(maintenanceID) = event.kind {
            guard var maintenanceRecords = session.vehicleMaintenanceRecords,
                  let maintenanceIndex = maintenanceRecords.firstIndex(where: {
                      $0.id == maintenanceID && !$0.isResolved
                  }) else { return }
            maintenanceRecords[maintenanceIndex].resolvedAt = event.simulatedAt
            let maintenance = maintenanceRecords[maintenanceIndex]
            session.vehicleMaintenanceRecords = maintenanceRecords
            if let busIndex = buses.firstIndex(where: { $0.id == maintenance.vehicleID }),
               buses[busIndex].status == .inMaintenance {
                buses[busIndex].conditionPercent = maintenance.restoredConditionPercent
                buses[busIndex].lastPreventiveMaintenanceDistanceMeters = buses[busIndex].distanceTravelledMeters ?? 0
                buses[busIndex].status = maintenance.returnStatus
                session.ownedBuses = buses
            }
            return
        }
        if case let .passengersExchanged(exchange) = event.kind {
            guard let index = buses.firstIndex(where: { $0.id == exchange.vehicleID }) else { return }
            buses[index].onboardPassengerCount = exchange.onboardAfterExchange
            buses[index].passengersBoardedCount = (buses[index].passengersBoardedCount ?? 0) + exchange.boardedCount
            buses[index].passengersLeftBehindCount = (buses[index].passengersLeftBehindCount ?? 0)
                + (exchange.newlyLeftBehindCount ?? exchange.leftBehindCount)
            session.ownedBuses = buses
            let queueKey = passengerQueueKey(routeID: exchange.routeID, stopID: exchange.stopID)
            var queues = session.passengerQueuesByRouteStopKey ?? [:]
            queues[queueKey] = max(0, exchange.waitingAfterCount ?? exchange.leftBehindCount)
            if let replacementStopID = exchange.replacementStopID,
               let replacementWaitingAfterCount = exchange.replacementWaitingAfterCount {
                let replacementQueueKey = passengerQueueKey(
                    routeID: exchange.routeID,
                    stopID: replacementStopID
                )
                queues[replacementQueueKey] = max(0, replacementWaitingAfterCount)
            }
            session.passengerQueuesByRouteStopKey = queues
            var queueUpdatedAt = session.passengerQueueUpdatedAtByRouteStopKey ?? [:]
            queueUpdatedAt[queueKey] = exchange.occurredAt
            if let replacementStopID = exchange.replacementStopID {
                let replacementQueueKey = passengerQueueKey(
                    routeID: exchange.routeID,
                    stopID: replacementStopID
                )
                queueUpdatedAt[replacementQueueKey] = exchange.occurredAt
            }
            session.passengerQueueUpdatedAtByRouteStopKey = queueUpdatedAt
            var records = session.passengerExchangeRecords ?? []
            records.append(PassengerExchangeRecord(eventSequence: event.sequence, exchange: exchange))
            session.passengerExchangeRecords = records
            return
        }
        if case let .busDeadheadStarted(tripID, _, vehicleID, _, depotName, _, _, plan) = event.kind {
            guard let index = buses.firstIndex(where: { $0.id == vehicleID }) else { return }
            let arrivalAt = event.simulatedAt.addingTimeInterval(plan.expectedTravelSeconds)
            buses[index].status = .deadheadingToService
            buses[index].currentStopID = nil
            buses[index].currentStopName = depotName
            buses[index].currentTripID = tripID
            buses[index].latitude = plan.origin.latitude
            buses[index].longitude = plan.origin.longitude
            buses[index].activeMovementLeg = ScheduledBusMovementLeg(
                startsAt: event.simulatedAt,
                endsAt: arrivalAt,
                coordinates: plan.routeCoordinates
            )
            session.ownedBuses = buses
            return
        }
        if case let .busDepotReturnStarted(vehicleID, plan) = event.kind {
            guard let index = buses.firstIndex(where: { $0.id == vehicleID }) else { return }
            let arrivalAt = event.simulatedAt.addingTimeInterval(plan.expectedTravelSeconds)
            buses[index].status = .returningToDepot
            buses[index].currentStopID = nil
            buses[index].currentTripID = nil
            buses[index].reservedTripKey = nil
            buses[index].reservedUntil = nil
            buses[index].latitude = plan.origin.latitude
            buses[index].longitude = plan.origin.longitude
            buses[index].activeMovementLeg = ScheduledBusMovementLeg(
                startsAt: event.simulatedAt,
                endsAt: arrivalAt,
                coordinates: plan.routeCoordinates
            )
            session.ownedBuses = buses
            return
        }
        let depotReturnArrival: (vehicleID: String, depotID: String, depotName: String, latitude: Double, longitude: Double)?
        switch event.kind {
        case let .busDepotReturnArrived(vehicleID, depotID, depotName, latitude, longitude, _):
            depotReturnArrival = (vehicleID, depotID, depotName, latitude, longitude)
        case let .busDepotReturnArrivedWithMachinist(_, vehicleID, depotID, depotName, latitude, longitude, _):
            depotReturnArrival = (vehicleID, depotID, depotName, latitude, longitude)
        default:
            depotReturnArrival = nil
        }
        if let depotReturnArrival {
            let (vehicleID, depotID, depotName, latitude, longitude) = depotReturnArrival
            let arrivalCoordinate = BusMovementCoordinate(latitude: latitude, longitude: longitude)
            guard let index = buses.firstIndex(where: { $0.id == vehicleID }),
                  session.effectiveManagedDepotIDs.contains(buses[index].depotID),
                  DepotCareerScope.supports(scenarioID: session.scenarioID, depotID: buses[index].depotID),
                  let depot = DepotCareerScope.depotReference(for: buses[index].depotID),
                  depotID == depot.id,
                  depotName == depot.name,
                  let movement = buses[index].activeMovementLeg,
                  movement.endsAt <= event.simulatedAt,
                  let routeDestination = movement.coordinates.last,
                  Self.coordinatesMatch(routeDestination, arrivalCoordinate) else { return }
            if let destination = movement.depotReturnDestination {
                guard destination.depotID == depot.id,
                      destination.depotName == depot.name,
                      destination.requestedAddress == depot.address,
                      !destination.resolvedAddress.isEmpty,
                      Self.coordinatesMatch(routeDestination, destination.coordinate),
                      Self.coordinatesMatch(destination.coordinate, arrivalCoordinate) else { return }
            }
            buses[index].status = .atDepot
            buses[index].depotID = depotID
            buses[index].currentStopID = nil
            buses[index].currentStopName = depotName
            buses[index].currentTripID = nil
            buses[index].reservedTripKey = nil
            buses[index].reservedUntil = nil
            buses[index].latitude = latitude
            buses[index].longitude = longitude
            buses[index].activeMovementLeg = nil
            session.ownedBuses = buses
            return
        }
        if case let .busDeadheadArrived(_, _, vehicleID, stopID, stopName, latitude, longitude, _) = event.kind {
            guard let index = buses.firstIndex(where: { $0.id == vehicleID }) else { return }
            buses[index].status = .atStop
            buses[index].currentStopID = stopID
            buses[index].currentStopName = stopName
            buses[index].currentTripID = nil
            buses[index].latitude = latitude
            buses[index].longitude = longitude
            buses[index].activeMovementLeg = nil
            session.ownedBuses = buses
            return
        }
        if case let .busMovementStarted(vehicleID, leg) = event.kind {
            guard let index = buses.firstIndex(where: { $0.id == vehicleID }) else { return }
            buses[index].activeMovementLeg = leg
            if let first = leg.coordinates.first {
                buses[index].latitude = first.latitude
                buses[index].longitude = first.longitude
            }
            session.ownedBuses = buses
            return
        }
        if case let .busStopBypassed(_, vehicleID, _, _, _, movementLeg) = event.kind {
            guard let index = buses.firstIndex(where: { $0.id == vehicleID }) else { return }
            buses[index].status = .inService
            buses[index].activeMovementLeg = movementLeg
            if let first = movementLeg?.coordinates.first {
                buses[index].latitude = first.latitude
                buses[index].longitude = first.longitude
            }
            session.ownedBuses = buses
            return
        }
        if case let .busServiceCompletedAtClosedStopWithPassengerRedirect(
            _, vehicleID, routeID, stopID, stopName, latitude, longitude,
            passengerCount, replacementStopID, _
        ) = event.kind {
            guard let index = buses.firstIndex(where: { $0.id == vehicleID }) else { return }
            let queueKey = passengerQueueKey(routeID: routeID, stopID: replacementStopID)
            var queues = session.passengerQueuesByRouteStopKey ?? [:]
            queues[queueKey, default: 0] += max(0, passengerCount)
            session.passengerQueuesByRouteStopKey = queues
            var queueUpdatedAt = session.passengerQueueUpdatedAtByRouteStopKey ?? [:]
            queueUpdatedAt[queueKey] = event.simulatedAt
            session.passengerQueueUpdatedAtByRouteStopKey = queueUpdatedAt

            buses[index].status = .atStop
            buses[index].currentStopID = stopID
            buses[index].currentStopName = stopName
            buses[index].latitude = latitude
            buses[index].longitude = longitude
            buses[index].currentTripID = nil
            buses[index].reservedTripKey = nil
            buses[index].reservedUntil = nil
            buses[index].activeMovementLeg = nil
            buses[index].onboardPassengerCount = 0
            session.ownedBuses = buses
            return
        }
        if case let .busServiceCompletedAtClosedStop(_, vehicleID, routeID, stopID, stopName, latitude, longitude, strandedPassengerCount) = event.kind {
            guard let index = buses.firstIndex(where: { $0.id == vehicleID }) else { return }
            let activeClosure = session.stopClosures?.first(where: {
                $0.affects(stopID: stopID, routeID: routeID, at: event.simulatedAt)
            })
            let replacementGuide = activeClosure?.replacementGuidesByRouteID?[routeID]
            let queueStopID = replacementGuide?.replacementStopID ?? stopID
            let queueKey = passengerQueueKey(routeID: routeID, stopID: queueStopID)
            var queues = session.passengerQueuesByRouteStopKey ?? [:]
            queues[queueKey, default: 0] += max(0, strandedPassengerCount)
            session.passengerQueuesByRouteStopKey = queues
            var queueUpdatedAt = session.passengerQueueUpdatedAtByRouteStopKey ?? [:]
            queueUpdatedAt[queueKey] = event.simulatedAt
            session.passengerQueueUpdatedAtByRouteStopKey = queueUpdatedAt

            buses[index].status = .atStop
            buses[index].currentStopID = stopID
            buses[index].currentStopName = stopName
            buses[index].latitude = latitude
            buses[index].longitude = longitude
            buses[index].currentTripID = nil
            buses[index].reservedTripKey = nil
            buses[index].reservedUntil = nil
            buses[index].activeMovementLeg = nil
            buses[index].onboardPassengerCount = 0
            buses[index].passengersLeftBehindCount = (buses[index].passengersLeftBehindCount ?? 0) + max(0, strandedPassengerCount)
            session.ownedBuses = buses
            return
        }
        let vehicleID: String
        let stopID: String
        let stopName: String
        let latitude: Double
        let longitude: Double
        switch event.kind {
        case let .busDeparted(_, id, idStop, name, lat, lon),
             let .busAtStop(_, id, idStop, name, _, lat, lon):
            vehicleID = id
            stopID = idStop
            stopName = name
            latitude = lat
            longitude = lon
        case let .vehicleReplacementDeparted(_, _, id, idStop, name, lat, lon, _):
            vehicleID = id
            stopID = idStop
            stopName = name
            latitude = lat
            longitude = lon
        case let .busServiceCompleted(_, id, idStop, name, lat, lon):
            vehicleID = id
            stopID = idStop
            stopName = name
            latitude = lat
            longitude = lon
        default:
            return
        }
        guard let index = buses.firstIndex(where: { $0.id == vehicleID }) else { return }
        buses[index].currentStopID = stopID
        buses[index].currentStopName = stopName
        buses[index].latitude = latitude
        buses[index].longitude = longitude
        switch event.kind {
        case let .busDeparted(tripID, _, _, _, _, _):
            buses[index].status = .inService
            buses[index].currentTripID = tripID
            buses[index].activeMovementLeg = nil
        case let .vehicleReplacementDeparted(_, tripID, _, _, _, _, _, _):
            buses[index].status = .inService
            buses[index].currentTripID = tripID
            buses[index].activeMovementLeg = nil
        case .busAtStop:
            buses[index].status = .inService
            buses[index].activeMovementLeg = nil
        case .busServiceCompleted:
            buses[index].status = .atStop
            buses[index].currentTripID = nil
            buses[index].reservedTripKey = nil
            buses[index].reservedUntil = nil
            buses[index].activeMovementLeg = nil
            buses[index].onboardPassengerCount = 0
        default:
            break
        }
        session.ownedBuses = buses
    }

    private static func applyLoanEvent(_ event: SimulationEvent, to session: inout SimulationSession) {
        guard case let .loanInstallmentDue(loanID, installmentNumber) = event.kind,
              var loans = session.loans,
              let loanIndex = loans.firstIndex(where: { $0.id == loanID }),
              let installmentIndex = loans[loanIndex].installments.firstIndex(where: {
                  $0.number == installmentNumber && $0.paidAt == nil && $0.dueAt <= event.simulatedAt
              }) else { return }

        let installment = loans[loanIndex].installments[installmentIndex]
        loans[loanIndex].installments[installmentIndex].paidAt = event.simulatedAt
        session.loans = loans
        session.cashBalance = (session.cashBalance ?? 0) - installment.totalEuro

        var entries = session.ledgerEntries ?? []
        if installment.principalEuro > 0 {
            entries.append(SimulationLedgerEntry(
                id: "loan-principal-\(loanID)-\(installmentNumber)",
                occurredAt: event.simulatedAt,
                category: "Remboursement d’emprunt",
                description: "Crédit de jeu · mensualité \(installmentNumber)/\(loans[loanIndex].termMonths)",
                amount: -installment.principalEuro,
                nature: .financing
            ))
        }
        if installment.interestEuro > 0 {
            entries.append(SimulationLedgerEntry(
                id: "loan-interest-\(loanID)-\(installmentNumber)",
                occurredAt: event.simulatedAt,
                category: "Intérêts d’emprunt",
                description: "Crédit de jeu · mensualité \(installmentNumber)/\(loans[loanIndex].termMonths)",
                amount: -installment.interestEuro,
                nature: .financing
            ))
        }
        session.ledgerEntries = entries
    }

    private static func applyInvoiceSettlementEvent(_ event: SimulationEvent, to session: inout SimulationSession) {
        guard case let .invoiceSettlementDue(invoiceID) = event.kind,
              var invoices = session.invoices,
              let invoiceIndex = invoices.firstIndex(where: {
                  $0.id == invoiceID && !$0.isPaid && $0.dueAt <= event.simulatedAt
              }),
              let cashBalance = session.cashBalance else { return }

        let invoice = invoices[invoiceIndex]
        let settlementEntryID = "invoice-settlement-\(invoice.id)"
        var entries = session.ledgerEntries ?? []
        if entries.contains(where: { $0.id == settlementEntryID }) {
            invoices[invoiceIndex].paidAt = event.simulatedAt
            session.invoices = invoices
            return
        }

        invoices[invoiceIndex].paidAt = event.simulatedAt
        session.invoices = invoices
        session.cashBalance = cashBalance + invoice.cashDeltaEuro
        entries.append(SimulationLedgerEntry(
            id: settlementEntryID,
            occurredAt: event.simulatedAt,
            category: invoice.direction == .receivable ? "Encaissement de facture" : "Paiement de facture",
            description: "\(invoice.title) · \(invoice.counterparty)",
            amount: 0,
            nature: .settlement,
            cashDeltaEuro: invoice.cashDeltaEuro
        ))
        session.ledgerEntries = entries
    }

    private static func applyMachinistEvent(_ event: SimulationEvent, to session: inout SimulationSession) {
        if case let .machinistBreakStarted(breakID) = event.kind {
            guard var breaks = session.machinistBreaks,
                  let index = breaks.firstIndex(where: {
                      $0.id == breakID && $0.isPending && $0.startsAt <= event.simulatedAt
                  }) else { return }
            breaks[index].startedAt = event.simulatedAt
            session.machinistBreaks = breaks
            return
        }
        if case let .machinistBreakCompleted(breakID) = event.kind {
            guard var breaks = session.machinistBreaks,
                  let index = breaks.firstIndex(where: {
                      $0.id == breakID && $0.isPending && $0.endsAt <= event.simulatedAt
                  }) else { return }
            breaks[index].completedAt = event.simulatedAt
            session.machinistBreaks = breaks
            return
        }
        if case let .machinistAbsenceCompleted(absenceID) = event.kind {
            guard var absences = session.machinistAbsences,
                  let absenceIndex = absences.firstIndex(where: {
                      $0.id == absenceID && $0.settledAt == nil && $0.endsAt <= event.simulatedAt
                  }) else { return }
            let absence = absences[absenceIndex]
            absences[absenceIndex].settledAt = event.simulatedAt
            session.machinistAbsences = absences

            guard let absenceType = absence.absenceType,
                  let laborCost = absence.estimatedPayrollCostEuro,
                  let machinist = session.machinists?.first(where: { $0.id == absence.machinistID }) else { return }
            Self.recordMachinistPayroll(
                id: "machinist-absence-\(absence.id)",
                machinistID: absence.machinistID,
                kind: MachinistPayrollKind(absenceType: absenceType),
                machinistName: machinist.displayName,
                routeDescription: absenceType.title.lowercased(),
                durationText: (absence.estimatedPaidHours ?? 0).formatted(.number.precision(.fractionLength(1))),
                workHours: absence.estimatedPaidHours ?? 0,
                laborCost: laborCost,
                occurredAt: event.simulatedAt,
                session: &session,
                workDescription: "d’absence rémunérée estimée"
            )
            return
        }

        switch event.kind {
        case let .vehicleTowTeamArrived(incidentID):
            Self.recordMachinistIncidentWaiting(incidentID: incidentID, endedAt: event.simulatedAt, in: &session)
        case let .vehicleTowArrived(incidentID):
            if session.vehicleIncidents?.first(where: { $0.id == incidentID })?.recoveryTeamArrivedAt == nil {
                Self.recordMachinistIncidentWaiting(incidentID: incidentID, endedAt: event.simulatedAt, in: &session)
            }
            return
        case let .vehicleRepairCompleted(incidentID):
            guard let incident = session.vehicleIncidents?.first(where: { $0.id == incidentID }),
                  incident.repairResponse != .towToDepot else { return }
            Self.recordMachinistIncidentWaiting(incidentID: incidentID, endedAt: event.simulatedAt, in: &session)
            return
        default:
            break
        }

        guard case let .machinistTrainingCompleted(trainingID) = event.kind,
              var trainings = session.machinistTrainings,
              let trainingIndex = trainings.firstIndex(where: {
                  $0.id == trainingID && $0.isPending && $0.endsAt <= event.simulatedAt
              }),
              var machinists = session.machinists,
              let machinistIndex = machinists.firstIndex(where: {
                  $0.id == trainings[trainingIndex].machinistID
              }) else { return }

        let training = trainings[trainingIndex]
        guard machinists[machinistIndex].qualification == training.sourceQualification else {
            trainings[trainingIndex].cancelledAt = event.simulatedAt
            session.machinistTrainings = trainings
            return
        }

        machinists[machinistIndex].qualification = training.targetQualification
        trainings[trainingIndex].completedAt = event.simulatedAt
        session.machinists = machinists
        session.machinistTrainings = trainings
        recordMachinistPayroll(
            id: "machinist-training-\(training.id)",
            machinistID: training.machinistID,
            kind: .training,
            machinistName: machinists[machinistIndex].displayName,
            routeDescription: "qualification bus articulé",
            durationText: MachinistWorkRules.articulatedTrainingDurationHours.formatted(),
            workHours: Double(MachinistWorkRules.articulatedTrainingDurationHours),
            laborCost: training.estimatedLaborCostEuro,
            occurredAt: event.simulatedAt,
            session: &session,
            workDescription: "de formation"
        )
    }

    private static func recordMachinistIncidentWaiting(
        incidentID: String,
        endedAt: Date,
        in session: inout SimulationSession
    ) {
        guard let incident = session.vehicleIncidents?.first(where: { $0.id == incidentID }),
              let machinistID = incident.machinistID
                ?? session.machinistServiceAssignments?.last(where: {
                    $0.vehicleID == incident.vehicleID && $0.tripID == incident.tripID
                })?.machinistID,
              let machinist = session.machinists?.first(where: { $0.id == machinistID }) else { return }

        let waitingHours = max(0, endedAt.timeIntervalSince(incident.occurredAt)) / 3_600
        let hourlyCost = machinist.estimatedLoadedCostPerServiceHourEuro
        let laborCost = Int((waitingHours * Double(hourlyCost)).rounded())
        Self.recordMachinistPayroll(
            id: "machinist-incident-wait-\(incident.id)",
            machinistID: machinist.id,
            kind: .incidentWaiting,
            machinistName: machinist.displayName,
            routeDescription: "ligne \(incident.routeID) · véhicule \(incident.vehicleID)",
            durationText: waitingHours.formatted(.number.precision(.fractionLength(2))),
            workHours: waitingHours,
            laborCost: laborCost,
            occurredAt: endedAt,
            session: &session,
            workDescription: "d’attente après panne estimée (règle de jeu)"
        )
    }

    private static func updateVehiclePositions(in session: inout SimulationSession, through date: Date) {
        guard var buses = session.ownedBuses else { return }
        var didUpdate = false
        for index in buses.indices {
            guard let leg = buses[index].activeMovementLeg,
                  let location = location(on: leg, at: date) else { continue }
            buses[index].latitude = location.latitude
            buses[index].longitude = location.longitude
            didUpdate = true
        }
        if didUpdate { session.ownedBuses = buses }
    }

    private static func location(
        on leg: ScheduledBusMovementLeg,
        at date: Date
    ) -> BusMovementCoordinate? {
        guard let first = leg.coordinates.first, let last = leg.coordinates.last,
              leg.coordinates.count >= 2 else { return nil }
        if date <= leg.startsAt { return first }
        if date >= leg.endsAt { return last }
        let duration = leg.endsAt.timeIntervalSince(leg.startsAt)
        guard duration > 0 else { return last }
        let progress = min(1, max(0, date.timeIntervalSince(leg.startsAt) / duration))
        let lengths = zip(leg.coordinates, leg.coordinates.dropFirst()).map { segment in
            pathDistance([segment.0, segment.1])
        }
        let totalDistance = lengths.reduce(0, +)
        guard totalDistance > 0 else { return first }
        var remainingDistance = totalDistance * progress
        for (index, segmentLength) in lengths.enumerated() {
            let start = leg.coordinates[index]
            let end = leg.coordinates[index + 1]
            if remainingDistance <= segmentLength || index == lengths.count - 1 {
                let fraction = segmentLength == 0 ? 0 : min(1, max(0, remainingDistance / segmentLength))
                return BusMovementCoordinate(
                    latitude: start.latitude + (end.latitude - start.latitude) * fraction,
                    longitude: start.longitude + (end.longitude - start.longitude) * fraction
                )
            }
            remainingDistance -= segmentLength
        }
        return last
    }
}
