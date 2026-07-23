import Foundation

@Observable
final class CaptureViewModel {
    private(set) var capturedCount: Int = 0
    private(set) var isSaving: Bool = false
    var errorMessage: String?

    private let repository: PhotoSessionRepositoryProtocol

    init(repository: PhotoSessionRepositoryProtocol) {
        self.repository = repository
    }

    func capturePhoto() async {
        isSaving = true
        defer { isSaving = false }
        do {
            try await repository.save(PhotoSession())
            capturedCount += 1
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
