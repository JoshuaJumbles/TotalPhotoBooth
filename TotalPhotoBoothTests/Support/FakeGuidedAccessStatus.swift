import Foundation
@testable import TotalPhotoBooth

@Observable
final class FakeGuidedAccessStatus: GuidedAccessStatusProviding {
    var isEnabled: Bool

    init(isEnabled: Bool = false) {
        self.isEnabled = isEnabled
    }
}
