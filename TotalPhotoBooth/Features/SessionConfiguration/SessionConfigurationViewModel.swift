import Foundation

@Observable
final class SessionConfigurationViewModel {
    private(set) var sessionCount: Int = 0
    private(set) var isPresentingCapture: Bool = false
    var errorMessage: String?

    private let repository: PhotoSessionRepositoryProtocol

    init(repository: PhotoSessionRepositoryProtocol) {
        self.repository = repository
    }

    func loadInitialCount() async {
        do {
            sessionCount = try await repository.fetchAll().count
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startSession() {
        isPresentingCapture = true
    }

    func endSession() async {
        isPresentingCapture = false
        await loadInitialCount()
    }

    func makeCaptureViewModel() -> CaptureViewModel {
        CaptureViewModel(repository: repository)
    }
}
