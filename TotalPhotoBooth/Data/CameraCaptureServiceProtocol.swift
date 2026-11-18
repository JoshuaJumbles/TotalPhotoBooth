import Foundation
import UIKit

protocol CameraCaptureServiceProtocol {
    func startHardwareSession() async throws
    func endHardwareSession()
    func capturePhoto() async throws -> Data
    func makePreviewView() -> UIView
    /// A fresh stream of coarse brightness frames for motion wake. Each call
    /// replaces (and finishes) the previous stream, so every Kiosk Mode run
    /// gets its own.
    func makeLumaFrameStream() -> AsyncStream<LumaGrid>
}
