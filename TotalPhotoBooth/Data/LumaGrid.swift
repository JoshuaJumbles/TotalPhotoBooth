import CoreVideo
import Foundation

/// A camera frame boiled down to a coarse grid of average brightness —
/// all motion wake needs, and cheap to compare. Values are 0…1.
nonisolated struct LumaGrid: Sendable, Equatable {
    let columns: Int
    let rows: Int
    /// Row-major, `columns * rows` long.
    let values: [Float]
    /// Seconds on the camera's clock.
    let timestamp: TimeInterval
}

nonisolated enum LumaSampler {
    /// Averages the luma (Y) plane of a 4:2:0 frame into `columns × rows`
    /// blocks, reading every `step`th pixel. Averaging also smooths away
    /// the sensor noise a dark booth produces.
    static func grid(
        from pixelBuffer: CVPixelBuffer,
        timestamp: TimeInterval,
        columns: Int = 32,
        rows: Int = 24,
        step: Int = 4
    ) -> LumaGrid? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard CVPixelBufferGetPlaneCount(pixelBuffer) >= 1,
              let base = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0) else {
            return nil
        }
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
        let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
        guard width > 0, height > 0 else { return nil }

        let pixels = base.assumingMemoryBound(to: UInt8.self)
        var sums = [Float](repeating: 0, count: columns * rows)
        var counts = [Float](repeating: 0, count: columns * rows)

        for y in stride(from: 0, to: height, by: step) {
            let row = y * rows / height
            let rowStart = y * bytesPerRow
            for x in stride(from: 0, to: width, by: step) {
                let cell = row * columns + x * columns / width
                sums[cell] += Float(pixels[rowStart + x])
                counts[cell] += 1
            }
        }

        let values = zip(sums, counts).map { sum, count in count > 0 ? sum / count / 255 : 0 }
        return LumaGrid(columns: columns, rows: rows, values: values, timestamp: timestamp)
    }
}
