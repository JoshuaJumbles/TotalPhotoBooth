import UIKit

/// The spiral's arms as a white-on-clear template image, drawn once and
/// cached. The view tints it with the second color over the first and spins
/// it with a plain rotation — for an Archimedean spiral, turning *is* a
/// rotation — so each frame is just cheap GPU compositing.
enum SpiralMask {
    /// Pixel size of the cached mask. It's drawn larger than any screen
    /// diagonal needs at 1:1, and the band edges are soft, so upscaling is
    /// invisible.
    static let pixelSize: CGFloat = 2400

    private static var cache: [Key: UIImage] = [:]

    private struct Key: Hashable {
        let arms: Int
        let tightness: Double
    }

    static func image(arms: Int, tightness: Double) -> UIImage {
        let key = Key(arms: arms, tightness: tightness)
        if let cached = cache[key] { return cached }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.preferredRange = .standard
        let size = CGSize(width: pixelSize, height: pixelSize)
        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.white.setFill()
            let path = armsPath(arms: arms, tightness: tightness, radius: pixelSize / 2)
            path.apply(CGAffineTransform(translationX: pixelSize / 2, y: pixelSize / 2))
            path.fill()
        }
        cache[key] = image
        return image
    }

    /// Every arm, centered on the origin, covering a disc of `radius`.
    ///
    /// The bands are where `sin(arms·θ + 2π·tightness·r/radius) ≥ 0`. One
    /// arm traced in *unwrapped* angle is a single strip; the other arms are
    /// copies rotated by 2π/arms.
    static func armsPath(arms: Int, tightness: Double, radius: CGFloat) -> UIBezierPath {
        let n = Double(max(arms, 1))
        let k = 2 * .pi * tightness / Double(radius)   // phase per point of radius
        let path = UIBezierPath()

        // Inner edge: n·θ + k·r = 0; outer edge: n·θ + k·r = π.
        // θ runs from π/n (where the strip starts at the center) downward
        // until the inner edge leaves the disc (with margin for corners).
        let thetaStart = .pi / n
        let thetaEnd = -(k * Double(radius) * 1.5) / n
        let step = -0.01
        var outer: [CGPoint] = []
        var inner: [CGPoint] = []
        for theta in stride(from: thetaStart, through: thetaEnd, by: step) {
            let rOuter = (.pi - n * theta) / k
            let rInner = max(0, -n * theta / k)
            outer.append(CGPoint(x: rOuter * cos(theta), y: rOuter * sin(theta)))
            inner.append(CGPoint(x: rInner * cos(theta), y: rInner * sin(theta)))
        }

        let strip = UIBezierPath()
        strip.move(to: outer[0])
        outer.dropFirst().forEach { strip.addLine(to: $0) }
        inner.reversed().forEach { strip.addLine(to: $0) }
        strip.close()

        for arm in 0..<Int(n) {
            let copy = strip.copy() as! UIBezierPath
            copy.apply(CGAffineTransform(rotationAngle: CGFloat(2 * .pi * Double(arm) / n)))
            path.append(copy)
        }
        return path
    }
}
