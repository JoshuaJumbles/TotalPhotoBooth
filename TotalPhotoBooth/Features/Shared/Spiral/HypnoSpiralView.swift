import SwiftUI

/// The hypnosis spiral at one moment in time. Screens that animate other
/// elements in step with it (the Attract logo) drive `time` from one shared
/// `TimelineView`; everything else uses `SpiralBackground`.
struct HypnoSpiralView: View {
    let style: SpiralStyle
    /// Seconds on any steady clock; only differences matter.
    let time: Double
    /// Turns of each arm across the mask's radius.
    var tightness: Double = 4

    var body: some View {
        let colors = style.colors(at: time)
        let mask = SpiralMask.image(arms: style.arms, tightness: tightness)

        GeometryReader { proxy in
            // Big enough to cover every corner at any rotation.
            let side = hypot(proxy.size.width, proxy.size.height)

            ZStack {
                colors.a.color

                Image(uiImage: mask)
                    .resizable()
                    .renderingMode(.template)
                    .interpolation(.high)
                    .foregroundStyle(colors.b.color)
                    .frame(width: side, height: side)
                    .rotationEffect(.radians(style.rotation(at: time)))
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .ignoresSafeArea()
    }
}

/// A self-animating spiral backdrop, styled from the shared `SpiralSettings`.
struct SpiralBackground: View {
    @Environment(SpiralSettings.self) private var spiralSettings
    /// Black laid over the spiral so foreground photos and type stay legible.
    var dimming: Double = 0

    var body: some View {
        SpiralTimeline { time in
            HypnoSpiralView(style: spiralSettings.style, time: time)
                .overlay(Color.black.opacity(dimming).ignoresSafeArea())
        }
    }
}

/// One clock for the spiral and anything that moves with it. Capped at
/// 60 fps: the motion is slow, and ProMotion's 120 fps would only add heat.
struct SpiralTimeline<Content: View>: View {
    @ViewBuilder let content: (Double) -> Content

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60)) { context in
            content(context.date.timeIntervalSinceReferenceDate)
        }
    }
}
