import Foundation

@main
struct AccessoryAdvertisingSmoke {
    static func main() throws {
        campaignStartsAndStopsAtItsRecordedSimulationTime()
        advertisingRevenueRequiresActiveServiceDistance()
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
}
