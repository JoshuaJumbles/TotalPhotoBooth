import UIKit
import os

/// Prints a single image edge to edge.
///
/// Draws into `paperRect` rather than `printableRect`, so on a borderless
/// paper (printable area == paper) the image reaches every edge; on a
/// margined paper it is simply clipped by the printer's margins.
///
/// `nonisolated` because UIKit may call `drawPage` off the main thread, while
/// this project defaults every type to `@MainActor`.
nonisolated final class FullBleedImagePrintRenderer: UIPrintPageRenderer {
    private let image: UIImage
    private let logger = Logger(subsystem: "TotalPhotoBooth", category: "Printing")

    init(image: UIImage) {
        self.image = image
        super.init()
    }

    override var numberOfPages: Int { 1 }

    override func drawPage(at pageIndex: Int, in printableRect: CGRect) {
        logger.info("Drawing page: paperRect=\(String(describing: self.paperRect)), printableRect=\(String(describing: printableRect))")
        image.draw(in: Self.aspectFillRect(for: image.size, in: paperRect))
    }

    /// The rect that scales `imageSize` to cover `bounds`, centered.
    static func aspectFillRect(for imageSize: CGSize, in bounds: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return bounds }
        let scale = max(bounds.width / imageSize.width, bounds.height / imageSize.height)
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        return CGRect(
            x: bounds.midX - size.width / 2,
            y: bounds.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
    }
}
