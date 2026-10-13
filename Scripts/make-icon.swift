#!/usr/bin/env swift
import AppKit
import Foundation

// All icon artwork is drawn as vectors, then rendered at every macOS icon size.
let iconsetURL = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "Support/Serpent.iconset", isDirectory: true)
try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: red, green: green, blue: blue, alpha: alpha)
}

func drawIcon() {
    let bounds = NSRect(x: 62, y: 62, width: 900, height: 900)
    let tile = NSBezierPath(roundedRect: bounds, xRadius: 206, yRadius: 206)

    let shadow = NSShadow()
    shadow.shadowColor = color(0.015, 0.04, 0.035, 0.20)
    shadow.shadowBlurRadius = 24
    shadow.shadowOffset = NSSize(width: 0, height: -10)
    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    color(0.08, 0.115, 0.105).setFill()
    tile.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGradient(starting: color(0.14, 0.20, 0.175), ending: color(0.065, 0.105, 0.09))!.draw(in: tile, angle: -90)
    color(0.70, 0.90, 0.79, 0.08).setStroke()
    tile.lineWidth = 2
    tile.stroke()

    // A restrained arena grid gives the simple silhouette depth.
    for x in stride(from: 232, through: 792, by: 140) {
        for y in stride(from: 232, through: 792, by: 140) {
            color(0.78, 0.91, 0.84, 0.065).setFill()
            NSBezierPath(ovalIn: NSRect(x: x - 3, y: y - 3, width: 6, height: 6)).fill()
        }
    }

    let snake = NSBezierPath()
    snake.move(to: NSPoint(x: 328, y: 300))
    snake.line(to: NSPoint(x: 600, y: 300))
    snake.curve(to: NSPoint(x: 730, y: 425), controlPoint1: NSPoint(x: 690, y: 300), controlPoint2: NSPoint(x: 730, y: 340))
    snake.curve(to: NSPoint(x: 604, y: 548), controlPoint1: NSPoint(x: 730, y: 505), controlPoint2: NSPoint(x: 685, y: 548))
    snake.line(to: NSPoint(x: 398, y: 548))
    snake.curve(to: NSPoint(x: 273, y: 656), controlPoint1: NSPoint(x: 316, y: 548), controlPoint2: NSPoint(x: 273, y: 586))
    snake.curve(to: NSPoint(x: 386, y: 746), controlPoint1: NSPoint(x: 273, y: 721), controlPoint2: NSPoint(x: 310, y: 746))
    snake.line(to: NSPoint(x: 635, y: 746))
    snake.lineWidth = 94
    snake.lineCapStyle = .round
    snake.lineJoinStyle = .round

    NSGraphicsContext.saveGraphicsState()
    let snakeShadow = NSShadow()
    snakeShadow.shadowColor = color(0.015, 0.07, 0.04, 0.35)
    snakeShadow.shadowBlurRadius = 20
    snakeShadow.shadowOffset = NSSize(width: 0, height: -8)
    snakeShadow.set()
    color(0.65, 0.91, 0.75).setStroke()
    snake.stroke()
    NSGraphicsContext.restoreGraphicsState()

    // Broad, rounded head with two understated eyes.
    let head = NSBezierPath(roundedRect: NSRect(x: 598, y: 686, width: 167, height: 120), xRadius: 60, yRadius: 60)
    NSGradient(starting: color(0.78, 0.98, 0.84), ending: color(0.59, 0.88, 0.69))!.draw(in: head, angle: -90)
    color(0.075, 0.17, 0.12).setFill()
    NSBezierPath(ovalIn: NSRect(x: 703, y: 764, width: 15, height: 15)).fill()
    NSBezierPath(ovalIn: NSRect(x: 703, y: 714, width: 15, height: 15)).fill()

    // Single coral food pellet echoes the in-game accent.
    let food = NSBezierPath(roundedRect: NSRect(x: 459, y: 374, width: 70, height: 70), xRadius: 22, yRadius: 22)
    NSGradient(starting: color(1.0, 0.65, 0.52), ending: color(0.91, 0.40, 0.32))!.draw(in: food, angle: -90)
    color(1, 0.87, 0.78, 0.52).setFill()
    NSBezierPath(ovalIn: NSRect(x: 473, y: 422, width: 11, height: 8)).fill()
}

func renderPNG(pixels: Int, to url: URL) throws {
    guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                                         bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                         isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
          let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        fatalError("Cannot create icon drawing surface")
    }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.cgContext.scaleBy(x: CGFloat(pixels) / 1024, y: CGFloat(pixels) / 1024)
    drawIcon()
    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
    guard let data = bitmap.representation(using: .png, properties: [:]) else { fatalError("Cannot encode icon") }
    try data.write(to: url)
}

for size in [16, 32, 128, 256, 512] {
    try renderPNG(pixels: size, to: iconsetURL.appendingPathComponent("icon_\(size)x\(size).png"))
    try renderPNG(pixels: size * 2, to: iconsetURL.appendingPathComponent("icon_\(size)x\(size)@2x.png"))
}
try renderPNG(pixels: 1024, to: iconsetURL.deletingLastPathComponent().appendingPathComponent("Serpent-icon.png"))
print("Icon artwork ready at \(iconsetURL.path)")
