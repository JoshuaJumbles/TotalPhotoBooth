import Foundation
import Testing
import UIKit
@testable import TotalPhotoBooth

struct UIImageAspectRatioCroppingTests {
    @Test func cropsWidthWhenSourceIsWiderThanTarget() {
        let source = UIImage(color: .red, size: CGSize(width: 200, height: 100))!

        let cropped = source.croppedToAspectRatio(1.0)

        #expect(cropped.size.width == 100)
        #expect(cropped.size.height == 100)
    }

    @Test func cropsHeightWhenSourceIsTallerThanTarget() {
        let source = UIImage(color: .red, size: CGSize(width: 100, height: 200))!

        let cropped = source.croppedToAspectRatio(1.0)

        #expect(cropped.size.width == 100)
        #expect(cropped.size.height == 100)
    }

    @Test func topAlignmentKeepsContentFromTheSourcesTopEdge() {
        // Top half red, bottom half blue -- pinned to scale 1 so pngData()
        // comparisons below are deterministic regardless of the host device's
        // screen scale.
        let size = CGSize(width: 100, height: 200)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let source = renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 100, width: 100, height: 100))
        }

        let topCropped = source.croppedToAspectRatio(1.0, verticalAlignment: .top)
        let bottomCropped = source.croppedToAspectRatio(1.0, verticalAlignment: .bottom)

        let expectedRedSquare = UIImage(color: .red, size: CGSize(width: 100, height: 100))!
        let expectedBlueSquare = UIImage(color: .blue, size: CGSize(width: 100, height: 100))!

        // A center crop of this source would also land entirely in the red band
        // (crop is 100x100 out of 100x200), so it's important that .bottom is
        // checked too -- that's the only way to catch a sign error in the offset
        // math that happened to still pass for .top.
        #expect(topCropped.pngData() == expectedRedSquare.pngData())
        #expect(bottomCropped.pngData() == expectedBlueSquare.pngData())
    }
}
