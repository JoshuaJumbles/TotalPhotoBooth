import SwiftUI
import UIKit

struct CaptureView: View {
    let viewModel: CaptureViewModel
    let previewView: UIView

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            CameraPreviewView(previewView: previewView)
                .aspectRatio(CompositeImageRendererService.pictureAspectRatio, contentMode: .fit)

            centerContent
        }
        .overlay(alignment: .top) {
            Text("Photo \(viewModel.activeIndex + 1) of \(CompositeImageRendererService.totalPhotos)")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 44)
        }
        .overlay(alignment: .bottom) {
            CaptureThumbnailTray(thumbnails: viewModel.thumbnails, activeIndex: viewModel.activeIndex)
                .padding(.bottom, 40)
        }
        .overlay(alignment: .topLeading) {
            Button(action: viewModel.cancel) {
                Label("Cancel", systemImage: "xmark")
                    .font(.system(size: 28, weight: .semibold))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(.white.opacity(0.2), in: Capsule())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .padding(32)
        }
        // Last, so the flash covers everything — Cancel included.
        .overlay {
            FlashOverlay(isOn: viewModel.phase == .flash)
        }
        .task { await viewModel.beginCaptureSequence() }
        .alert(
            "Error",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.dismissError() } }
            ),
            actions: { Button("OK") { viewModel.dismissError() } },
            message: { Text(viewModel.errorMessage ?? "") }
        )
    }

    @ViewBuilder
    private var centerContent: some View {
        switch viewModel.phase {
        case .countdown(let remaining):
            CountdownRing(
                remaining: remaining,
                startedAt: viewModel.countdownStartedAt,
                totalDuration: viewModel.timing.countdownLength
            )
        case .betweenShots:
            Text("Nice! Photo \(viewModel.activeIndex + 2) is next…")
                .font(.system(size: 56, weight: .heavy))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.vertical, 24)
                .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 28))
                .transition(.opacity)
        case .idle, .flash:
            EmptyView()
        }
    }
}
