import SwiftUI
import UIKit

struct CaptureView: View {
    let viewModel: CaptureViewModel
    let previewView: UIView

    var body: some View {
        ZStack {
            CameraPreviewView(previewView: previewView)
                .ignoresSafeArea()

            Color.black.opacity(0.25)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Photo \(viewModel.activeIndex + 1) of \(CaptureViewModel.totalPhotos)")
                    .font(.headline)
                    .foregroundStyle(.white)

                if viewModel.countdownValue > 0 {
                    Text("\(viewModel.countdownValue)")
                        .font(.system(size: 96, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .task { await viewModel.beginCaptureSequence() }
        .alert(
            "Error",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            ),
            actions: { Button("OK") { viewModel.errorMessage = nil } },
            message: { Text(viewModel.errorMessage ?? "") }
        )
    }
}
