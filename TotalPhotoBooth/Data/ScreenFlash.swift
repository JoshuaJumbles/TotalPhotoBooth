import UIKit

/// The hardware side of the screen flash: driving the display to full
/// brightness while the flash overlay is up, then putting it back.
protocol ScreenFlashProtocol: AnyObject {
    func begin()
    func end()
}

final class ScreenBrightnessFlash: ScreenFlashProtocol {
    /// The brightness to restore; non-nil only while a flash is on.
    private var savedBrightness: CGFloat?

    func begin() {
        guard savedBrightness == nil, let screen else { return }
        savedBrightness = screen.brightness
        screen.brightness = 1
    }

    func end() {
        guard let saved = savedBrightness, let screen else { return }
        screen.brightness = saved
        savedBrightness = nil
    }

    /// `UIScreen.main` is deprecated; go through the active window scene.
    private var screen: UIScreen? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return (scenes.first { $0.activationState == .foregroundActive } ?? scenes.first)?.screen
    }
}
