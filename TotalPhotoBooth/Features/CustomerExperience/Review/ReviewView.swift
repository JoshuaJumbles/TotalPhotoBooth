import SwiftUI
import UIKit

struct ReviewView: View {
    let viewModel: ReviewViewModel

    private let photoSpacing: CGFloat = 24
    private let aspectRatio = CompositeImageRendererService.pictureAspectRatio

    var body: some View {
        VStack(spacing: 32) {
            Text("Look good?")
                .font(.system(size: 64, weight: .heavy))

            // One column, sized so the three photos fill the available height.
            GeometryReader { geometry in
                let photoHeight = (geometry.size.height - photoSpacing * 2) / 3
                let photoWidth = min(photoHeight * aspectRatio, geometry.size.width * 0.6)
                let sideWidth = (geometry.size.width - photoWidth) / 2

                VStack(spacing: photoSpacing) {
                    ForEach(viewModel.photos) { photo in
                        HStack(spacing: 0) {
                            Color.clear
                                .frame(width: sideWidth)

                            photoImage(photo)
                                .frame(width: photoWidth, height: photoWidth / aspectRatio)
                                .clipShape(RoundedRectangle(cornerRadius: 16))

                            retakeButton(for: photo)
                                .frame(width: sideWidth)
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }

            Button {
                Task { await viewModel.confirm() }
            } label: {
                Group {
                    if viewModel.isSaving {
                        ProgressView()
                            .controlSize(.large)
                    } else {
                        Text("Print My Photos")
                    }
                }
                .font(.system(size: 44, weight: .bold))
                .frame(minWidth: 420, minHeight: 64)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .disabled(viewModel.isSaving)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 40)
        .foregroundStyle(.white)
        .background(SpiralBackground(dimming: 0.4))
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

    @ViewBuilder
    private func photoImage(_ photo: CapturedPhoto) -> some View {
        if let uiImage = UIImage(data: photo.imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Rectangle()
                .fill(.quaternary)
                .overlay {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.secondary)
                }
        }
    }

    private func retakeButton(for photo: CapturedPhoto) -> some View {
        Button {
            viewModel.retake(at: photo.index)
        } label: {
            Label("Retake", systemImage: "arrow.counterclockwise")
                .font(.system(size: 28, weight: .semibold))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .disabled(viewModel.isSaving)
    }
}
