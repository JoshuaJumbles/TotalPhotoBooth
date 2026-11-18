import SwiftUI

/// The strip's three slots along the bottom during capture: photos taken so
/// far, the one being taken now (outlined), and the ones still to come.
struct CaptureThumbnailTray: View {
    let thumbnails: [Int: UIImage]
    let activeIndex: Int

    private let slotWidth: CGFloat = 170
    private var slotHeight: CGFloat { slotWidth / CompositeImageRendererService.pictureAspectRatio }

    var body: some View {
        HStack(spacing: 20) {
            ForEach(0..<CompositeImageRendererService.totalPhotos, id: \.self) { index in
                slot(index)
                    .frame(width: slotWidth, height: slotHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                index == activeIndex ? .white : .white.opacity(0.3),
                                lineWidth: index == activeIndex ? 5 : 2
                            )
                    }
            }
        }
    }

    @ViewBuilder
    private func slot(_ index: Int) -> some View {
        if let thumbnail = thumbnails[index] {
            Image(uiImage: thumbnail)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Color.white.opacity(0.08)
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(.white.opacity(0.35), style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                Text("\(index + 1)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }
}
