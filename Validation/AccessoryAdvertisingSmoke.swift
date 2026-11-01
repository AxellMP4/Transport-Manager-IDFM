import Foundation

@main
struct AccessoryAdvertisingSmoke {
    static func main() throws {
        campaignStartsAndStopsAtItsRecordedSimulationTime()
        advertisingRevenueRequiresActiveServiceDistance()
        campaignBoundariesProrateMovementSegmentDistance()
        proratedSegmentsRetainCumulativeRounding()
        try legacyTripDistanceRecordsDecodeWithoutSegmentBounds()
        segmentedDistanceUsesCumulativeRounding()
        print("PASS: simulated advertising is optional, service-scoped, and rounded cumulatively")
    }

    private static func campaignStartsAndStopsAtItsRecordedSimulationTime() {
        let startedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let endedAt = startedAt.addingTimeInterval(3_600)
        let campaign = SimulatedAdvertisingCampaign(
            id: "advertising-smoke",
            startedAt: startedAt,
            endedAt: endedAt
        )

        precondition(!campaign.isActive(at: startedAt.addingTimeInterval(-1)))
        precondition(campaign.isActive(at: startedAt))
        precondition(campaign.isActive(at: endedAt.addingTimeInterval(-1)))
        precondition(!campaign.isActive(at: endedAt))
    }

    private static func advertisingRevenueRequiresActiveServiceDistance() {
        let startedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let endedAt = startedAt.addingTimeInterval(3_600)
        let campaign = SimulatedAdvertisingCampaign(
            id: "advertising-active",
            startedAt: startedAt,
            endedAt: endedAt
        )

        precondition(AccessoryRevenueRules.estimatedAdvertisingRevenue(
            campaign: campaign,
            at: startedAt.addingTimeInterval(-1),
            serviceDistanceMeters: 10_000,
            previousCampaignServiceDistanceMeters: 0,
            isServiceDistance: true
        ) == 0)
        precondition(AccessoryRevenueRules.estimatedAdvertisingRevenue(
            campaign: campaign,
            at: startedAt,
            serviceDistanceMeters: 1_500,
            previousCampaignServiceDistanceMeters: 0,
            isServiceDistance: false
        ) == 0)
        precondition(AccessoryRevenueRules.estimatedAdvertisingRevenue(
            campaign: campaign,
            at: startedAt,
            serviceDistanceMeters: 1_500,
            previousCampaignServiceDistanceMeters: 0,
            isServiceDistance: true
        ) > 0)
        precondition(AccessoryRevenueRules.estimatedAdvertisingRevenue(
            campaign: campaign,
            at: endedAt,
            serviceDistanceMeters: 10_000,
            previousCampaignServiceDistanceMeters: 0,
            isServiceDistance: true
        ) == 0)
        precondition(AccessoryRevenueRules.estimatedAdvertisingRevenue(
            campaign: nil,
            at: startedAt,
            serviceDistanceMeters: 10_000,
            previousCampaignServiceDistanceMeters: 0,
            isServiceDistance: true
        ) == 0)
        precondition(AccessoryRevenueRules.estimatedAdvertisingRevenue(
            campaign: campaign,
            at: startedAt,
            serviceDistanceMeters: -10_000,
            previousCampaignServiceDistanceMeters: 0,
            isServiceDistance: true
        ) == 0)
    }

    private static func segmentedDistanceUsesCumulativeRounding() {
        let startedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let campaign = SimulatedAdvertisingCampaign(id: "advertising-rounding", startedAt: startedAt)
        let firstSegment = AccessoryRevenueRules.estimatedAdvertisingRevenue(
            campaign: campaign,
            at: startedAt,
            serviceDistanceMeters: 1_500,
            previousCampaignServiceDistanceMeters: 0,
            isServiceDistance: true
        )
        let secondSegment = AccessoryRevenueRules.estimatedAdvertisingRevenue(
            campaign: campaign,
            at: startedAt,
            serviceDistanceMeters: 1_500,
            previousCampaignServiceDistanceMeters: 1_500,
            isServiceDistance: true
        )
        let combinedDistance = AccessoryRevenueRules.estimatedAdvertisingRevenue(
            campaign: campaign,
            at: startedAt,
            serviceDistanceMeters: 3_000,
            previousCampaignServiceDistanceMeters: 0,
            isServiceDistance: true
        )

        precondition(firstSegment + secondSegment == combinedDistance)
    }

