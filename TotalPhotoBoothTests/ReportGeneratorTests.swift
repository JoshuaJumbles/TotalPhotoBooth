import XCTest
@testable import TotalPhotoBooth

final class ReportGeneratorTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    private func date(daysAgo: Int, from reference: Date) -> Date {
        calendar.date(byAdding: .day, value: -daysAgo, to: reference)!
    }

    func testEmptyInputProducesZeroedSevenDayWindow() {
        let reference = Date()
        let generator = ReportGenerator(calendar: calendar, dayWindow: 7)

        let report = generator.generateReport(from: [], referenceDate: reference)

        XCTAssertEqual(report.totalSessions, 0)
        XCTAssertEqual(report.dailyCounts.count, 7)
        XCTAssertTrue(report.dailyCounts.allSatisfy { $0.count == 0 })
    }

    func testTotalSessionsCountsAllSessionsRegardlessOfWindow() {
        let reference = Date()
        let oldSession = PhotoSession(timestamp: date(daysAgo: 30, from: reference))
        let recentSession = PhotoSession(timestamp: reference)
        let generator = ReportGenerator(calendar: calendar, dayWindow: 7)

        let report = generator.generateReport(from: [oldSession, recentSession], referenceDate: reference)

        XCTAssertEqual(report.totalSessions, 2)
    }

    func testMultipleSessionsSameDayAreGrouped() {
        let reference = Date()
        let sessions = [
            PhotoSession(timestamp: reference),
            PhotoSession(timestamp: reference.addingTimeInterval(60)),
            PhotoSession(timestamp: reference.addingTimeInterval(120))
        ]
        let generator = ReportGenerator(calendar: calendar, dayWindow: 7)

        let report = generator.generateReport(from: sessions, referenceDate: reference)

        XCTAssertEqual(report.dailyCounts.last?.count, 3)
    }

    func testSessionOutsideWindowIsExcludedFromDailyCounts() {
        let reference = Date()
        let outsideWindow = PhotoSession(timestamp: date(daysAgo: 10, from: reference))
        let generator = ReportGenerator(calendar: calendar, dayWindow: 7)

        let report = generator.generateReport(from: [outsideWindow], referenceDate: reference)

        XCTAssertEqual(report.totalSessions, 1)
        XCTAssertTrue(report.dailyCounts.allSatisfy { $0.count == 0 })
    }

    func testDailyCountsAreOrderedOldestToNewestEndingToday() {
        let reference = calendar.startOfDay(for: Date())
        let generator = ReportGenerator(calendar: calendar, dayWindow: 7)

        let report = generator.generateReport(from: [], referenceDate: reference)

        XCTAssertEqual(report.dailyCounts.last?.date, reference)
        XCTAssertEqual(report.dailyCounts.first?.date, date(daysAgo: 6, from: reference))
    }
}
