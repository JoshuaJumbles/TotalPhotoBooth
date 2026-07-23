import Foundation

protocol CameraCaptureServiceProtocol {
    func capturePhoto() async throws -> Data
}
