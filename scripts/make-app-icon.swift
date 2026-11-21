#!/usr/bin/env swift
// Renders the TotalPhotoBooth app icon: a white camera over the kiosk's
// two-arm hypnosis spiral, in the default purples.
//
//   swift scripts/make-app-icon.swift TotalPhotoBooth/Assets.xcassets/AppIcon.appiconset/AppIcon.png
//
// Re-run after changing the palette below. The spiral geometry matches
// SpiralMask.armsPath in the app.

import AppKit

let side = 1024
let outputPath = CommandLine.arguments.dropFirst().first ?? "AppIcon.png"

// SpiralStyle.default
let colorA = CGColor(srgbRed: 0.20, green: 0.10, blue: 0.36, alpha: 1)
let colorB = CGColor(srgbRed: 0.33, green: 0.18, blue: 0.52, alpha: 1)
let arms = 2
let tightness = 2.2          // turns across the radius; fewer than on screen, to read at icon size
let radius = Double(side) * 0.75

func armsPath(center: CGPoint) -> CGPath {
    let n = Double(arms)
    let k = 2 * Double.pi * tightness / radius
    let thetaStart = Double.pi / n
    let thetaEnd = -(k * radius * 1.5) / n
    var outer: [CGPoint] = []
    var inner: [CGPoint] = []
    for theta in stride(from: thetaStart, through: thetaEnd, by: -0.01) {
        let rOuter = (Double.pi - n * theta) / k
        let rInner = max(0, -n * theta / k)
        outer.append(CGPoint(x: rOuter * cos(theta), y: rOuter * sin(theta)))
        inner.append(CGPoint(x: rInner * cos(theta), y: rInner * sin(theta)))
    }
    let strip = CGMutablePath()
    strip.addLines(between: outer + inner.reversed())
    strip.closeSubpath()

    let path = CGMutablePath()
    for arm in 0..<arms {
        let turn = CGAffineTransform(translationX: center.x, y: center.y)
            .rotated(by: 2 * .pi * Double(arm) / n)
        path.addPath(strip, transform: turn)
    }
    return path
}

guard let context = CGContext(
    data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue   // app icons must be opaque
) else { fatalError("no context") }

let center = CGPoint(x: Double(side) / 2, y: Double(side) / 2)

// Spiral
context.setFillColor(colorA)
context.fill(CGRect(x: 0, y: 0, width: side, height: side))
context.setFillColor(colorB)
context.addPath(armsPath(center: center))
context.fillPath()

// Soft dark disc so the camera reads against the spiral
let discDiameter = Double(side) * 0.60
context.setFillColor(CGColor(srgbRed: 0.05, green: 0.02, blue: 0.10, alpha: 0.55))
context.fillEllipse(in: CGRect(
    x: center.x - discDiameter / 2, y: center.y - discDiameter / 2,
    width: discDiameter, height: discDiameter
))

// Camera glyph
let config = NSImage.SymbolConfiguration(pointSize: 330, weight: .semibold)
    .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
guard let symbol = NSImage(systemSymbolName: "camera.fill", accessibilityDescription: nil)?
    .withSymbolConfiguration(config) else { fatalError("no symbol") }
let symbolSize = symbol.size
let symbolRect = CGRect(
    x: center.x - symbolSize.width / 2, y: center.y - symbolSize.height / 2,
    width: symbolSize.width, height: symbolSize.height
)
NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
symbol.draw(in: symbolRect)
NSGraphicsContext.current = nil

guard let image = context.makeImage(),
      let destination = CGImageDestinationCreateWithURL(
        URL(fileURLWithPath: outputPath) as CFURL, "public.png" as CFString, 1, nil) else {
    fatalError("no output")
}
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("write failed") }
print("Wrote \(outputPath) (\(side)×\(side))")
