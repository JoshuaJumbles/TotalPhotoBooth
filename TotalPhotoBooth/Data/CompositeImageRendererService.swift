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
    var printWidth: CGFloat = 4
    let printHeight: CGFloat = 6
    let buffer: CGFloat = 0.1

    func makeDoublePhotoStrip(photoData: [Data]) -> UIImage {
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: printWidth * ppi, height: printHeight * ppi)
        )

        let image = renderer.image { (context) in
            UIColor.darkGray.setStroke()
            let cg = context.cgContext
            cg.setLineWidth(5.0)
            
            context.stroke(CGRect(
                x: 0,
                y: 0,
                width: renderer.format.bounds.width,
                height: renderer.format.bounds.height
            ))
            
            UIColor.lightGray.setFill()
            context.fill(
                CGRect(
                    x: 0,
                    y: 0,
                    width: renderer.format.bounds.width,
                    height: renderer.format.bounds.height
                )
            )
            
            let imageSize = (printWidth * ppi / 2) - (2 * buffer * ppi)
            let bufferSize = buffer * ppi
            for (index,data) in photoData.enumerated() {
                guard let photoImage = UIImage(data: data) else { return }
                photoImage.draw(in: CGRect(x: bufferSize, y: CGFloat(index) * imageSize + CGFloat(index+1) * bufferSize, width: imageSize, height: imageSize))
            }
            
            for (index,data) in photoData.enumerated() {
                guard let photoImage = UIImage(data: data) else { return }
                photoImage.draw(in: CGRect(x: (printWidth * ppi)/2 + bufferSize, y: CGFloat(index) * imageSize + CGFloat(index+1) * bufferSize, width: imageSize, height: imageSize))
            }
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
    Image(uiImage: imageService.makeDoublePhotoStrip(photoData: photoData))
}
