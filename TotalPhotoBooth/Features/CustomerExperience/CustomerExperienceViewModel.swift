import Foundation

@Observable
final class CustomerExperienceViewModel {
    enum FlowStep: Equatable {
        case attract
        case capture(mode: CaptureViewModel.Mode, existingPhotos: [CapturedPhoto])
        case review(photos: [CapturedPhoto])
        case success
    }

    private(set) var step: FlowStep = .attract

    private let repository: PhotoSessionRepositoryProtocol

    init(repository: PhotoSessionRepositoryProtocol) {
        self.repository = repository
    }

    func startSession() {
        step = .capture(mode: .fullSequence, existingPhotos: [])
    }

    func captureSequenceCompleted(photos: [CapturedPhoto]) {
        step = .review(photos: photos)
    }

    func retake(index: Int, currentPhotos: [CapturedPhoto]) {
        step = .capture(mode: .retake(index: index), existingPhotos: currentPhotos)
    }

    func confirmAndSave() async throws {
        try await repository.save(PhotoSession())
        step = .success
    }

    func finishSession() {
        step = .attract
    }
}
