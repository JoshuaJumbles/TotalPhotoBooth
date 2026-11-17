import SwiftUI
import UIKit

/// Calls `action` when someone holds two fingers anywhere on screen for
/// `minimumDuration` — the staff-only way into the hidden menu.
///
/// SwiftUI's `LongPressGesture` can't require two touches, so this installs a
/// UIKit recognizer on the *window* while the view is on screen. Living on
/// the window means it sees touches over every kiosk screen (camera preview,
/// buttons) without sitting on top of them, and `cancelsTouchesInView =
/// false` plus simultaneous recognition keep it from stealing customer taps.
struct StaffGestureInstaller: UIViewRepresentable {
    var minimumDuration: TimeInterval = 2
    let action: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    func makeUIView(context: Context) -> InstallerView {
        let recognizer = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handle(_:))
        )
        recognizer.numberOfTouchesRequired = 2
        recognizer.minimumPressDuration = minimumDuration
        recognizer.allowableMovement = 40
        recognizer.cancelsTouchesInView = false
        recognizer.delaysTouchesBegan = false
        recognizer.delaysTouchesEnded = false
        recognizer.delegate = context.coordinator

        let view = InstallerView(recognizer: recognizer)
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: InstallerView, context: Context) {
        context.coordinator.action = action
        uiView.recognizer.minimumPressDuration = minimumDuration
    }

    static func dismantleUIView(_ uiView: InstallerView, coordinator: Coordinator) {
        uiView.uninstall()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var action: () -> Void

        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc func handle(_ recognizer: UILongPressGestureRecognizer) {
            if recognizer.state == .began {
                action()
            }
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }

    /// An invisible view whose only job is to move the recognizer onto
    /// whichever window it lands in, and off again when it leaves.
    final class InstallerView: UIView {
        let recognizer: UILongPressGestureRecognizer
        private weak var installedWindow: UIWindow?

        init(recognizer: UILongPressGestureRecognizer) {
            self.recognizer = recognizer
            super.init(frame: .zero)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) is not supported")
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard window !== installedWindow else { return }
            uninstall()
            if let window {
                window.addGestureRecognizer(recognizer)
                installedWindow = window
            }
        }

        func uninstall() {
            installedWindow?.removeGestureRecognizer(recognizer)
            installedWindow = nil
        }
    }
}
