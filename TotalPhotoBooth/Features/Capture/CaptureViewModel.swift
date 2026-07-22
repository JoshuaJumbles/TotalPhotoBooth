import Foundation

@Observable
final class CaptureViewModel {
    private(set) var sessionCount: Int = 0
    private(set) var isSaving: Bool = false
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

    func capturePhoto() async {
        isSaving = true
        defer { isSaving = false }
        do {
            try await repository.save(PhotoSession())
            sessionCount += 1
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
