import SwiftUI

/// The Total Recall logo, layered for contrast over the spiral: a "shadow"
/// copy as the base, and the foreground copy on top, offset and orbiting at
/// a multiple of the spiral's turn. Both colors swell with the spiral.
struct LayeredLogo: View {
    let style: SpiralStyle
    let time: Double
    var orbitRadius: CGFloat = 8

    var body: some View {
        let angle = style.logoOrbitAngle(at: time)
        let colors = style.logoColors(at: time)
        let logo = Image("TotalRecallLogo")
            .resizable()
            .renderingMode(.template)
            .scaledToFit()

        ZStack {
            logo
                .foregroundStyle(colors.shadow.color)

            logo
                .foregroundStyle(colors.foreground.color)
                .offset(
                    x: orbitRadius * CGFloat(cos(angle)),
                    y: orbitRadius * CGFloat(sin(angle))
                )
        }
        .accessibilityElement()
        .accessibilityLabel("Total Recall")
    }
}
