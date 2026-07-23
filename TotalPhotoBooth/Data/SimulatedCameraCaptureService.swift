import UIKit

struct SimulatedCameraCaptureService: CameraCaptureServiceProtocol {
    func capturePhoto() async throws -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 400))
        let image = renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 400, height: 400))
        }
        return image.jpegData(compressionQuality: 0.8) ?? Data()
    }
}
