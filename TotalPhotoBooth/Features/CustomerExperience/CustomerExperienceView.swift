import SwiftUI

struct CustomerExperienceView: View {
    let viewModel: CustomerExperienceViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        content
            .background(StaffGestureInstaller { viewModel.openStaffMenu() })
            .sheet(isPresented: Binding(
                get: { viewModel.isStaffMenuPresented },
                set: { viewModel.isStaffMenuPresented = $0 }
            )) {
                StaffMenuView(viewModel: viewModel.staffMenu) {
                    viewModel.isStaffMenuPresented = false
                    dismiss()
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.step {
        case .attract:
            AttractView(
                previewView: viewModel.previewView,
                onStart: { viewModel.startSession() }
            )

        case .capture(let mode, let existingPhotos):
            CaptureView(
                viewModel: viewModel.makeCaptureViewModel(
                    mode: mode,
                    existingPhotos: existingPhotos,
                    onComplete: { photos in viewModel.captureSequenceCompleted(photos: photos) }
                ),
                previewView: viewModel.previewView
            )

        case .review(let photos):
            ReviewView(
                viewModel: ReviewViewModel(
                    photos: photos,
                    onRetake: { index in viewModel.retake(index: index, currentPhotos: photos) },
                    onConfirm: { try await viewModel.confirmAndSave(photos: photos) }
                )
            )

        case .success(let photoStrip):
            SuccessView(
                onDone: { viewModel.finishSession() },
                photoStripImage: photoStrip,
                printStatus: viewModel.printStatus
            )
        }
    }
}
