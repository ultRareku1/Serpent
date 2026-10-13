import CoreGraphics
import Foundation

/// Builds a continuous snake path in cell units, allowing the canvas to clip
/// periodically translated copies instead of connecting opposite board edges.
enum SnakeGeometry {
    static func positions(
        snake: [GridPoint],
        previous: [GridPoint],
        direction: Direction,
        progress: CGFloat,
        columns: Int,
        rows: Int,
        wrapsEdges: Bool
    ) -> [CGPoint] {
        precondition(columns > 0 && rows > 0)
        guard let currentHead = snake.first else { return [] }
        let fraction = min(1, max(0, progress))

        guard wrapsEdges else {
            return snake.enumerated().map { index, point in
                let end = center(point)
                let start = center(previous.isEmpty ? point : previous[min(index, previous.count - 1)])
                return interpolate(from: start, to: end, fraction: fraction)
            }
        }

        guard let previousHead = previous.first else {
            return unwrap(snake, head: center(currentHead), columns: columns, rows: rows)
        }

        let startHead = center(previousHead)
        let candidate = previousHead + direction.vector
        let normalizedCandidate = GridPoint(
            x: normalized(candidate.x, extent: columns),
            y: normalized(candidate.y, extent: rows)
        )
        let endHead: CGPoint
        if currentHead != previousHead && currentHead == normalizedCandidate {
            endHead = CGPoint(x: startHead.x + CGFloat(direction.vector.x),
                              y: startHead.y + CGFloat(direction.vector.y))
        } else if currentHead == previousHead {
            // Pause/resume and failed collision ticks must not animate another move.
            endHead = startHead
        } else {
            endHead = center(currentHead)
        }

        let start = unwrap(previous, head: startHead, columns: columns, rows: rows)
        let end = unwrap(snake, head: endHead, columns: columns, rows: rows)
        return end.enumerated().map { index, point in
            interpolate(from: start[min(index, start.count - 1)], to: point, fraction: fraction)
        }
    }

    /// Includes every board-period translation whose padded path bounds can
    /// intersect the board, even when a winding snake spans several periods.
    static func tileOffsets(for positions: [CGPoint], columns: Int, rows: Int) -> [CGPoint] {
        precondition(columns > 0 && rows > 0)
        guard let first = positions.first else { return [] }
        var minX = first.x
        var maxX = first.x
        var minY = first.y
        var maxY = first.y
        for point in positions.dropFirst() {
            minX = min(minX, point.x)
            maxX = max(maxX, point.x)
            minY = min(minY, point.y)
            maxY = max(maxY, point.y)
        }
        let width = CGFloat(columns)
        let height = CGFloat(rows)
        let firstColumn = Int(ceil((-maxX - 0.5) / width))
        let lastColumn = Int(floor((width - minX + 0.5) / width))
        let firstRow = Int(ceil((-maxY - 0.5) / height))
        let lastRow = Int(floor((height - minY + 0.5) / height))
        guard firstColumn <= lastColumn && firstRow <= lastRow else { return [] }

        var offsets: [CGPoint] = []
        // Prefer the unshifted path, then emit all other intersecting copies.
        if firstColumn <= 0 && lastColumn >= 0 && firstRow <= 0 && lastRow >= 0 {
            offsets.append(.zero)
        }
        for row in firstRow...lastRow {
            for column in firstColumn...lastColumn where column != 0 || row != 0 {
                offsets.append(CGPoint(x: CGFloat(column) * width, y: CGFloat(row) * height))
            }
        }
        return offsets
    }

    private static func unwrap(_ points: [GridPoint], head: CGPoint, columns: Int, rows: Int) -> [CGPoint] {
        guard !points.isEmpty else { return [] }
        var positions = [head]
        positions.reserveCapacity(points.count)
        for index in 1..<points.count {
            let preceding = points[index - 1]
            let point = points[index]
            let anchor = positions[index - 1]
            positions.append(CGPoint(
                x: anchor.x + CGFloat(shortestDelta(point.x - preceding.x, extent: columns)),
                y: anchor.y + CGFloat(shortestDelta(point.y - preceding.y, extent: rows))
            ))
        }
        return positions
    }

    private static func shortestDelta(_ delta: Int, extent: Int) -> Int {
        var result = delta % extent
        if result > extent / 2 { result -= extent }
        if result < -(extent / 2) { result += extent }
        // A two-cell dimension cannot distinguish the two routes between its
        // neighbors from coordinates alone; equal-distance ties keep their sign.
        return result
    }

    private static func normalized(_ value: Int, extent: Int) -> Int {
        (value % extent + extent) % extent
    }

    private static func center(_ point: GridPoint) -> CGPoint {
        CGPoint(x: CGFloat(point.x) + 0.5, y: CGFloat(point.y) + 0.5)
    }

    private static func interpolate(from start: CGPoint, to end: CGPoint, fraction: CGFloat) -> CGPoint {
        CGPoint(x: start.x + (end.x - start.x) * fraction,
                y: start.y + (end.y - start.y) * fraction)
    }
}
