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

    @Test func offsetCompensationConvertsOnPaperMillimetersToDrawingPoints() {
        let offset = AirPrintConnectionService.printerOffsetCompensation
        let expected = 0.5 * (72 / 25.4) * AirPrintConnectionService.printerOverscanCompensation

        #expect(abs(offset.width - expected) < 0.001)
        #expect(abs(offset.height - expected) < 0.001)
        #expect(offset.width > 0 && offset.height > 0) // right and down
    }

    @Test func contentScaleShrinksTheDrawRectAboutTheCenter() {
        let paper = CGRect(origin: .zero, size: postcard)
        let imageSize = CGSize(width: 1200, height: 1800)
        let full = FullBleedImagePrintRenderer.contentRect(for: imageSize, in: paper, scale: 1)
        let scaled = FullBleedImagePrintRenderer.contentRect(for: imageSize, in: paper, scale: 0.9)

        #expect(abs(scaled.width - full.width * 0.9) < 0.001)
        #expect(abs(scaled.height - full.height * 0.9) < 0.001)
        #expect(abs(scaled.midX - paper.midX) < 0.001)
        #expect(abs(scaled.midY - paper.midY) < 0.001)
    }
}
