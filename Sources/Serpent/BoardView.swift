import AppKit
import SwiftUI

struct BoardView: NSViewRepresentable {
    @ObservedObject var session: GameSession
    let dark: Bool
    let accessibilityLabel: String

    func makeNSView(context: Context) -> SnakeCanvas {
        let view = SnakeCanvas()
        view.setAccessibilityElement(true)
        view.setAccessibilityRole(.image)
        view.setAccessibilityLabel(accessibilityLabel)
        return view
    }

    func updateNSView(_ view: SnakeCanvas, context: Context) {
        view.configure(engine: session.engine, previous: session.previousSnake,
                       tickTime: session.tickTime, dark: dark)
        view.onTurn = { [weak session] direction in session?.turn(direction) }
        view.setAccessibilityLabel(accessibilityLabel)
    }

    static func dismantleNSView(_ nsView: SnakeCanvas, coordinator: ()) { nsView.stopAnimation() }
}

final class SnakeCanvas: NSView {
    override var isFlipped: Bool { true }
    override var isOpaque: Bool { true }
    override var mouseDownCanMoveWindow: Bool { false }
    var onTurn: ((Direction) -> Void)?
    private var engine = GameEngine()
    private var previous: [GridPoint] = []
    private var tickTime: TimeInterval = 0
    private var dark = false
    private var animationTimer: Timer?
    private var gestureTurned = false
    private var scrollAccumulator = CGPoint.zero
    private var lastWheelTurn: TimeInterval = 0

    override func scrollWheel(with event: NSEvent) {
        guard event.momentumPhase.isEmpty else { return }
        if event.phase.contains(.began) {
            gestureTurned = false
            scrollAccumulator = .zero
        }
        if event.phase.contains(.ended) || event.phase.contains(.cancelled) {
            gestureTurned = false
            scrollAccumulator = .zero
            return
        }
        let discrete = event.phase.isEmpty
        let now = ProcessInfo.processInfo.systemUptime
        if discrete && now - lastWheelTurn < 0.18 { return }
        guard !gestureTurned || discrete else { return }
        let physicalDirection: CGFloat = event.isDirectionInvertedFromDevice ? -1 : 1
        scrollAccumulator.x += event.scrollingDeltaX * physicalDirection
        scrollAccumulator.y += event.scrollingDeltaY * physicalDirection
        guard max(abs(scrollAccumulator.x), abs(scrollAccumulator.y)) > 8 else { return }
        let direction: Direction
        if abs(scrollAccumulator.x) > abs(scrollAccumulator.y) {
            direction = scrollAccumulator.x > 0 ? .left : .right
        } else { direction = scrollAccumulator.y > 0 ? .up : .down }
        onTurn?(direction)
        gestureTurned = true
        lastWheelTurn = now
        scrollAccumulator = .zero
    }

    func configure(engine: GameEngine, previous: [GridPoint], tickTime: TimeInterval, dark: Bool) {
        self.engine = engine
        self.previous = previous
        self.tickTime = tickTime
        self.dark = dark
        if engine.phase == .running && animationTimer == nil {
            let timer = Timer(timeInterval: 1.0 / 60, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated { self?.needsDisplay = true }
            }
            timer.tolerance = 0.003
            RunLoop.main.add(timer, forMode: .common)
            animationTimer = timer
        } else if engine.phase != .running { stopAnimation() }
        needsDisplay = true
    }

    func stopAnimation() { animationTimer?.invalidate(); animationTimer = nil }