    private static func campaignBoundariesProrateMovementSegmentDistance() {
        let segmentStartedAt = Date(timeIntervalSince1970: 1_800_100_000)
        let segmentEndsAt = segmentStartedAt.addingTimeInterval(480)
        let campaign = SimulatedAdvertisingCampaign(
            id: "advertising-partial-segment",
            startedAt: segmentStartedAt.addingTimeInterval(120),
            endedAt: segmentStartedAt.addingTimeInterval(360)
        )

        precondition(AccessoryRevenueRules.estimatedAdvertisingRevenue(
            campaign: campaign,
            segmentStartsAt: segmentStartedAt,
            segmentEndsAt: segmentEndsAt,
            serviceDistanceMeters: 8_000,
            previousCampaignServiceDistanceMeters: 0,
            isServiceDistance: true
        ) == 2)
    }

    private static func proratedSegmentsRetainCumulativeRounding() {
        let segmentStartedAt = Date(timeIntervalSince1970: 1_800_200_000)
        let campaign = SimulatedAdvertisingCampaign(
            id: "advertising-cumulative-proration",
            startedAt: segmentStartedAt.addingTimeInterval(30)
        )
        let firstSegmentEnd = segmentStartedAt.addingTimeInterval(60)
        let secondSegmentEnd = segmentStartedAt.addingTimeInterval(120)
        let firstBillableDistance = AccessoryRevenueRules.billableAdvertisingDistanceMeters(
            campaign: campaign,
            segmentStartsAt: segmentStartedAt,
            segmentEndsAt: firstSegmentEnd,
            serviceDistanceMeters: 1_000
        )
        let firstRevenue = AccessoryRevenueRules.estimatedAdvertisingRevenue(
            campaign: campaign,
            segmentStartsAt: segmentStartedAt,
            segmentEndsAt: firstSegmentEnd,
            serviceDistanceMeters: 1_000,
            previousCampaignServiceDistanceMeters: 0,
            isServiceDistance: true
        )
        let secondRevenue = AccessoryRevenueRules.estimatedAdvertisingRevenue(
            campaign: campaign,
            segmentStartsAt: firstSegmentEnd,
            segmentEndsAt: secondSegmentEnd,
            serviceDistanceMeters: 1_000,
            previousCampaignServiceDistanceMeters: firstBillableDistance,
            isServiceDistance: true
        )
        let combinedRevenue = AccessoryRevenueRules.estimatedAdvertisingRevenue(
            campaign: campaign,
            segmentStartsAt: segmentStartedAt,
            segmentEndsAt: secondSegmentEnd,
            serviceDistanceMeters: 2_000,
            previousCampaignServiceDistanceMeters: 0,
            isServiceDistance: true
        )

        precondition(firstBillableDistance == 500)
        precondition(firstRevenue + secondRevenue == combinedRevenue)
    }

    private static func legacyTripDistanceRecordsDecodeWithoutSegmentBounds() throws {
        let legacyJSON = #"{"eventSequence":1,"tripID":"trip-old","vehicleID":"bus-old","occurredAt":0,"distanceMeters":1200}"#
        let legacyRecord = try JSONDecoder().decode(TripDistanceRecord.self, from: Data(legacyJSON.utf8))
        precondition(legacyRecord.segmentStartedAt == nil)
        precondition(legacyRecord.segmentEndedAt == nil)
    }
}
