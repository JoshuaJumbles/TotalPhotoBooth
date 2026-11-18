@testable import TotalPhotoBooth

final class FakeScreenFlash: ScreenFlashProtocol {
    private(set) var beginCount = 0
    private(set) var endCount = 0
    var isOn: Bool { beginCount > endCount }

    func begin() { beginCount += 1 }
    func end() { endCount += 1 }
}
