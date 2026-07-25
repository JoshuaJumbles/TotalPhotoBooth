//
//  CompositeImageRendererService.swift
//  TotalPhotoBooth
//
//  Created by Joshua Jumbles on 7/23/26.
//

import SwiftUI
import UIKit

enum CompositeImageRendererService {
    static let ppi: CGFloat = 160

    static let totalPhotos: Int = 3

    static let printWidthInches: CGFloat = 4
    static let printHeightInches: CGFloat = 6
    static let bufferInches: CGFloat = 0.1

    static var printWidth: CGFloat { ppi * printWidthInches }
    static var printHeight: CGFloat { ppi * printHeightInches }
    static var buffer: CGFloat { ppi * bufferInches }

    //Per the design spec from old photo booth app
    static let pictureAspectRatio: CGFloat = 500 / 580

    static var pictureWidth: CGFloat {
        (printWidth / 2) - (2 * buffer)
    }
    static var pictureHeight: CGFloat { pictureWidth * pictureAspectRatio }

    static let brandImage = UIImage(named: "TotalRecallLogoQRCombo")

    static var brandImageWidth: CGFloat {
        pictureWidth
    }
    static var brandImageHeight: CGFloat {
        guard let brandImage = brandImage else { return 0 }
        let aspectRatio = brandImage.size.height / brandImage.size.width
        return brandImageWidth * aspectRatio
    }
    static var brandImageY: CGFloat {
        let i:CGFloat = CGFloat(totalPhotos)
        let h = (printHeight - buffer * i - pictureHeight * i)
        let yOffset = (h - brandImageHeight) / 2
        return (printHeight - h) + yOffset
    }

    static func makeDoublePhotoStrip(photoData: [Data]) -> UIImage {
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(
                width: printWidth,
                height: printHeight
            )
        )
        let photoStripImage = makeSinglePhotoStrip(photoData: photoData)
        let image = renderer.image { (context) in
            UIColor.lightGray.setFill()
            context.fill(
                CGRect(
                    x: 0,
                    y: 0,
                    width: renderer.format.bounds.width,
                    height: renderer.format.bounds.height
                )
            )
            photoStripImage.draw(at: CGPoint(x: 0, y: 0))
            photoStripImage.draw(at: CGPoint(x: printWidth / 2, y: 0))
        }

        return image
    }

    static func makeSinglePhotoStrip(photoData: [Data]) -> UIImage {
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(
                width: printWidth / 2,
                height: printHeight
            )
        )

        let image = renderer.image { (context) in
            UIColor.white.setFill()
            context.fill(
                CGRect(
                    x: 0,
                    y: 0,
                    width: renderer.format.bounds.width,
                    height: renderer.format.bounds.height
                )
            )

            for (index, data) in photoData.enumerated() {
                guard let photoImage = UIImage(data: data) else { return }
                photoImage.draw(
                    in: CGRect(
                        x: buffer,
                        y: CGFloat(index) * pictureHeight + CGFloat(index + 1)
                            * buffer,
                        width: pictureWidth,
                        height: pictureHeight
                    )
                )
            }

            brandImage!.draw(
                in: CGRect(
                    x: buffer,
                    y: brandImageY,
                    width: brandImageWidth,
                    height: brandImageHeight
                )
            )
        }

        return image
    }
}

#Preview {
    let photoImages: [UIImage?] = [
        UIImage(color: .red), UIImage(color: .green), UIImage(color: .blue),
    ]
    let photoData = photoImages.map { $0!.pngData()! }
    VStack {
        Image(uiImage: CompositeImageRendererService.makeDoublePhotoStrip(photoData: photoData))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.indigo)
    .ignoresSafeArea()
}
