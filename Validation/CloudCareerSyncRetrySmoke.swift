import Foundation

@main
struct CloudCareerSyncRetrySmoke {
    @MainActor
    static func main() async {
        await throttledUploadRetriesWithoutFurtherInput()
        await aNewerSuccessfulSyncCancelsTheRetry()
        await deallocationCancelsTheRetry()
        await aNewerRequestRunsAfterTheActiveSync()
        print("PASS: throttled retries and in-flight synchronization coalescing are deterministic")
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
