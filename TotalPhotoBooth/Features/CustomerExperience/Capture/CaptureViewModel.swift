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

    static let totalPhotos = 4

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
        onComplete: @escaping ([CapturedPhoto]) -> Void
    ) {
        self.mode = mode
        self.capturedPhotos = existingPhotos
        self.cameraService = cameraService
        self.countdownTick = countdownTick
        self.onComplete = onComplete
    }

    func beginCaptureSequence() async {
        let indices: [Int]
        switch mode {
        case .fullSequence:
            indices = Array(0..<Self.totalPhotos)
        case .retake(let index):
            indices = [index]
        }

        for index in indices {
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
        }

        onComplete(capturedPhotos)
    }
}
