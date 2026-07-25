import SwiftUI

struct SuccessView: View {
    let onDone: () -> Void
    let photoStripImage: UIImage
    let showDebugPrintPreview = true

    var body: some View {
        VStack(spacing: 24) {
            if showDebugPrintPreview {
                Image(uiImage: photoStripImage)
                    .resizable()
                    .scaledToFit()
            }
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 96))
                .foregroundStyle(.green)

            Text("You're all set!")
                .font(.title)

            Button(action: onDone) {
                Text("Done")
                    .font(.headline)
                    .frame(minWidth: 160)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
