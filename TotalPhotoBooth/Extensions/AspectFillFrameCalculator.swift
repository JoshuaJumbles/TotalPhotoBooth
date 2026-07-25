//
//  AspectFillFrameCalculator.swift
//  TotalPhotoBooth
//
//  Created by Joshua Jumbles on 7/25/26.
//

import CoreGraphics

enum AspectFillFrameCalculator {
    /// Reproduces the scale `AVLayerVideoGravity.resizeAspectFill` would use to cover
    /// `containerSize` with `sourceSize`, but positions the result per `verticalAlignment`
    /// instead of always centering it. Horizontal position is always centered -- only the
    /// vertical anchor is ever meaningful for this app's portrait-source/landscape-target
    /// pairing.
    static func frame(containerSize: CGSize, sourceSize: CGSize, verticalAlignment: CropVerticalAlignment) -> CGRect {
        let scale = max(containerSize.width / sourceSize.width, containerSize.height / sourceSize.height)
        let scaledSize = CGSize(width: sourceSize.width * scale, height: sourceSize.height * scale)

        let x = (containerSize.width - scaledSize.width) / 2
        let y: CGFloat
        switch verticalAlignment {
        case .top:
            y = 0
        case .center:
            y = (containerSize.height - scaledSize.height) / 2
        case .bottom:
            y = containerSize.height - scaledSize.height
        }

        return CGRect(x: x, y: y, width: scaledSize.width, height: scaledSize.height)
    }
}
