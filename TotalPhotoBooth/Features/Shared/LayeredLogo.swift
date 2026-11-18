import SwiftUI

/// The Total Recall logo, layered for contrast over the spiral: a white copy
/// as the base, and the black copy on top, offset and slowly orbiting in step
/// with the spiral's turn.
struct LayeredLogo: View {
    let style: SpiralStyle
    let time: Double
    var orbitRadius: CGFloat = 8

    var body: some View {
        let angle = style.rotation(at: time)
        let logo = Image("TotalRecallLogo")
            .resizable()
            .renderingMode(.template)
            .scaledToFit()

        ZStack {
            logo
                .foregroundStyle(.white)

            logo
                .foregroundStyle(.black)
                .offset(
                    x: orbitRadius * CGFloat(cos(angle)),
                    y: orbitRadius * CGFloat(sin(angle))
                )
        }
        .accessibilityElement()
        .accessibilityLabel("Total Recall")
    }
}
