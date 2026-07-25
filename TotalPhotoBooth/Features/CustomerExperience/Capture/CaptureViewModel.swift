import Foundation

struct CapturedPhoto: Identifiable, Equatable {
    let id = UUID()
    let index: Int
    let imageData: Data
}

@Observable
final class CaptureViewModel {
    enum Mode: Equatable {
        case fullSequence
        case retake(index: Int)
    }

    var totalPhotos: Int

    private(set) var capturedPhotos: [CapturedPhoto]
    private(set) var activeIndex: Int = 0
    private(set) var countdownValue: Int = 0
    var errorMessage: String?

    private let mode: Mode
    private let cameraService: CameraCaptureServiceProtocol
    private let countdownTick: () async -> Void
    private let onComplete: ([CapturedPhoto]) -> Void

    init(
        mode: Mode,
        existingPhotos: [CapturedPhoto],
        cameraService: CameraCaptureServiceProtocol,
        countdownTick: @escaping () async -> Void = { try? await Task.sleep(for: .seconds(1)) },
        onComplete: @escaping ([CapturedPhoto]) -> Void,
        totalPhotos: Int
    ) {
        self.mode = mode
        self.capturedPhotos = existingPhotos
        self.cameraService = cameraService
        self.countdownTick = countdownTick
        self.onComplete = onComplete
        self.totalPhotos = totalPhotos
    }

    func beginCaptureSequence() async {
        let indices: [Int]
        switch mode {
        case .fullSequence:
            indices = Array(0..<self.totalPhotos)
        case .retake(let index):
            indices = [index]
        }

        for (position, index) in indices.enumerated() {
            activeIndex = index
            for remaining in stride(from: 3, through: 1, by: -1) {
                countdownValue = remaining
                await countdownTick()
            }
            countdownValue = 0

            do {
                let imageData = try await cameraService.capturePhoto()
                let photo = CapturedPhoto(index: index, imageData: imageData)
                if index < capturedPhotos.count {
                    capturedPhotos[index] = photo
                } else {
                    capturedPhotos.append(photo)
                }
            } catch {
                errorMessage = error.localizedDescription
                return
            }

            let isLastPhoto = position == indices.count - 1
            if !isLastPhoto {
                await countdownTick()
            }
        }

        onComplete(capturedPhotos)
    }
}
