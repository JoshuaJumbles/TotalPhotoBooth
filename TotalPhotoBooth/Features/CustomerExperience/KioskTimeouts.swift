import Foundation

/// How long each customer-facing screen waits, untouched, before the kiosk
/// gives up and returns to Attract. Screens that ask for a quick decision
/// are short; Review is long because customers study their photos there.
struct KioskTimeouts {
    var pitch: Duration
    /// Review's quiet period before the "Still there?" warning appears.
    var reviewBeforeWarning: Duration
    /// Length of the "Still there?" countdown, in whole seconds.
    var reviewWarningSeconds: Int
    var success: Duration

    static let standard = KioskTimeouts(
        pitch: .seconds(30),
        reviewBeforeWarning: .seconds(105),
        reviewWarningSeconds: 15,
        success: .seconds(20)
    )
}
