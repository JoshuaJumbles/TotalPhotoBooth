import Foundation
import Testing
import UIKit
@testable import TotalPhotoBooth

struct CompositeImageRendererServiceTests {
    private func samplePhotoData(count: Int) -> [Data] {
        (0..<count).map { _ in UIImage(color: .red)!.pngData()! }
    }

    @Test func makeSinglePhotoStripProducesExpectedDimensions() throws {
        let photoData = samplePhotoData(count: CompositeImageRendererService.totalPhotos)

        let image = try CompositeImageRendererService.makeSinglePhotoStrip(photoData: photoData)

        #expect(image.size.width == CompositeImageRendererService.printWidth / 2)
        #expect(image.size.height == CompositeImageRendererService.printHeight)
    }

    @Test func makeDoublePhotoStripProducesExpectedDimensions() throws {
        let photoData = samplePhotoData(count: CompositeImageRendererService.totalPhotos)

        let image = try CompositeImageRendererService.makeDoublePhotoStrip(photoData: photoData)

        #expect(image.size.width == CompositeImageRendererService.printWidth)
        #expect(image.size.height == CompositeImageRendererService.printHeight)
    }

    @Test func makeSinglePhotoStripThrowsOnInvalidPhotoData() {
        var photoData = samplePhotoData(count: CompositeImageRendererService.totalPhotos)
        photoData[1] = Data([0xFF, 0x00])

        #expect(throws: CompositeImageRenderError.self) {
            try CompositeImageRendererService.makeSinglePhotoStrip(photoData: photoData)
        }
    }

    @Test func makeDoublePhotoStripThrowsOnInvalidPhotoData() {
        var photoData = samplePhotoData(count: CompositeImageRendererService.totalPhotos)
        photoData[0] = Data([0xFF, 0x00])

        #expect(throws: CompositeImageRenderError.self) {
            try CompositeImageRendererService.makeDoublePhotoStrip(photoData: photoData)
        }
    }

    @Test func makeSinglePhotoStripSucceedsWithFewerPhotosThanTotal() throws {
        let photoData = samplePhotoData(count: 1)

        let image = try CompositeImageRendererService.makeSinglePhotoStrip(photoData: photoData)

        #expect(image.size.width > 0)
        #expect(image.size.height > 0)
    }
}
