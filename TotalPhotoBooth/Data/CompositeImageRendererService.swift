//
//  CompositeImageService.swift
//  TotalPhotoBooth
//
//  Created by Joshua Jumbles on 7/23/26.
//

import SwiftUI
import UIKit

struct CompositeImageRendererService {
    let ppi: CGFloat = 160

    let printWidthInches: CGFloat = 4
    let printHeightInches: CGFloat = 6
    let bufferInches: CGFloat = 0.1

    var printWidth: CGFloat { ppi * printWidthInches }
    var printHeight: CGFloat { ppi * printHeightInches }
    var buffer: CGFloat { ppi * bufferInches }

    let pictureAspectRatio: CGFloat = 500 / 580
    var pictureWidth: CGFloat {
        (printWidth / 2) - (2 * buffer)
    }
    var pictureHeight: CGFloat { pictureWidth * pictureAspectRatio }

    let brandImage = UIImage(named: "TotalRecallLogoQRCombo")
    
    var brandImageWidth: CGFloat {
        pictureWidth
    }
    var brandImageHeight: CGFloat {
        guard let brandImage = brandImage else { return 0 }
        let aspectRatio = brandImage.size.height / brandImage.size.width
        return brandImageWidth * aspectRatio
    }
    var brandImageY: CGFloat {
        let h = (printHeight - buffer * 3 - pictureHeight * 3)
        let yOffset = (h - brandImageHeight)/2
        return (printHeight - h) + yOffset
    }

    func makeDoublePhotoStrip(photoData: [Data]) -> UIImage {
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

    func makeSinglePhotoStrip(photoData: [Data]) -> UIImage {
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
    let imageService = CompositeImageRendererService()

    let photoImages: [UIImage?] = [
        UIImage(color: .red), UIImage(color: .green), UIImage(color: .blue),
    ]
    let photoData = photoImages.map { $0!.pngData()! }
    VStack {
        Image(uiImage: imageService.makeDoublePhotoStrip(photoData: photoData))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.indigo)
    .ignoresSafeArea()
}
