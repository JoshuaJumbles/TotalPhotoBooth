import AVFoundation
import UIKit

enum CameraCaptureError: LocalizedError {
    case permissionDenied
    case deviceUnavailable
    case configurationFailed
    case captureFailed
    case sessionNotStarted

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
        case .sessionNotStarted:
            return "The camera session hasn't been started yet."
        }
    }
}

final class AVFoundationCameraCaptureService: NSObject, CameraCaptureServiceProtocol {
    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var isConfigured = false
    private var continuation: CheckedContinuation<Data, Error>?

    func startHardwareSession() async throws {
        try await configureSessionIfNeeded()
        if !session.isRunning {
            session.startRunning()
        }
    }

    func endHardwareSession() {
        if session.isRunning {
            session.stopRunning()
        }
    }

    func capturePhoto() async throws -> Data {
        guard isConfigured, session.isRunning else {
            throw CameraCaptureError.sessionNotStarted
        }
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
        }
    }

    func makePreviewView() -> UIView {
        VideoPreviewUIView(session: session)
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

private final class VideoPreviewUIView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    private var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    init(session: AVCaptureSession) {
        super.init(frame: .zero)
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
