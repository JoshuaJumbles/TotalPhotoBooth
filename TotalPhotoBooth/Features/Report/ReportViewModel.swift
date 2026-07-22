import Foundation

@Observable
final class ReportViewModel {
    private(set) var report: ActivityReport?
    private(set) var isLoading: Bool = false
    var errorMessage: String?

    private let repository: PhotoSessionRepositoryProtocol
    private let reportGenerator: ReportGenerator

    init(repository: PhotoSessionRepositoryProtocol, reportGenerator: ReportGenerator = ReportGenerator()) {
        self.repository = repository
        self.reportGenerator = reportGenerator
    }

    func loadReport() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let sessions = try await repository.fetchAll()
            report = reportGenerator.generateReport(from: sessions)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
