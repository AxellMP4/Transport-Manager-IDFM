import Foundation
import CloudKit

@main
struct CloudCareerSyncRetrySmoke {
    @MainActor
    static func main() async {
        await choosingCloudPreservesLocalCareerBeforeDownload()
        downloadedVersionRemainsTheCheckpointWhenCloudAdvancesDuringImport()
        var policyFailures: [String] = []
        if let failure = await choosingCloudPreservesSameLocalCareerBeforeDownload() {
            policyFailures.append(failure)
        }
        if let failure = await failedLocalBackupPreventsSameCareerCloudReplacement() {
            policyFailures.append(failure)
        }
        await throttledUploadRetriesWithoutFurtherInput()
        await requestRateLimitedUploadRetriesAfterServerDelay()
        await serviceUnavailableRetriesAfterServerDelay()
        await serverRateLimitDoesNotShortenLocalThrottle()
        await aNewerSuccessfulSyncCancelsTheRetry()
        await deallocationCancelsTheRetry()
        await aNewerRequestRunsAfterTheActiveSync()
        precondition(policyFailures.isEmpty, policyFailures.joined(separator: "\n"))
        print("PASS: throttled retries and in-flight synchronization coalescing are deterministic")
    }

    private static func downloadedVersionRemainsTheCheckpointWhenCloudAdvancesDuringImport() {
        let decision = CloudCareerSyncPolicy.downloadCheckpointDecision(
            downloadedChangeTag: "cloud-v1",
            latestChangeTag: "cloud-v2"
        )
        precondition(
            decision == .remoteAdvanced(downloadedChangeTag: "cloud-v1"),
            "If CloudKit advances during import, checkpoint only the version that was imported and request another sync."
        )

        let stableDecision = CloudCareerSyncPolicy.downloadCheckpointDecision(
            downloadedChangeTag: "cloud-v2",
            latestChangeTag: "cloud-v2"
        )
        precondition(
            stableDecision == .stable(downloadedChangeTag: "cloud-v2"),
            "An unchanged CloudKit record should finish the download without another sync."
        )
    }

    @MainActor
    private static func choosingCloudPreservesLocalCareerBeforeDownload() async {
        var operations: [String] = []

        do {
            try await CloudCareerSyncPolicy.resolvePreferCloudChoice(
                preserveLocal: { operations.append("preserve-local") },
                downloadCloud: { operations.append("download-cloud") }
            )
        } catch {
            preconditionFailure("A successful conflict backup and download should complete: \(error)")
        }

        precondition(
            operations == ["preserve-local", "download-cloud"],
            "Choosing iCloud must preserve the local career before downloading the replacement."
        )
    }

    @MainActor
    private static func choosingCloudPreservesSameLocalCareerBeforeDownload() async -> String? {
        var operations: [String] = []

        do {
            try await CloudCareerSyncPolicy.resolvePreferCloudChoice(
                preserveLocal: { operations.append("preserve-local") },
                downloadCloud: { operations.append("download-cloud") }
            )
        } catch {
            return "FAIL (same-session conflict): successful backup and download threw \(error)"
        }

        guard operations == ["preserve-local", "download-cloud"] else {
            return "FAIL (same-session conflict): expected [preserve-local, download-cloud], got \(operations)"
        }
        return nil
    }

    @MainActor
    private static func failedLocalBackupPreventsSameCareerCloudReplacement() async -> String? {
        var downloadedCloud = false
        var receivedBackupError = false
        let backupError = NSError(domain: "CloudCareerSyncRetrySmoke", code: 1)

        do {
            try await CloudCareerSyncPolicy.resolvePreferCloudChoice(
                preserveLocal: { throw backupError },
                downloadCloud: { downloadedCloud = true }
            )
        } catch let error as NSError {
            receivedBackupError = error == backupError
        } catch {
            return "FAIL (backup failure): expected original backup error, got \(error)"
        }

        guard receivedBackupError, !downloadedCloud else {
            return "FAIL (backup failure): expected backup error propagation and no cloud download; receivedBackupError=\(receivedBackupError), downloadedCloud=\(downloadedCloud)"
        }
        return nil
    }

