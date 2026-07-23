import SwiftUI

struct CustomerExperienceView: View {
    let viewModel: CustomerExperienceViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        switch viewModel.step {
        case .attract:
            AttractView(
                onStart: { viewModel.startSession() },
                onExitKioskMode: { dismiss() }
            )

        case .capture(let mode, let existingPhotos):
            CaptureView(
                viewModel: CaptureViewModel(
                    mode: mode,
                    existingPhotos: existingPhotos,
                    onComplete: { photos in viewModel.captureSequenceCompleted(photos: photos) }
                )
            )

        case .review(let photos):
            ReviewView(
                viewModel: ReviewViewModel(
                    photos: photos,
                    onRetake: { index in viewModel.retake(index: index, currentPhotos: photos) },
                    onConfirm: { try await viewModel.confirmAndSave() }
                )
            )

        case .success:
            SuccessView(onDone: { viewModel.finishSession() })
        }
    }
}
