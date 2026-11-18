import SwiftUI

struct CustomerExperienceView: View {
    let viewModel: CustomerExperienceViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            // One live preview behind Pitch and Capture, rather than each
            // screen embedding it: there's a single preview view, and during a
            // crossfade two screens can't both hold it.
            if viewModel.step.kind.showsCameraPreview {
                CameraPreviewView(previewView: viewModel.previewView)
                    .aspectRatio(CompositeImageRendererService.pictureAspectRatio, contentMode: .fit)
                    .transition(.opacity)
                    .zIndex(1)
            }

            // Explicit z-order: without it, a screen fading *out* can be drawn
            // beneath the black backdrop and vanish instead of dissolving.
            content
                .zIndex(2)
        }
        .animation(transitionAnimation, value: viewModel.step.kind)
        .task { await viewModel.monitorPresence() }
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
            AttractView(
                presenceMonitor: viewModel.showsMotionMeter ? viewModel.presenceMonitor : nil,
                onWake: { viewModel.showPitch() }
            )
            .transition(.opacity)

        case .pitch:
            PitchView(onStart: { viewModel.startSession() })
                .transition(.opacity)

        case .capture:
            if let captureViewModel = viewModel.captureViewModel {
                CaptureView(viewModel: captureViewModel)
                    .transition(.opacity)
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
                    .transition(.opacity)
            }

        case .success:
            SuccessView(
                onDone: { viewModel.finishSession() },
                printStatus: viewModel.printStatus
            )
            .transition(.opacity)
        }
    }

    /// Waking from the spiral into the pitch gets a slow dissolve, so the
    /// entry feels unhurried; every other screen change is quicker.
    private var transitionAnimation: Animation {
        viewModel.step.kind == .pitch ? .easeInOut(duration: 1.2) : .easeInOut(duration: 0.6)
    }
}
