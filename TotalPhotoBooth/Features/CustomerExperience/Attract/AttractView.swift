import SwiftUI
import UIKit

struct AttractView: View {
    let previewView: UIView
    let onStart: () -> Void
    let onExitKioskMode: () -> Void

    var body: some View {
        ZStack {
            CameraPreviewView(previewView: previewView)
                .ignoresSafeArea()

            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Welcome!")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                Button(action: onStart) {
                    Text("Tap to Start")
                        .font(.title2)
                        .frame(minWidth: 220)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button("Exit Kiosk Mode", action: onExitKioskMode)
                .font(.caption)
                .foregroundStyle(.white)
                .padding()
        }
    }
}
