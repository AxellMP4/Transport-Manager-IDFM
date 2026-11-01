import Foundation

@main
struct MobileCloudRestorePresentationSmoke {
    static func main() {
        let initialRestore = CareerRestorePresentation(
            statusMessage: "iCloud non vérifié",
            isSyncing: false,
            hasConflict: false
        )
        precondition(initialRestore.isPending, "Career actions must wait until the first cloud restore check finishes.")
        precondition(!initialRestore.canStartNewCareer, "A new career must not race the initial cloud restore.")
        precondition(!initialRestore.canImportSave, "A file import must not race the initial cloud restore.")

        let accountError = "Connectez-vous à iCloud pour synchroniser cette carrière"
        let failedRestore = CareerRestorePresentation(
            statusMessage: accountError,
            isSyncing: false,
            hasConflict: false
        )

        precondition(failedRestore.statusMessage == accountError, "The empty-career view must retain the restore failure reason.")
        precondition(failedRestore.isRetryEnabled, "A completed restore failure must leave retry available.")
        precondition(!failedRestore.isPending, "A completed restore failure must let the player continue locally.")
        precondition(failedRestore.canStartNewCareer, "A failed restore must not block a new local career.")
        precondition(failedRestore.canImportSave, "A failed restore must leave manual import available.")

        let activeRestore = CareerRestorePresentation(
            statusMessage: "Synchronisation iCloud…",
            isSyncing: true,
            hasConflict: false
        )
        precondition(!activeRestore.isRetryEnabled, "A retry must not start while a restore is already running.")
        precondition(!activeRestore.canStartNewCareer, "A new career must wait while a cloud restore could replace the local session.")
        precondition(!activeRestore.canImportSave, "Manual import must wait while a cloud restore could replace the local session.")

        let unresolvedConflict = CareerRestorePresentation(
            statusMessage: "Une autre carrière est déjà dans iCloud.",
            isSyncing: false,
            hasConflict: true
        )
        precondition(unresolvedConflict.statusSymbol == "exclamationmark.icloud", "A conflict must have a distinct status symbol.")

        print("PASS: initial restore gating, local recovery after error, retry, and conflict indicator")
    }
}
