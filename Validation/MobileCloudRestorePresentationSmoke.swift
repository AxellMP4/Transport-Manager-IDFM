import Foundation

@main
struct MobileCloudRestorePresentationSmoke {
    static func main() {
        let accountError = "Connectez-vous à iCloud pour synchroniser cette carrière"
        let failedRestore = MobileCloudRestorePresentation(
            statusMessage: accountError,
            isSyncing: false,
            hasConflict: false
        )

        precondition(failedRestore.statusMessage == accountError, "The empty-career view must retain the restore failure reason.")
        precondition(failedRestore.isRetryEnabled, "A completed restore failure must leave retry available.")
        precondition(failedRestore.canStartNewCareer, "A failed restore must not block a new local career.")
        precondition(failedRestore.canImportSave, "A failed restore must leave manual import available.")

        let activeRestore = MobileCloudRestorePresentation(
            statusMessage: "Synchronisation iCloud…",
            isSyncing: true,
            hasConflict: false
        )
        precondition(!activeRestore.isRetryEnabled, "A retry must not start while a restore is already running.")
        precondition(!activeRestore.canStartNewCareer, "A new career must wait while a cloud restore could replace the local session.")
        precondition(!activeRestore.canImportSave, "Manual import must wait while a cloud restore could replace the local session.")

        let unresolvedConflict = MobileCloudRestorePresentation(
            statusMessage: "Une autre carrière est déjà dans iCloud.",
            isSyncing: false,
            hasConflict: true
        )
        precondition(unresolvedConflict.statusSymbol == "exclamationmark.icloud", "A conflict must have a distinct status symbol.")

        print("PASS: restore feedback, retry, career/import gating, and explicit conflict indicator")
    }
}