    @MainActor
    private static func throttledUploadRetriesWithoutFurtherInput() async {
        let queue = ManualRetryQueue()
        let scheduler = CloudSyncRetryScheduler { delay, operation in
            queue.enqueue(after: delay, operation: operation)
        }
        let uploadTime = Date(timeIntervalSince1970: 1_000)
        var attempts = 0

        let wasThrottled = scheduler.scheduleIfThrottled(
            lastSuccessfulUploadAt: uploadTime,
            now: uploadTime.addingTimeInterval(110),
            minimumInterval: 120,
            retry: { attempts += 1 }
        )

        precondition(wasThrottled, "A save within the upload window should schedule its retry.")
        precondition(queue.scheduledDelays == [10], "The retry should wait only for the remaining throttle window.")

        await queue.fireNext()
        precondition(attempts == 1, "The pending retry must run without another save or manual sync.")
        precondition(queue.pendingCount == 0, "The retry should be a single scheduled attempt.")
    }

    @MainActor
    private static func requestRateLimitedUploadRetriesAfterServerDelay() async {
        let queue = ManualRetryQueue()
        let scheduler = CloudSyncRetryScheduler { delay, operation in
            queue.enqueue(after: delay, operation: operation)
        }
        let now = Date(timeIntervalSince1970: 4_000)
        let error = CKError(
            .requestRateLimited,
            userInfo: [CKErrorRetryAfterKey: NSNumber(value: 90)]
        )
        var attempts = 0

        guard let retryAfter = CloudCareerSyncPolicy.serverRetryAfterSeconds(for: error) else {
            preconditionFailure("A rate-limit error should expose CloudKit's retry-after delay.")
        }
        let wasLocallyThrottled = scheduler.scheduleIfThrottled(
            lastSuccessfulUploadAt: now.addingTimeInterval(-50),
            now: now,
            minimumInterval: 120,
            retry: { attempts += 1 }
        )
        let wasExtendedForServerDelay = scheduler.scheduleIfThrottled(
            lastSuccessfulUploadAt: now.addingTimeInterval(-110),
            now: now,
            minimumInterval: 120,
            serverRetryAfter: retryAfter,
            retry: { attempts += 1 }
        )

        precondition(wasLocallyThrottled && wasExtendedForServerDelay, "A rate-limit response should keep one automatic retry scheduled.")
        precondition(queue.scheduledDelays == [70, 90], "The retry must move out to CloudKit's requested 90-second delay.")
        precondition(queue.pendingCount == 1, "Extending the retry must cancel its earlier, too-soon schedule.")
        await queue.fireNext()
        precondition(attempts == 0, "The canceled local retry must not run before CloudKit's requested delay.")
        await queue.fireNext()
        precondition(attempts == 1, "The server-requested retry must run once without further input.")
    }

    @MainActor
    private static func serverRateLimitDoesNotShortenLocalThrottle() async {
        let queue = ManualRetryQueue()
        let scheduler = CloudSyncRetryScheduler { delay, operation in
            queue.enqueue(after: delay, operation: operation)
        }
        let now = Date(timeIntervalSince1970: 5_000)
        let error = CKError(
            .requestRateLimited,
            userInfo: [CKErrorRetryAfterKey: NSNumber(value: 30)]
        )
        var attempts = 0

        guard let retryAfter = CloudCareerSyncPolicy.serverRetryAfterSeconds(for: error) else {
            preconditionFailure("A rate-limit error should expose CloudKit's retry-after delay.")
        }
        let wasScheduled = scheduler.scheduleIfThrottled(
            lastSuccessfulUploadAt: now.addingTimeInterval(-40),
            now: now,
            minimumInterval: 120,
            serverRetryAfter: retryAfter,
            retry: { attempts += 1 }
        )

        precondition(wasScheduled, "A CloudKit rate-limit response should schedule an automatic retry.")
        precondition(queue.scheduledDelays == [80], "A shorter server delay must not bypass the remaining local throttle.")
        await queue.fireNext()
        precondition(attempts == 1, "The combined throttle retry must run once.")
    }

    @MainActor
    private static func serviceUnavailableRetriesAfterServerDelay() async {
        let queue = ManualRetryQueue()
        let scheduler = CloudSyncRetryScheduler { delay, operation in
            queue.enqueue(after: delay, operation: operation)
        }
        let now = Date(timeIntervalSince1970: 6_000)
        let error = CKError(
            .serviceUnavailable,
            userInfo: [CKErrorRetryAfterKey: NSNumber(value: 45)]
        )
        var attempts = 0

        guard let retryAfter = CloudCareerSyncPolicy.serverRetryAfterSeconds(for: error) else {
            preconditionFailure("A service-unavailable error should expose CloudKit's retry-after delay.")
        }
        let wasScheduled = scheduler.scheduleIfThrottled(
            lastSuccessfulUploadAt: nil,
            now: now,
            minimumInterval: 120,
            serverRetryAfter: retryAfter,
            retry: { attempts += 1 }
        )

        precondition(wasScheduled, "A CloudKit service-unavailable response should schedule an automatic retry.")
        precondition(queue.scheduledDelays == [45], "The retry must honor CloudKit's 45-second service delay.")
        await queue.fireNext()
        precondition(attempts == 1, "The service-unavailable retry must run once without further input.")
    }

