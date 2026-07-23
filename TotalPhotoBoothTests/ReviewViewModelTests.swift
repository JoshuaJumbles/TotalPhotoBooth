import Foundation
import Testing
@testable import TotalPhotoBooth

@MainActor
struct ReviewViewModelTests {
    @Test func retakeCallsOnRetakeWithTheTargetedIndex() {
        var retakenIndex: Int?
        let viewModel = ReviewViewModel(
            photos: [],
            onRetake: { retakenIndex = $0 },
            onConfirm: {}
        )

        viewModel.retake(at: 2)

        #expect(retakenIndex == 2)
    }

    @Test func confirmCallsOnConfirmAndClearsSavingOnSuccess() async {
        var confirmed = false
        let viewModel = ReviewViewModel(
            photos: [],
            onRetake: { _ in },
            onConfirm: { confirmed = true }
        )

        await viewModel.confirm()

        #expect(confirmed)
        #expect(!viewModel.isSaving)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func confirmSetsErrorMessageOnFailure() async {
        let viewModel = ReviewViewModel(
            photos: [],
            onRetake: { _ in },
            onConfirm: { throw URLError(.badServerResponse) }
        )

        await viewModel.confirm()

        #expect(!viewModel.isSaving)
        #expect(viewModel.errorMessage != nil)
    }
}
