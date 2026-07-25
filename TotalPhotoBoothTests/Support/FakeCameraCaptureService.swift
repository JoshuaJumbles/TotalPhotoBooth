import Foundation
import UIKit
@testable import TotalPhotoBooth

final class FakeCameraCaptureService: CameraCaptureServiceProtocol {
    var imageData: Data
    var captureError: Error?
    var startHardwareSessionError: Error?
    private(set) var captureCount = 0
    private(set) var startHardwareSessionCallCount = 0
    private(set) var endHardwareSessionCallCount = 0

    init(imageData: Data = UIImage(color: .red, size: CGSize(width: 400, height: 400))!.pngData()!) {
        self.imageData = imageData
    }

    func startHardwareSession() async throws {
        startHardwareSessionCallCount += 1
        if let startHardwareSessionError {
            throw startHardwareSessionError
        }
    }

    func endHardwareSession() {
        endHardwareSessionCallCount += 1
    }

    func capturePhoto() async throws -> Data {
        captureCount += 1
        if let captureError {
            throw captureError
        }
        return imageData
    }

    func makePreviewView() -> UIView {
        UIView()
    }
}
