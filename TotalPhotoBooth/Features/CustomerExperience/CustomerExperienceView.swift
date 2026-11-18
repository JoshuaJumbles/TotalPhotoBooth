import SwiftUI

struct CustomerExperienceView: View {
    let viewModel: CustomerExperienceViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        content
            .background(StaffGestureInstaller { viewModel.openStaffMenu() })
            // A kiosk shows no clock, battery or home indicator — and nothing
            // should sit on top of the screen flash.
            .statusBarHidden()
            .persistentSystemOverlays(.hidden)
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
            AttractView(onWake: { viewModel.showPitch() })

        case .pitch:
            PitchView(
                previewView: viewModel.previewView,
                onStart: { viewModel.startSession() }
            )

        case .capture:
            if let captureViewModel = viewModel.captureViewModel {
                CaptureView(viewModel: captureViewModel, previewView: viewModel.previewView)
            }

        case .review:
            if let reviewViewModel = viewModel.reviewViewModel {
                ReviewView(viewModel: reviewViewModel)
                    .overlay {
                        if viewModel.isShowingStillThere {
                            StillThereOverlay(
                                secondsRemaining: viewModel.stillThereSecondsRemaining,
                                onStillHere: { viewModel.stillHere() }
                            )
                        }
                    }
            }

        case .success:
            SuccessView(
                onDone: { viewModel.finishSession() },
                printStatus: viewModel.printStatus
            )
        }
    }
}
