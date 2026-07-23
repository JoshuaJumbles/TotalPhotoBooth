import Foundation
import Testing
@testable import TotalPhotoBooth

struct ReportGeneratorTests {
    private let calendar = Calendar(identifier: .gregorian)

    private func date(daysAgo: Int, from reference: Date) -> Date {
        calendar.date(byAdding: .day, value: -daysAgo, to: reference)!
    }

    @Test func emptyInputProducesZeroedSevenDayWindow() {
        let reference = Date()
        let generator = ReportGenerator(calendar: calendar, dayWindow: 7)

        let report = generator.generateReport(from: [], referenceDate: reference)

        #expect(report.totalSessions == 0)
        #expect(report.dailyCounts.count == 7)
        #expect(report.dailyCounts.allSatisfy { $0.count == 0 })
    }

    @Test func totalSessionsCountsAllSessionsRegardlessOfWindow() {
        let reference = Date()
        let oldSession = PhotoSession(timestamp: date(daysAgo: 30, from: reference))
        let recentSession = PhotoSession(timestamp: reference)
        let generator = ReportGenerator(calendar: calendar, dayWindow: 7)

        let report = generator.generateReport(from: [oldSession, recentSession], referenceDate: reference)

        #expect(report.totalSessions == 2)
    }

    @Test func multipleSessionsSameDayAreGrouped() {
        let reference = Date()
        let sessions = [
            PhotoSession(timestamp: reference),
            PhotoSession(timestamp: reference.addingTimeInterval(60)),
            PhotoSession(timestamp: reference.addingTimeInterval(120))
        ]
        let generator = ReportGenerator(calendar: calendar, dayWindow: 7)

        let report = generator.generateReport(from: sessions, referenceDate: reference)

        #expect(report.dailyCounts.last?.count == 3)
    }

    @Test func sessionOutsideWindowIsExcludedFromDailyCounts() {
        let reference = Date()
        let outsideWindow = PhotoSession(timestamp: date(daysAgo: 10, from: reference))
        let generator = ReportGenerator(calendar: calendar, dayWindow: 7)

        let report = generator.generateReport(from: [outsideWindow], referenceDate: reference)

        #expect(report.totalSessions == 1)
        #expect(report.dailyCounts.allSatisfy { $0.count == 0 })
    }

    @Test func dailyCountsAreOrderedOldestToNewestEndingToday() {
        let reference = calendar.startOfDay(for: Date())
        let generator = ReportGenerator(calendar: calendar, dayWindow: 7)

        let report = generator.generateReport(from: [], referenceDate: reference)

        #expect(report.dailyCounts.last?.date == reference)
        #expect(report.dailyCounts.first?.date == date(daysAgo: 6, from: reference))
    }
}
