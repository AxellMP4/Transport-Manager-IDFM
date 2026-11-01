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

        let activeRestore = MobileCloudRestorePresentation(
            statusMessage: "Synchronisation iCloud…",
            isSyncing: true,
            hasConflict: false
        )
        precondition(!activeRestore.isRetryEnabled, "A retry must not start while a restore is already running.")

        print("PASS: empty-career restore status stays visible and retry re-enables after failure")
    }
}
