import Foundation
@testable import TotalPhotoBooth

final class FakeCameraCaptureService: CameraCaptureServiceProtocol {
    var imageData: Data
    var captureError: Error?
    private(set) var captureCount = 0

    init(imageData: Data = Data([0x01, 0x02, 0x03])) {
        self.imageData = imageData
    }

    func capturePhoto() async throws -> Data {
        captureCount += 1
        if let captureError {
            throw captureError
        }
        return imageData
    }
}
