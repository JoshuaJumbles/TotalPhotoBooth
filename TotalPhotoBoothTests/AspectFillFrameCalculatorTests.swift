import Foundation
import Testing
@testable import TotalPhotoBooth

struct AspectFillFrameCalculatorTests {
    // Portrait source (100x200) into a square container (100x100):
    // scale = max(100/100, 100/200) = 1.0 -> scaled size stays 100x200,
    // giving 100pt of vertical excess to position.
    private let containerSize = CGSize(width: 100, height: 100)
    private let sourceSize = CGSize(width: 100, height: 200)

    @Test func topAlignsToTheContainersTopEdge() {
        let frame = AspectFillFrameCalculator.frame(
            containerSize: containerSize,
            sourceSize: sourceSize,
            verticalAlignment: .top
        )

        #expect(frame.origin.y == 0)
        #expect(frame.size == CGSize(width: 100, height: 200))
    }

    @Test func centerSplitsTheExcessEvenly() {
        let frame = AspectFillFrameCalculator.frame(
            containerSize: containerSize,
            sourceSize: sourceSize,
            verticalAlignment: .center
        )

        #expect(frame.origin.y == -50)
    }

    @Test func bottomAlignsToTheContainersBottomEdge() {
        let frame = AspectFillFrameCalculator.frame(
            containerSize: containerSize,
            sourceSize: sourceSize,
            verticalAlignment: .bottom
        )

        #expect(frame.origin.y == -100)
    }

    @Test func horizontalPositionIsAlwaysCenteredRegardlessOfVerticalAlignment() {
        let wideContainer = CGSize(width: 100, height: 200)
        let wideSource = CGSize(width: 200, height: 100)
        // scale = max(100/200, 200/100) = 2.0 -> scaled size 400x200
        // x = (100-400)/2 = -150, independent of vertical alignment.

        let top = AspectFillFrameCalculator.frame(containerSize: wideContainer, sourceSize: wideSource, verticalAlignment: .top)
        let bottom = AspectFillFrameCalculator.frame(containerSize: wideContainer, sourceSize: wideSource, verticalAlignment: .bottom)

        #expect(top.origin.x == -150)
        #expect(bottom.origin.x == -150)
    }
}
