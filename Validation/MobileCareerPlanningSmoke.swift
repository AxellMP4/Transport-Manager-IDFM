import Foundation

@main
struct MobileCareerPlanningSmoke {
    static func main() {
        let choices = [
            MobileCareerLineChoice(id: "confirmed", label: "101", evidenceStatus: .confirmed, routeIDs: ["IDFM:C1", "IDFM:C2"]),
            MobileCareerLineChoice(id: "candidate", label: "102", evidenceStatus: .candidate, routeIDs: ["IDFM:C3"]),
            MobileCareerLineChoice(id: "planned", label: "103", evidenceStatus: .planned, routeIDs: ["IDFM:C4"])
        ]

        precondition(
            MobileCareerLineSelection.routeIDs(from: choices, selectedLineIDs: []) == Set(["IDFM:C1", "IDFM:C2"]),
            "Confirmed routes should be included without extra taps."
        )
        precondition(
            MobileCareerLineSelection.routeIDs(from: choices, selectedLineIDs: ["candidate", "planned"])
                == Set(["IDFM:C1", "IDFM:C2", "IDFM:C3"]),
            "A player may opt into an uncertain candidate, but a planned service must never start automatically."
        )
        print("PASS: mobile career route selection respects dated evidence")
    }
}
