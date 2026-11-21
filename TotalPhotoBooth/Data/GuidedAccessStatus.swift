import UIKit

/// Whether the iPad is locked to this app with Guided Access.
///
/// On an unsupervised iPad, Guided Access is turned on by staff (triple-click
/// Home), never by the app, so all the app can do is watch for it: show staff
/// whether the booth is locked, and warn before starting an unlocked kiosk.
protocol GuidedAccessStatusProviding: AnyObject {
    var isEnabled: Bool { get }
}

/// The system's Guided Access state, kept current as staff turn it on or off.
@Observable
final class SystemGuidedAccessStatus: GuidedAccessStatusProviding {
    private(set) var isEnabled: Bool
    @ObservationIgnored private var observer: (any NSObjectProtocol)?

    init(notificationCenter: NotificationCenter = .default) {
        isEnabled = UIAccessibility.isGuidedAccessEnabled
        observer = notificationCenter.addObserver(
            forName: UIAccessibility.guidedAccessStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.isEnabled = UIAccessibility.isGuidedAccessEnabled
            }
        }
    }
}
