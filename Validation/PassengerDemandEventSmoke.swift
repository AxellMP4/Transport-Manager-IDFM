import Foundation

@main
struct PassengerDemandEventSmoke {
    static func main() {
        saturdayMarketCreatesDeterministicEstimatedDemand()
        ordinaryStopsHaveNoEventDemand()
        sportsAndExhibitionSitesProduceLocalEvents()
        eventDemandIsBoundedByTheBaseEstimate()
        print("PASS: local event demand is deterministic, venue-scoped and estimated")
    }

    private static func saturdayMarketCreatesDeterministicEstimatedDemand() {
        let saturdayAtMarket = parisDate(year: 2026, month: 10, day: 31, hour: 10)
        let effect = LocalPassengerDemandRules.effect(
            stopID: "market-stop",
            stopName: "Marché de Nogent",
            at: saturdayAtMarket,
            randomSeed: 42
        )

        precondition(effect?.displayName == "Marché local (simulation)")
        precondition(effect?.additionalArrivals(for: 20) ?? 0 > 0)
        precondition(effect == LocalPassengerDemandRules.effect(
            stopID: "market-stop",
            stopName: "Marché de Nogent",
            at: saturdayAtMarket,
            randomSeed: 42
        ))

        let fridayAtMarket = parisDate(year: 2026, month: 10, day: 30, hour: 10)
        precondition(LocalPassengerDemandRules.effect(
            stopID: "market-stop",
            stopName: "Marché de Nogent",
            at: fridayAtMarket,
            randomSeed: 42
        ) == nil)
    }

    private static func ordinaryStopsHaveNoEventDemand() {
        let saturdayAtStop = parisDate(year: 2026, month: 10, day: 31, hour: 10)
        precondition(LocalPassengerDemandRules.effect(
            stopID: "ordinary-stop",
            stopName: "Mairie",
            at: saturdayAtStop,
            randomSeed: 42
        ) == nil)
    }

    private static func sportsAndExhibitionSitesProduceLocalEvents() {
        let weekendDates = [
            parisDate(year: 2026, month: 10, day: 30, hour: 18),
            parisDate(year: 2026, month: 10, day: 31, hour: 18),
            parisDate(year: 2026, month: 11, day: 1, hour: 18)
        ]
        let sportsEffects = weekendDates.compactMap { date in
            LocalPassengerDemandRules.effect(
                stopID: "stadium-stop",
                stopName: "Stade du Centre",
                at: date,
                randomSeed: 42
            )
        }
        precondition(sportsEffects.count == 1)
        precondition(sportsEffects.first?.displayName == "Affluence sportive locale (simulation)")

        let exhibitionAtWeekend = parisDate(year: 2026, month: 10, day: 31, hour: 10)
        precondition(LocalPassengerDemandRules.effect(
            stopID: "exhibition-stop",
            stopName: "Parc des expositions",
            at: exhibitionAtWeekend,
            randomSeed: 42
        )?.displayName == "Salon local (simulation)")
    }

    private static func eventDemandIsBoundedByTheBaseEstimate() {
        let saturdayAtMarket = parisDate(year: 2026, month: 10, day: 31, hour: 10)
        guard let effect = LocalPassengerDemandRules.effect(
            stopID: "market-stop",
            stopName: "Marché de Nogent",
            at: saturdayAtMarket,
            randomSeed: 42
        ) else {
            preconditionFailure("The market should have a simulated local event at this time.")
        }
        precondition(effect.additionalArrivals(for: 0) == 0)
        precondition(effect.additionalArrivals(for: 20) <= 20)
    }

    private static func parisDate(year: Int, month: Int, day: Int, hour: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = GTFSServiceDate.parisTimeZone
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }
}
