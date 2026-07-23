import AVFoundation

enum CameraCaptureError: LocalizedError {
    case permissionDenied
    case deviceUnavailable
    case configurationFailed
    case captureFailed

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Camera access was denied."
        case .deviceUnavailable:
            return "No front camera is available on this device."
        case .configurationFailed:
            return "The camera could not be configured."
        case .captureFailed:
            return "The photo could not be captured."
        }
    }
}

final class AVFoundationCameraCaptureService: NSObject, CameraCaptureServiceProtocol {
    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var isConfigured = false
    private var continuation: CheckedContinuation<Data, Error>?

    func capturePhoto() async throws -> Data {
        try await configureSessionIfNeeded()
        if !session.isRunning {
            session.startRunning()
        }
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
        }
    }

    private func configureSessionIfNeeded() async throws {
        guard !isConfigured else { return }

        guard await AVCaptureDevice.requestAccess(for: .video) else {
            throw CameraCaptureError.permissionDenied
        }
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            throw CameraCaptureError.deviceUnavailable
        }

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else {
            throw CameraCaptureError.configurationFailed
        }
        session.addInput(input)

        guard session.canAddOutput(photoOutput) else {
            throw CameraCaptureError.configurationFailed
        }
        session.addOutput(photoOutput)

        isConfigured = true
    }
}

extension AVFoundationCameraCaptureService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        defer { continuation = nil }
        if let error {
            continuation?.resume(throwing: error)
        } else if let data = photo.fileDataRepresentation() {
            continuation?.resume(returning: data)
        } else {
            continuation?.resume(throwing: CameraCaptureError.captureFailed)
        }
    }
}
