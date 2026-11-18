import CoreGraphics

/// Picks the printer's postcard ("4×6") paper out of what it advertises.
///
/// `UIPrintPaper.bestPaper(forPageSize:withPapersFrom:)` looks for paper the
/// content fits on, and the SELPHY's postcard (100×148 mm) is slightly
/// *smaller* than true 4×6 — so it can be skipped, or a margined variant
/// chosen. This works on plain sizes so it can be unit tested; the delegate
/// maps the result back to a `UIPrintPaper`.
enum PostcardPaperSelector {
    struct Candidate: Equatable {
        let paperSize: CGSize
        let printableRect: CGRect
    }

    /// All sizes in points (1/72 in).
    static let postcardSize = CGSize(width: 100 / 25.4 * 72, height: 148 / 25.4 * 72)
    static let fourBySixSize = CGSize(width: 4 * 72, height: 6 * 72)
    static let sizeTolerance: CGFloat = 3

    /// Index of the best postcard-sized paper, preferring borderless, or nil
    /// if nothing postcard-sized is offered.
    static func bestIndex(in candidates: [Candidate]) -> Int? {
        let postcardSized = candidates.indices.filter { isPostcardSized(candidates[$0].paperSize) }
        return postcardSized.first { isBorderless(candidates[$0]) } ?? postcardSized.first
    }

    static func isPostcardSized(_ size: CGSize) -> Bool {
        [postcardSize, fourBySixSize].contains { target in
            matches(size, target) || matches(size, CGSize(width: target.height, height: target.width))
        }
    }

    static func isBorderless(_ candidate: Candidate) -> Bool {
        matches(candidate.printableRect.size, candidate.paperSize)
    }

    private static func matches(_ a: CGSize, _ b: CGSize) -> Bool {
        abs(a.width - b.width) <= sizeTolerance && abs(a.height - b.height) <= sizeTolerance
    }
}
