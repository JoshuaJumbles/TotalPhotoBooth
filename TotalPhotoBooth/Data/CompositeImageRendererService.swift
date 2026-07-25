//
//  CompositeImageRendererService.swift
//  TotalPhotoBooth
//
//  Created by Joshua Jumbles on 7/23/26.
//

import SwiftUI
import UIKit

enum CompositeImageRenderError: LocalizedError {
    case missingBrandImage
    case invalidPhotoData(index: Int)

    var errorDescription: String? {
        switch self {
        case .missingBrandImage:
            return "The template branding image could not be loaded."
        case .invalidPhotoData(let index):
            return "Photo \(index + 1) could not be decoded."
        }
    }
}

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

    // The booth's camera is mounted low, so a centered crop risks cutting
    // off heads -- keep the top of the frame instead.
    static let pictureCropAlignment: CropVerticalAlignment = .top

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

    private static var pinnedScaleFormat: UIGraphicsImageRendererFormat {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return format
    }

    static func makeDoublePhotoStrip(photoData: [Data]) throws -> UIImage {
        let photoStripImage = try makeSinglePhotoStrip(photoData: photoData)

        let renderer = UIGraphicsImageRenderer(
            size: CGSize(
                width: printWidth,
                height: printHeight
            ),
            format: pinnedScaleFormat
        )

        return renderer.image { (context) in
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
    }

    static func makeSinglePhotoStrip(photoData: [Data]) throws -> UIImage {
        guard let brandImage else {
            throw CompositeImageRenderError.missingBrandImage
        }

        let photoImages = try photoData.enumerated().map { index, data -> UIImage in
            guard let photoImage = UIImage(data: data) else {
                throw CompositeImageRenderError.invalidPhotoData(index: index)
            }
            return photoImage
        }

        let renderer = UIGraphicsImageRenderer(
            size: CGSize(
                width: printWidth / 2,
                height: printHeight
            ),
            format: pinnedScaleFormat
        )

        return renderer.image { (context) in
            UIColor.white.setFill()
            context.fill(
                CGRect(
                    x: 0,
                    y: 0,
                    width: renderer.format.bounds.width,
                    height: renderer.format.bounds.height
                )
            )

            for (index, photoImage) in photoImages.enumerated() {
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

            brandImage.draw(
                in: CGRect(
                    x: buffer,
                    y: brandImageY,
                    width: brandImageWidth,
                    height: brandImageHeight
                )
            )
        }
    }
}

#Preview {
    let photoImages: [UIImage?] = [
        UIImage(color: .red), UIImage(color: .green), UIImage(color: .blue),
    ]
    let photoData = photoImages.map { $0!.pngData()! }
    VStack {
        if let composite = try? CompositeImageRendererService.makeDoublePhotoStrip(photoData: photoData) {
            Image(uiImage: composite)
        }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.indigo)
    .ignoresSafeArea()
}
