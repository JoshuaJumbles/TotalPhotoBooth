import Foundation

struct ReportGenerator {
    private let calendar: Calendar
    private let dayWindow: Int

    init(calendar: Calendar = .current, dayWindow: Int = 7) {
        self.calendar = calendar
        self.dayWindow = dayWindow
    }

    func generateReport(from sessions: [PhotoSession], referenceDate: Date = .now) -> ActivityReport {
        let today = calendar.startOfDay(for: referenceDate)
        let windowStart = calendar.date(byAdding: .day, value: -(dayWindow - 1), to: today) ?? today

        var countsByDay: [Date: Int] = [:]
        for session in sessions {
            let day = calendar.startOfDay(for: session.timestamp)
            guard day >= windowStart, day <= today else { continue }
            countsByDay[day, default: 0] += 1
        }

        var dailyCounts: [DailyCount] = []
        for offset in 0..<dayWindow {
            guard let day = calendar.date(byAdding: .day, value: offset, to: windowStart) else { continue }
            dailyCounts.append(DailyCount(date: day, count: countsByDay[day] ?? 0))
        }

        return ActivityReport(totalSessions: sessions.count, dailyCounts: dailyCounts)
    }
}
