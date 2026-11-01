import Foundation

@main
enum GameLaunchMenuFlowSmoke {
    static func main() {
        precondition(
            GameLaunchMenuFlow.destination(for: .continueCareer, hasActiveCareer: false) == .welcome
        )
        precondition(
            GameLaunchMenuFlow.destination(for: .continueCareer, hasActiveCareer: true) == .resumeCareer
        )
        precondition(
            GameLaunchMenuFlow.destination(for: .newCareer, hasActiveCareer: false) == .careerSetup
        )
        precondition(
            GameLaunchMenuFlow.destination(for: .newCareer, hasActiveCareer: true) == .careerSetup
        )
        precondition(
            GameLaunchMenuFlow.destination(for: .chooseScenario, hasActiveCareer: true) == .scenarioPicker
        )
        precondition(
            GameLaunchMenuFlow.destination(for: .importCareer, hasActiveCareer: true) == .importPicker
        )
        precondition(
            GameLaunchMenuFlow.destination(for: .options, hasActiveCareer: true) == .options
        )

        let summaryJSON = Data("""
        {
          "id": "career-1",
          "scenarioID": "dsp-45",
          "depotID": "saint-maur",
          "createdAt": "2026-10-01T08:00:00Z",
          "updatedAt": "2026-10-31T12:30:00Z",
          "simulatedAt": "2026-10-03T09:15:00Z",
          "cashBalance": 250000,
          "ownedBuses": "ignored by the lightweight menu summary"
        }
        """.utf8)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let summary = try! decoder.decode(SavedCareerSummary.self, from: summaryJSON)
        precondition(summary.id == "career-1")
        precondition(summary.scenarioID == "dsp-45")
        precondition(summary.depotID == "saint-maur")
        precondition(summary.cashBalance == 250000)
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
        precondition(utcCalendar.component(.year, from: summary.updatedAt) == 2026)
        precondition(utcCalendar.component(.month, from: summary.updatedAt) == 10)
        precondition(utcCalendar.component(.day, from: summary.updatedAt) == 31)

        let existingID = GameLaunchMenuFlow.importIdentity(
            sourceID: "career-1",
            existingIDs: ["career-1"]
        ) { "career-copy" }
        precondition(existingID.id == "career-copy")
        precondition(existingID.sourceID == "career-1")
        precondition(existingID.wasCopied)

        let freshID = GameLaunchMenuFlow.importIdentity(sourceID: "new-career", existingIDs: ["career-1"])
        precondition(freshID.id == "new-career")
        precondition(!freshID.wasCopied)

        let menuState = GameLaunchMenuFlow.destination(for: .importCareer, hasActiveCareer: true)
        precondition(menuState == .importPicker)
        print("PASS: launch actions, lightweight saved-career summaries, and collision-safe imports")
    }
}
