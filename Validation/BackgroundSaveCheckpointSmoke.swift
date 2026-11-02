import SwiftUI

@main
struct BackgroundSaveCheckpointSmoke {
    static func main() {
        let cases: [(ScenePhase, Bool)] = [
            (.active, false),
            (.inactive, false),
            (.background, true)
        ]

        for (phase, expected) in cases {
            guard CareerLifecycleCheckpoint.shouldSave(for: phase) == expected else {
                fatalError("Le checkpoint doit être demandé uniquement au passage en arrière-plan.")
            }
        }

        let synchronizationCases: [(ScenePhase, Bool)] = [
            (.active, true),
            (.inactive, false),
            (.background, false)
        ]

        for (phase, expected) in synchronizationCases {
            guard CareerLifecycleCheckpoint.shouldSynchronize(for: phase) == expected else {
                fatalError("La synchronisation iCloud doit être demandée au retour au premier plan seulement.")
            }
        }

        print("PASS : le checkpoint est demandé en arrière-plan et iCloud au retour au premier plan seulement.")
    }
}
