import CoreGraphics
import Testing
@testable import TotalPhotoBooth

struct PostcardPaperSelectorTests {
    private typealias Candidate = PostcardPaperSelector.Candidate

    private let postcard = PostcardPaperSelector.postcardSize
    private let letter = CGSize(width: 612, height: 792)

    private func borderless(_ size: CGSize) -> Candidate {
        Candidate(paperSize: size, printableRect: CGRect(origin: .zero, size: size))
    }

    private func margined(_ size: CGSize) -> Candidate {
        Candidate(paperSize: size, printableRect: CGRect(origin: .zero, size: size).insetBy(dx: 12, dy: 12))
    }

    @Test func prefersBorderlessPostcardOverMarginedPostcard() {
        let candidates = [borderless(letter), margined(postcard), borderless(postcard)]

        #expect(PostcardPaperSelector.bestIndex(in: candidates) == 2)
    }

    @Test func fallsBackToMarginedPostcardWhenNoBorderlessIsOffered() {
        let candidates = [borderless(letter), margined(postcard)]

        #expect(PostcardPaperSelector.bestIndex(in: candidates) == 1)
    }

    @Test func acceptsTrueFourBySixAndLandscapeOrientation() {
        let landscapeFourBySix = CGSize(width: 432, height: 288)

        #expect(PostcardPaperSelector.bestIndex(in: [borderless(letter), borderless(landscapeFourBySix)]) == 1)
    }

    @Test func returnsNilWhenNothingPostcardSizedIsOffered() {
        let candidates = [borderless(letter), borderless(CGSize(width: 360, height: 504))]

        #expect(PostcardPaperSelector.bestIndex(in: candidates) == nil)
    }

    @Test func aspectFillCoversThePaperAndStaysCentered() {
        let paper = CGRect(origin: .zero, size: postcard)
        let rect = FullBleedImagePrintRenderer.aspectFillRect(for: CGSize(width: 1200, height: 1800), in: paper)

        #expect(rect.width >= paper.width - 0.001)
        #expect(rect.height >= paper.height - 0.001)
        #expect(abs(rect.midX - paper.midX) < 0.001)
        #expect(abs(rect.midY - paper.midY) < 0.001)
    }
}
