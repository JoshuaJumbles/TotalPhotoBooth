import SwiftUI
import UIKit

/// The offer, over a live view of the booth: price, how to pay, and the
/// button that starts a session. Type is sized to read from the booth seat.
struct PitchView: View {
    let previewView: UIView
    let onStart: () -> Void

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            CameraPreviewView(previewView: previewView)
                .aspectRatio(CompositeImageRendererService.pictureAspectRatio, contentMode: .fit)

            // Scrims keep the white type legible over a bright preview.
            VStack(spacing: 0) {
                LinearGradient(colors: [.black.opacity(0.85), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 520)
                Spacer()
                LinearGradient(colors: [.clear, .black.opacity(0.85)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 360)
            }
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("$5 for a Pair of Photo Strips")
                    .font(.system(size: 76, weight: .heavy))
                    .minimumScaleFactor(0.6)

                Text("Pay & Pickup at the front counter")
                    .font(.system(size: 40, weight: .semibold))
                    .opacity(0.9)

                Spacer()

                Button(action: onStart) {
                    Text("Tap to Start")
                        .font(.system(size: 44, weight: .bold))
                        .padding(.horizontal, 56)
                        .padding(.vertical, 22)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
            }
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 48)
            .padding(.vertical, 64)
        }
    }
}
