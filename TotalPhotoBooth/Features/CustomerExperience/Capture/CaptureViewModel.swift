import Foundation
import UIKit

struct CapturedPhoto: Identifiable, Equatable {
    let id = UUID()
    let index: Int
    let imageData: Data
}

private enum PhotoProcessingError: LocalizedError {
    case invalidImageData

    var errorDescription: String? {
        "The captured photo could not be processed."
    }
}

@Observable
final class CaptureViewModel {
    enum Mode: Equatable {
        case fullSequence
        case retake(index: Int)
    }

    enum Phase: Equatable {
        /// Nothing on screen yet, or the sequence has finished.
        case idle
        case countdown(remaining: Int)
        /// The screen flash is up and the shutter is about to fire.
        case flash
        /// A beat between photos to reset and change pose.
        case betweenShots
    }

    private(set) var capturedPhotos: [CapturedPhoto]
    /// Small previews for the thumbnail tray, keyed by photo index, made once
    /// per photo rather than decoding full JPEGs on every render.
    private(set) var thumbnails: [Int: UIImage] = [:]
    private(set) var activeIndex: Int = 0
    private(set) var phase: Phase = .idle
    /// When the current countdown began, so the ring can drain smoothly
    /// instead of stepping once a second.
    private(set) var countdownStartedAt: Date?
    var errorMessage: String?

    let timing: CaptureTiming

    private let mode: Mode
    private let cameraService: CameraCaptureServiceProtocol
    private let screenFlash: ScreenFlashProtocol
    /// `@MainActor`-typed on purpose: unannotated, a `Duration` argument can
    /// arrive as garbage under this project's concurrency settings.
    private let sleep: @MainActor (Duration) async -> Void
    private let now: () -> Date
    private let onComplete: ([CapturedPhoto]) -> Void
    private let onCancel: () -> Void
    /// Set by Cancel. `sleep` swallows task cancellation, so the sequence
    /// checks this explicitly rather than trusting the sleep to throw.
    private var isCancelled = false

    private var shouldStop: Bool { isCancelled || Task.isCancelled }

    init(
        mode: Mode,
        existingPhotos: [CapturedPhoto],
        cameraService: CameraCaptureServiceProtocol,
        screenFlash: ScreenFlashProtocol,
        timing: CaptureTiming = .standard,
        sleep: @escaping @MainActor (Duration) async -> Void = { try? await Task.sleep(for: $0) },
        now: @escaping () -> Date = { Date() },
        onComplete: @escaping ([CapturedPhoto]) -> Void,
        onCancel: @escaping () -> Void = {}
    ) {
        self.mode = mode
        self.capturedPhotos = existingPhotos
        self.cameraService = cameraService
        self.screenFlash = screenFlash
        self.timing = timing
        self.sleep = sleep
        self.now = now
        self.onComplete = onComplete
        self.onCancel = onCancel
        for photo in existingPhotos {
            thumbnails[photo.index] = Self.thumbnail(from: photo.imageData)
        }
    }

    /// Stops the sequence where it is — no further photos, no completion —
    /// and leaves capture.
    func cancel() {
        guard !isCancelled else { return }
        isCancelled = true
        onCancel()
    }

    /// The error alert's OK: leave capture the same way Cancel does, so the
    /// customer is never stranded on a frozen countdown.
    func dismissError() {
        errorMessage = nil
        cancel()
    }

    func beginCaptureSequence() async {
        let indices: [Int]
        switch mode {
        case .fullSequence:
            indices = Array(0..<CompositeImageRendererService.totalPhotos)
        case .retake(let index):
            indices = [index]
        }

        for (position, index) in indices.enumerated() {
            activeIndex = index

            countdownStartedAt = now()
            for remaining in stride(from: timing.countdownFrom, through: 1, by: -1) {
                phase = .countdown(remaining: remaining)
                await sleep(timing.countdownStep)
                if shouldStop { return }
            }
            countdownStartedAt = nil

            let rawData: Data
            do {
                guard let data = try await captureWithFlash() else { return }
                rawData = data
            } catch {
                if shouldStop { return }
                errorMessage = error.localizedDescription
                return
            }

            do {
                let imageData = try processCapturedImageData(rawData)
                store(CapturedPhoto(index: index, imageData: imageData))
            } catch {
                errorMessage = error.localizedDescription
                return
            }

            let isLastPhoto = position == indices.count - 1
            if !isLastPhoto {
                phase = .betweenShots
                await sleep(timing.pauseBetweenShots)
                if shouldStop { return }
            }
        }

        phase = .idle
        onComplete(capturedPhotos)
    }

    /// Flash on, let the camera settle, shoot, hold, flash off. Returns nil
    /// if the sequence was cancelled. The flash always ends on the way out —
    /// cancelled, failed, or done — so the screen never stays at full blast.
    private func captureWithFlash() async throws -> Data? {
        phase = .flash
        screenFlash.begin()
        defer {
            screenFlash.end()
            phase = .idle
        }

        await sleep(timing.flashLead)
        if shouldStop { return nil }

        let data = try await cameraService.capturePhoto()
        if shouldStop { return nil }

        await sleep(timing.flashHold)
        return shouldStop ? nil : data
    }

    private func store(_ photo: CapturedPhoto) {
        if photo.index < capturedPhotos.count {
            capturedPhotos[photo.index] = photo
        } else {
            capturedPhotos.append(photo)
        }
        thumbnails[photo.index] = Self.thumbnail(from: photo.imageData)
    }

    private static func thumbnail(from data: Data) -> UIImage? {
        UIImage(data: data)?.preparingThumbnail(of: CGSize(width: 400, height: 400 / CompositeImageRendererService.pictureAspectRatio))
    }

    private func processCapturedImageData(_ rawData: Data) throws -> Data {
        guard let rawImage = UIImage(data: rawData) else {
            throw PhotoProcessingError.invalidImageData
        }
        let croppedImage = rawImage.croppedToAspectRatio(
            CompositeImageRendererService.pictureAspectRatio,
            verticalAlignment: CompositeImageRendererService.pictureCropAlignment
        )
        guard let croppedData = croppedImage.jpegData(compressionQuality: 0.8) else {
            throw PhotoProcessingError.invalidImageData
        }
        return croppedData
    }
}
