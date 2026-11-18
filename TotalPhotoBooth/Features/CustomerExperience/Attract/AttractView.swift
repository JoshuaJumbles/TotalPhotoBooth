import SwiftUI
import UIKit

/// The idle screen. Any touch moves on to the pitch. (The spiral and logo
/// replace this look in a later pass; motion will wake it too.)
struct AttractView: View {
    let previewView: UIView
    let onWake: () -> Void

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            CameraPreviewView(previewView: previewView)
                .aspectRatio(CompositeImageRendererService.pictureAspectRatio, contentMode: .fit)

            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Welcome!")
                    .font(.system(size: 88, weight: .heavy))

                Text("Touch anywhere to begin")
                    .font(.system(size: 36, weight: .semibold))
                    .opacity(0.85)
            }
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(48)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onWake)
    }
}
