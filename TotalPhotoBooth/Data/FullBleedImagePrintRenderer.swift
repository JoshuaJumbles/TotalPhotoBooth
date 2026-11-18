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
    private let contentScale: CGFloat
    private let contentOffset: CGSize
    private let logger = Logger(subsystem: "TotalPhotoBooth", category: "Printing")

    /// - Parameters:
    ///   - contentScale: shrinks the drawn image about the page center to
    ///     cancel out a printer's own borderless overscan (the SELPHY enlarges
    ///     borderless prints a few percent so ink always bleeds past the edge).
    ///     1.0 draws exactly sheet-sized.
    ///   - contentOffset: nudges the drawn image, in points (+x right, +y down),
    ///     to cancel out the printer's mechanical paper-positioning offset.
    init(image: UIImage, contentScale: CGFloat = 1, contentOffset: CGSize = .zero) {
        self.image = image
        self.contentScale = contentScale
        self.contentOffset = contentOffset
        super.init()
    }

    override var numberOfPages: Int { 1 }

    override func drawPage(at pageIndex: Int, in printableRect: CGRect) {
        let drawRect = Self.contentRect(for: image.size, in: paperRect, scale: contentScale)
            .offsetBy(dx: contentOffset.width, dy: contentOffset.height)
        logger.info("Drawing page: paperRect=\(String(describing: self.paperRect)), printableRect=\(String(describing: printableRect)), drawRect=\(String(describing: drawRect))")
        image.draw(in: drawRect)
    }

    /// Aspect-fill into `bounds`, then scaled by `scale` about the center.
    static func contentRect(for imageSize: CGSize, in bounds: CGRect, scale: CGFloat) -> CGRect {
        let fill = aspectFillRect(for: imageSize, in: bounds)
        let size = CGSize(width: fill.width * scale, height: fill.height * scale)
        return CGRect(
            x: bounds.midX - size.width / 2,
            y: bounds.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
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
