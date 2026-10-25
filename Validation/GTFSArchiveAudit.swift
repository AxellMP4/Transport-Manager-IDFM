import Foundation
import Darwin

@main
struct GTFSArchiveAudit {
    static func main() throws {
        guard CommandLine.arguments.count == 2 else {
            fputs("Usage: GTFSArchiveAudit <archive.zip>\n", stderr)
            exit(2)
        }
        let archiveURL = URL(fileURLWithPath: CommandLine.arguments[1])
        let inspection = try GTFSFeedInspector.inspect(archiveURL) { progress in
            if progress.stage == .tripDiagnostics,
               let completed = progress.completed,
               let total = progress.total,
               completed == 0 || completed == total || completed.isMultiple(of: 10_000) {
                report("PROGRESS trips=\(completed)/\(total)")
            } else if progress.stage != .tripDiagnostics {
                report("STAGE \(progress.stage.title)")
            }
        }
        let q = inspection.quality
        let motifs = GTFSServiceTripMotifCatalog.build(from: inspection.busTripSchedules)
        print("RESULT busRoutes=\(inspection.busRouteCount) busTrips=\(q.busTripCount) schedules=\(q.tripScheduleCount) busStopsGeolocated=\(inspection.busStopCount) feedStopRows=\(inspection.feedStopCount)")
        print("RESULT serviceRange=\(inspection.validFrom.map(isoDate) ?? "unknown")..\(inspection.validThrough.map(isoDate) ?? "unknown") calendars=\(inspection.serviceCalendars.count) activeServiceTripsMissing=\(q.tripsWithoutActiveServiceDates ?? -1)")
        print("RESULT tripsWithoutStopTimes=\(q.tripsWithoutStopTimes) incompleteTimes=\(q.tripsWithIncompleteTimes) invalidChronology=\(q.tripsWithInvalidChronology) invalidStopSequence=\(q.tripsWithInvalidStopSequence) fewerThanTwoStops=\(q.tripsWithTooFewStops)")
        print("RESULT tripsMissingCoordinates=\(q.tripsWithMissingStopCoordinates) tripsMissingStopRecords=\(q.tripsWithMissingStopRecords ?? -1) missingStopIDRows=\(q.missingStopIDRowCount ?? -1) invalidStopTimeRows=\(q.invalidStopTimeRowCount)")
        print("RESULT tripsWithoutShape=\(q.tripsWithoutShapeReference) unavailableShapeTrips=\(q.tripsWithUnavailableShape) unmatchedShapeTrips=\(q.tripsWithUnmatchedShapeStops ?? -1) referencedShapes=\(q.referencedShapeCount) availableShapes=\(q.availableShapeCount) invalidShapes=\(q.invalidShapeCount)")
        print("RESULT motifs=\(motifs.count) frequenciesFile=\(q.containsFrequenciesFile ?? false)")
        let issues: [GTFSImportTripIssue] = q.tripIssues ?? []
        let issueKinds = Dictionary(grouping: issues, by: { $0.issueKinds })
        print("RESULT tripsWithAnyIssue=\(issues.count) distinctIssueCombinations=\(issueKinds.count)")
        for kind in GTFSImportTripIssueKind.allCases {
            let affected = issues.filter { $0.issueKinds.contains(kind) }
            print("ISSUE \(kind.rawValue)=\(affected.count)")
        }
        let samples = issues.prefix(12)
        for issue in samples {
            let projections = issue.stopProjectionDiagnostics?.count ?? 0
            print("SAMPLE route=\(issue.routeID) trip=\(issue.tripID) shape=\(issue.shapeID ?? "-") kinds=\(issue.issueKinds.map(\.rawValue).sorted().joined(separator: ",")) projectionStops=\(projections)")
        }
        print("AUDIT_COMPLETE")
    }

    private static func isoDate(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.string(from: date)
    }

    private static func report(_ line: String) {
        print(line)
        fflush(stdout)
    }
}