    override func draw(_ dirtyRect: NSRect) {
        let boardColor = NSColor(hex: dark ? 0x1B241F : 0xECF1E8)
        boardColor.setFill()
        bounds.fill()
        let cell = min(bounds.width / CGFloat(engine.columns), bounds.height / CGFloat(engine.rows))
        let origin = CGPoint(x: (bounds.width - cell * CGFloat(engine.columns)) / 2,
                             y: (bounds.height - cell * CGFloat(engine.rows)) / 2)
        let dots = NSBezierPath()
        for x in 0...engine.columns {
            for y in 0...engine.rows {
                let point = CGPoint(x: origin.x + CGFloat(x) * cell, y: origin.y + CGFloat(y) * cell)
                dots.appendOval(in: CGRect(x: point.x - 0.7, y: point.y - 0.7, width: 1.4, height: 1.4))
            }
        }
        NSColor(hex: dark ? 0x526C59 : 0xA5B39F, alpha: dark ? 0.28 : 0.34).setFill()
        dots.fill()
        let now = ProcessInfo.processInfo.systemUptime
        let progress: CGFloat = engine.phase == .running
            ? CGFloat(min(1, max(0, (now - tickTime) / engine.difficulty.stepInterval))) : 1

        func center(_ point: GridPoint) -> CGPoint {
            CGPoint(x: origin.x + (CGFloat(point.x) + 0.5) * cell,
                    y: origin.y + (CGFloat(point.y) + 0.5) * cell)
        }

        if let food = engine.food {
            let point = center(food)
            let pulse: CGFloat = engine.phase == .running ? CGFloat(1 + sin(now * 3) * 0.08) : 1
            let halo = cell * 0.85 * pulse
            NSColor(hex: dark ? 0xD8A87C : 0xDFA075, alpha: 0.12).setFill()
            NSBezierPath(ovalIn: CGRect(x: point.x - halo / 2, y: point.y - halo / 2, width: halo, height: halo)).fill()
            let size = cell * 0.47
            NSColor(hex: dark ? 0xE9AD7A : 0xD68E60).setFill()
            NSBezierPath(roundedRect: CGRect(x: point.x - size / 2, y: point.y - size / 2,
                                             width: size, height: size), xRadius: size * 0.4, yRadius: size * 0.4).fill()
            let leaf = NSBezierPath()
            leaf.move(to: CGPoint(x: point.x, y: point.y - size / 2))
            leaf.curve(to: CGPoint(x: point.x + size * 0.3, y: point.y - size * 0.8),
                       controlPoint1: CGPoint(x: point.x, y: point.y - size * 0.85),
                       controlPoint2: CGPoint(x: point.x + size * 0.3, y: point.y - size * 0.75))
            leaf.lineWidth = max(1.5, cell * 0.08)
            leaf.lineCapStyle = .round
            NSColor(hex: dark ? 0x9BB28D : 0x6B865A).setStroke()
            leaf.stroke()
        }

        let positions = SnakeGeometry.positions(
            snake: engine.snake, previous: previous, direction: engine.direction, progress: progress,
            columns: engine.columns, rows: engine.rows, wrapsEdges: engine.wrapsEdges
        )
        guard !positions.isEmpty else { return }
        let offsets = engine.wrapsEdges
            ? SnakeGeometry.tileOffsets(for: positions, columns: engine.columns, rows: engine.rows) : [.zero]
        let vector = engine.direction.vector
        let forward = CGPoint(x: CGFloat(vector.x), y: CGFloat(vector.y))
        let side = CGPoint(x: -forward.y, y: forward.x)
        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        NSBezierPath(rect: bounds).addClip()
        // Draw continuous geometry at both edges, clipped to the board.
        for offset in offsets {
            let translated = positions.map {
                CGPoint(x: origin.x + ($0.x + offset.x) * cell,
                        y: origin.y + ($0.y + offset.y) * cell)
            }
            let head = translated[0]
            let body = NSBezierPath()
            body.move(to: head)
            for point in translated.dropFirst() { body.line(to: point) }
            body.lineWidth = cell * 0.76
            body.lineCapStyle = .round
            body.lineJoinStyle = .round
            NSColor(hex: dark ? 0xADCF97 : 0x426E48).setStroke()
            body.stroke()

            let headSize = cell * 0.83
            NSColor(hex: dark ? 0xD0EDB5 : 0x2E5839).setFill()
            NSBezierPath(roundedRect: CGRect(x: head.x - headSize / 2, y: head.y - headSize / 2,
                                             width: headSize, height: headSize), xRadius: cell * 0.29, yRadius: cell * 0.29).fill()
            NSColor(hex: dark ? 0x30432C : 0xE3EFD6).setFill()
            for sign: CGFloat in [-1, 1] {
                let eye = CGPoint(x: head.x + forward.x * cell * 0.17 + side.x * sign * cell * 0.16,
                                  y: head.y + forward.y * cell * 0.17 + side.y * sign * cell * 0.16)
                let radius = cell * 0.065
                NSBezierPath(ovalIn: CGRect(x: eye.x - radius, y: eye.y - radius, width: radius * 2, height: radius * 2)).fill()
            }
        }
    }
}
