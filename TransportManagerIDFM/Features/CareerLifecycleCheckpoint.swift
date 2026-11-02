import SwiftUI

enum CareerLifecycleCheckpoint {
    static func shouldSave(for phase: ScenePhase) -> Bool {
        phase == .background
    }

    static func shouldSynchronize(for phase: ScenePhase) -> Bool {
        phase == .active
    }
}
