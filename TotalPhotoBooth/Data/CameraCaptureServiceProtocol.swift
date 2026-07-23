import Foundation
import UIKit

protocol CameraCaptureServiceProtocol {
    func startHardwareSession() async throws
    func endHardwareSession()
    func capturePhoto() async throws -> Data
    func makePreviewView() -> UIView
}
