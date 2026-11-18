import Foundation

/// The rhythm of a capture sequence. Production uses `.standard`; the flash
/// lead time comes from `FlashSettings` so it can be tuned in the booth.
struct CaptureTiming: Equatable {
    /// The countdown runs from this number down to 1.
    var countdownFrom: Int = 3
    var countdownStep: Duration = .seconds(1)
    /// How long the screen flash is on before the shutter, so the front
    /// camera's auto-exposure and white balance settle on the lit face.
    var flashLead: Duration = .milliseconds(400)
    /// How long the flash stays on after the shutter.
    var flashHold: Duration = .milliseconds(150)
    /// Reset time between photos: a beat to change pose.
    var pauseBetweenShots: Duration = .milliseconds(2500)

    static let standard = CaptureTiming()

    var countdownLength: Duration {
        countdownStep * countdownFrom
    }
}
