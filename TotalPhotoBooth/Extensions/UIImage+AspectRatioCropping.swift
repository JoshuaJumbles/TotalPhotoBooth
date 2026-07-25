//
//  UIImage+AspectRatioCropping.swift
//  TotalPhotoBooth
//
//  Created by Joshua Jumbles on 7/25/26.
//

import UIKit

enum CropVerticalAlignment {
    case top, center, bottom
}

extension UIImage {
    func croppedToAspectRatio(_ targetAspectRatio: CGFloat, verticalAlignment: CropVerticalAlignment = .center) -> UIImage {
        let sourceAspectRatio = size.width / size.height
        let cropSize: CGSize
        if sourceAspectRatio > targetAspectRatio {
            cropSize = CGSize(width: size.height * targetAspectRatio, height: size.height)
        } else {
            cropSize = CGSize(width: size.width, height: size.width / targetAspectRatio)
        }

        let xOffset = (size.width - cropSize.width) / 2
        let yOffset: CGFloat
        switch verticalAlignment {
        case .top:
            yOffset = 0
        case .center:
            yOffset = (size.height - cropSize.height) / 2
        case .bottom:
            yOffset = size.height - cropSize.height
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: cropSize, format: format)
        return renderer.image { _ in
            self.draw(at: CGPoint(x: -xOffset, y: -yOffset))
        }
    }
}
