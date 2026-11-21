import Foundation

/// Decides how much of the booth looks different from when it was empty.
///
/// The booth is enclosed and the camera fixed, so instead of comparing each
/// frame with the last (which stops seeing someone who holds still), each
/// frame is compared with a slowly learned *background* of the empty booth.
struct PresenceDetector {
    /// Fraction of the frame that must differ for someone to count as there.
    var presenceThreshold: Double
    /// How far a cell's (normalized) brightness must move to count as changed.
    var cellThreshold: Float = 0.15
    /// Background learning speed while the booth looks empty…
    var emptyTimeConstant: TimeInterval = 5
    /// …and, much slower, while someone seems present — slow, not frozen, so
    /// a wrong first background (staff in view at kiosk start) heals itself.
    var presentTimeConstant: TimeInterval = 60
    /// Frames darker than this skip normalization rather than amplify noise.
    var darkMeanFloor: Float = 0.02

    private var background: [Float]?
    private var lastTimestamp: TimeInterval?
    private(set) var isPresent = false

    init(presenceThreshold: Double) {
        self.presenceThreshold = presenceThreshold
    }

    /// Scores a frame — the fraction of cells that differ from the background
    /// — and updates the background. The first frame becomes the background.
    @discardableResult
    mutating func process(_ grid: LumaGrid) -> Double {
        let frame = Self.normalized(grid.values, darkMeanFloor: darkMeanFloor)
        defer { lastTimestamp = grid.timestamp }

        guard let background, background.count == frame.count, !frame.isEmpty else {
            self.background = frame
            isPresent = false
            return 0
        }

        var changed = 0
        for index in frame.indices where abs(frame[index] - background[index]) > cellThreshold {
            changed += 1
        }
        let score = Double(changed) / Double(frame.count)
        isPresent = score >= presenceThreshold

        let elapsed = max(0, grid.timestamp - (lastTimestamp ?? grid.timestamp))
        let timeConstant = isPresent ? presentTimeConstant : emptyTimeConstant
        let blend = Float(1 - exp(-elapsed / timeConstant))
        self.background = zip(background, frame).map { old, new in old + blend * (new - old) }

        return score
    }

    /// Each cell relative to the frame's mean brightness, so a change in
    /// overall light — the spiral's color swell, auto-exposure — cancels out.
    static func normalized(_ values: [Float], darkMeanFloor: Float) -> [Float] {
        guard !values.isEmpty else { return values }
        let mean = values.reduce(0, +) / Float(values.count)
        guard mean >= darkMeanFloor else { return values }
        return values.map { $0 / mean }
    }
}
