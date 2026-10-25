import Foundation

@main
struct ZIPArchiveStreamingSmoke {
    static func main() throws {
        guard CommandLine.arguments.count == 6 else {
            fputs("Usage: ZIPArchiveStreamingSmoke <archive.zip> <expected-file> <corrupt-archive.zip> <gtfs.zip> <corrupt-stop-times.zip>\n", stderr)
            exit(2)
        }

        let archive = try ZIPArchiveReader(url: URL(fileURLWithPath: CommandLine.arguments[1]))
        guard let entry = archive.entry(named: "payload.bin") else {
            fatalError("The archive must contain payload.bin")
        }
        let expected = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[2]))
        var actual = Data()
        var chunkCount = 0
        try archive.forEachChunk(in: entry) { chunk in
            precondition(!chunk.isEmpty, "Streaming must not emit empty chunks")
            precondition(chunk.count <= 64 * 1_024, "Streaming chunks must remain bounded")
            actual.append(chunk)
            chunkCount += 1
        }
        precondition(chunkCount > 1, "The fixture must exercise multiple chunks")
        precondition(actual == expected, "Streaming output must exactly match the original payload")

        var callbackErrorPropagated = false
        do {
            try archive.forEachChunk(in: entry) { _ in
                throw SmokeError.callback
            }
        } catch SmokeError.callback {
            callbackErrorPropagated = true
        }
        precondition(callbackErrorPropagated, "Streaming must propagate errors from its consumer")

        try verifyChecksumMismatch(
            in: URL(fileURLWithPath: CommandLine.arguments[3]),
            entryName: "payload.bin"
        )

        let gtfsInspection = try GTFSFeedInspector.inspect(URL(fileURLWithPath: CommandLine.arguments[4]))
        precondition(gtfsInspection.busRouteCount == 1, "The GTFS fixture must contain one bus route")
        precondition(gtfsInspection.quality.busTripCount == 1, "The GTFS fixture must contain one bus trip")
        precondition(gtfsInspection.busTripSchedules.count == 1, "The GTFS fixture must contain one streamed schedule")
        try verifyStopTimesChecksumPropagates(in: URL(fileURLWithPath: CommandLine.arguments[5]))

        print("PASS: bounded ZIP streaming, complete CRC checks, and stop_times error propagation")
    }

    private static func verifyChecksumMismatch(in url: URL, entryName: String) throws {
        let archive = try ZIPArchiveReader(url: url)
        guard let entry = archive.entry(named: entryName) else {
            fatalError("The corrupted archive must contain \(entryName)")
        }
        do {
            try archive.forEachChunk(in: entry) { _ in }
        } catch let error as ZIPArchiveError {
            guard case let .checksumMismatch(name) = error, name == entryName else {
                throw error
            }
            return
        }
        throw SmokeError.checksumWasAccepted(entryName)
    }

    private static func verifyStopTimesChecksumPropagates(in url: URL) throws {
        var reachedStopTimes = false
        do {
            _ = try GTFSFeedInspector.inspect(url) { progress in
                reachedStopTimes = reachedStopTimes || progress.stage == .readingStopTimes
            }
        } catch let error as ZIPArchiveError {
            guard case .checksumMismatch("stop_times.txt") = error, reachedStopTimes else {
                throw error
            }
            return
        }
        throw SmokeError.checksumWasAccepted("stop_times.txt")
    }

    private enum SmokeError: Error {
        case callback
        case checksumWasAccepted(String)
    }
}
