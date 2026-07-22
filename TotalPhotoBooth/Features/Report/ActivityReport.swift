import Foundation

struct DailyCount: Identifiable, Equatable {
    let date: Date
    let count: Int

    var id: Date { date }
}

struct ActivityReport: Equatable {
    let totalSessions: Int
    let dailyCounts: [DailyCount]
}
