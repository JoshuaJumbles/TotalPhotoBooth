import Foundation

@Observable
final class ReviewViewModel {
    let photos: [CapturedPhoto]
    private(set) var isSaving: Bool = false
    var errorMessage: String?

    private let onRetake: (Int) -> Void
    private let onConfirm: () async throws -> Void

    init(
        photos: [CapturedPhoto],
        onRetake: @escaping (Int) -> Void,
        onConfirm: @escaping () async throws -> Void
    ) {
        self.photos = photos
        self.onRetake = onRetake
        self.onConfirm = onConfirm
    }

    func retake(at index: Int) {
        onRetake(index)
    }

    func confirm() async {
        isSaving = true
        defer { isSaving = false }
        do {
            try await onConfirm()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