    @MainActor
    private static func aNewerSuccessfulSyncCancelsTheRetry() async {
        let queue = ManualRetryQueue()
        let scheduler = CloudSyncRetryScheduler { delay, operation in
            queue.enqueue(after: delay, operation: operation)
        }
        let uploadTime = Date(timeIntervalSince1970: 2_000)
        var attempts = 0

        _ = scheduler.scheduleIfThrottled(
            lastSuccessfulUploadAt: uploadTime,
            now: uploadTime.addingTimeInterval(60),
            minimumInterval: 120,
            retry: { attempts += 1 }
        )
        scheduler.cancel()
        await queue.fireNext()

        precondition(attempts == 0, "A successful newer sync must cancel the stale retry.")
    }

    @MainActor
    private static func deallocationCancelsTheRetry() async {
        let queue = ManualRetryQueue()
        let uploadTime = Date(timeIntervalSince1970: 3_000)
        var attempts = 0
        weak var weakScheduler: CloudSyncRetryScheduler?

        do {
            let scheduler = CloudSyncRetryScheduler { delay, operation in
                queue.enqueue(after: delay, operation: operation)
            }
            weakScheduler = scheduler
            _ = scheduler.scheduleIfThrottled(
                lastSuccessfulUploadAt: uploadTime,
                now: uploadTime.addingTimeInterval(30),
                minimumInterval: 120,
                retry: { attempts += 1 }
            )
        }

        precondition(weakScheduler == nil, "The retry task must not keep its owner alive.")
        await queue.fireNext()
        precondition(attempts == 0, "A retry owned by a deallocated sync manager must not run.")
    }

    @MainActor
    private static func aNewerRequestRunsAfterTheActiveSync() async {
        let coalescer = CloudSyncRequestCoalescer()
        let gate = SmokeAsyncGate()
        var completedRequests: [Int] = []

        let firstSync = Task { @MainActor in
            await coalescer.run {
                completedRequests.append(1)
                await gate.wait()
            }
        }

        while completedRequests.isEmpty { await Task.yield() }
        await coalescer.run { completedRequests.append(2) }
        await coalescer.run { completedRequests.append(3) }
        precondition(completedRequests == [1], "Requests arriving during a sync must wait, not overlap it.")

        gate.release()
        await firstSync.value
        precondition(completedRequests == [1, 3], "The latest queued save must run immediately after the active sync.")
    }
}

@MainActor
private final class SmokeAsyncGate {
    private var continuation: CheckedContinuation<Void, Never>?
    private var isReleased = false

    func wait() async {
        guard !isReleased else { return }
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func release() {
        isReleased = true
        continuation?.resume()
        continuation = nil
    }
}

@MainActor
private final class ManualRetryQueue {
    private struct Entry {
        let delay: TimeInterval
        let operation: @MainActor () async -> Void
        let cancellation: CancellationFlag
    }

    private var entries: [Entry] = []

    var scheduledDelays: [TimeInterval] { entries.map(\.delay) }
    var pendingCount: Int { entries.filter { !$0.cancellation.isCancelled }.count }

    func enqueue(
        after delay: TimeInterval,
        operation: @escaping @MainActor () async -> Void
    ) -> @MainActor () -> Void {
        let cancellation = CancellationFlag()
        entries.append(Entry(delay: delay, operation: operation, cancellation: cancellation))
        return { cancellation.cancel() }
    }

    func fireNext() async {
        guard !entries.isEmpty else { preconditionFailure("Expected one scheduled retry.") }
        let entry = entries.removeFirst()
        if !entry.cancellation.isCancelled { await entry.operation() }
    }
}

private final class CancellationFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var cancelled = false

    var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return cancelled
    }

    func cancel() {
        lock.lock()
        defer { lock.unlock() }
        cancelled = true
    }
}
