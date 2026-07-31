import Foundation
import UIKit

@Observable
final class CustomerExperienceViewModel {
    enum FlowStep: Equatable {
        case attract
        case capture(mode: CaptureViewModel.Mode, existingPhotos: [CapturedPhoto])
        case review(photos: [CapturedPhoto])
        case success(photoStrip: UIImage)
    }

    private(set) var step: FlowStep = .attract
    let previewView: UIView

    private let repository: PhotoSessionRepositoryProtocol
    private let cameraService: CameraCaptureServiceProtocol
    private let photoLibrarySaver: PhotoLibrarySaverProtocol
    private let isDebugMode: Bool

    init(repository: PhotoSessionRepositoryProtocol,
         cameraService: CameraCaptureServiceProtocol,
         photoLibrarySaver: PhotoLibrarySaverProtocol,
         isDebugMode: Bool = false) {
        self.repository = repository
        self.cameraService = cameraService
        self.photoLibrarySaver = photoLibrarySaver
        self.isDebugMode = isDebugMode
        self.previewView = cameraService.makePreviewView()
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

    func makeCaptureViewModel(
        mode: CaptureViewModel.Mode,
        existingPhotos: [CapturedPhoto],
        onComplete: @escaping ([CapturedPhoto]) -> Void
    ) -> CaptureViewModel {
        CaptureViewModel(
            mode: mode,
            existingPhotos: existingPhotos,
            cameraService: cameraService,
            onComplete: onComplete
        )
    }

    func confirmAndSave(photos: [CapturedPhoto]) async throws {
        if !isDebugMode {
            try await repository.save(PhotoSession())
        }
        let photoStrip = try CompositeImageRendererService.makeDoublePhotoStrip(photoData: photos.map { $0.imageData })
        try await photoLibrarySaver.save(image: photoStrip)
        step = .success(photoStrip: photoStrip)
    }

    func finishSession() {
        step = .attract
    }
}
