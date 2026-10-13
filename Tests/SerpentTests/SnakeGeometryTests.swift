import CoreGraphics
import XCTest
@testable import Serpent

final class SnakeGeometryTests: XCTestCase {
    func testHeadMovesHalfACellThroughEachEdge() {
        let cases: [(GridPoint, GridPoint, Direction, CGPoint)] = [
            (point(7, 3), point(0, 3), .right, CGPoint(x: 8, y: 3.5)),
            (point(0, 3), point(7, 3), .left, CGPoint(x: 0, y: 3.5)),
            (point(3, 0), point(3, 7), .up, CGPoint(x: 3.5, y: 0)),
            (point(3, 7), point(3, 0), .down, CGPoint(x: 3.5, y: 8))
        ]
        for (previousHead, head, direction, expected) in cases {
            let positions = wrapped([head], previous: [previousHead], direction: direction)
            XCTAssertEqual(positions, [expected])
        }
    }

    func testBodyRemainsAdjacentWhenHeadCrossesSeam() {
        let positions = wrapped(
            [point(0, 3), point(7, 3), point(6, 3), point(5, 3)],
            previous: [point(7, 3), point(6, 3), point(5, 3), point(4, 3)]
        )

        XCTAssertEqual(positions, [CGPoint(x: 8, y: 3.5), CGPoint(x: 7, y: 3.5),
                                   CGPoint(x: 6, y: 3.5), CGPoint(x: 5, y: 3.5)])
        assertAdjacent(positions)
    }

    func testBodyRemainsAdjacentAfterHeadLeavesSeam() {
        let positions = wrapped(
            [point(1, 3), point(0, 3), point(7, 3), point(6, 3)],
            previous: [point(0, 3), point(7, 3), point(6, 3), point(5, 3)]
        )

        XCTAssertEqual(positions, [CGPoint(x: 1, y: 3.5), CGPoint(x: 0, y: 3.5),
                                   CGPoint(x: -1, y: 3.5), CGPoint(x: -2, y: 3.5)])
        assertAdjacent(positions)
    }

    func testCrossingAndTurningKeepsBothSeamsContinuous() {
        let positions = wrapped(
            [point(0, 7), point(0, 0), point(7, 0), point(6, 0)],
            previous: [point(0, 0), point(7, 0), point(6, 0), point(5, 0)],
            direction: .up
        )

        XCTAssertEqual(positions, [CGPoint(x: 0.5, y: 0), CGPoint(x: 0, y: 0.5),
                                   CGPoint(x: -1, y: 0.5), CGPoint(x: -2, y: 0.5)])
        assertAdjacent(positions)
    }

    func testGrowthDuplicatesPreviousTailDuringInterpolation() {
        let positions = wrapped(
            [point(0, 3), point(7, 3), point(6, 3), point(5, 3)],
            previous: [point(7, 3), point(6, 3), point(5, 3)]
        )

        XCTAssertEqual(positions, [CGPoint(x: 8, y: 3.5), CGPoint(x: 7, y: 3.5),
                                   CGPoint(x: 6, y: 3.5), CGPoint(x: 5.5, y: 3.5)])
        assertAdjacent(positions)
    }

    func testCompletedPositionsProjectToEveryCurrentCell() {
        let snake = [point(0, 7), point(0, 0), point(7, 0), point(6, 0)]
        let positions = wrapped(
            snake, previous: [point(0, 0), point(7, 0), point(6, 0), point(5, 0)],
            direction: .up, progress: 1
        )

        XCTAssertEqual(positions.map(project), snake)
        assertAdjacent(positions)
    }

    func testStationaryResumeDoesNotMoveHeadOrBody() {
        let snake = [point(0, 3), point(7, 3), point(6, 3)]
        let start = wrapped(snake, previous: snake, progress: 0)

        XCTAssertEqual(wrapped(snake, previous: snake, progress: 0.5), start)
        XCTAssertEqual(wrapped(snake, previous: snake, progress: 1), start)
        XCTAssertEqual(start, [CGPoint(x: 0.5, y: 3.5), CGPoint(x: -0.5, y: 3.5),
                               CGPoint(x: -1.5, y: 3.5)])
    }

    func testEmptyPreviousSnakeStartsAtCurrentContinuousShape() {
        let snake = [point(0, 3), point(7, 3), point(6, 3)]
        let positions = wrapped(snake, previous: [], progress: 0)

        XCTAssertEqual(positions.map(project), snake)
        assertAdjacent(positions)
    }

    func testClassicInterpolationKeepsOriginalBehavior() {
        let positions = SnakeGeometry.positions(
            snake: [point(4, 3), point(3, 3), point(2, 3)],
            previous: [point(3, 3), point(2, 3)], direction: .right,
            progress: 0.5, columns: 8, rows: 8, wrapsEdges: false
        )

        XCTAssertEqual(positions, [CGPoint(x: 4, y: 3.5), CGPoint(x: 3, y: 3.5),
                                   CGPoint(x: 2.5, y: 3.5)])
    }

    func testNormalPathOnlyNeedsUnshiftedCopy() {
        let positions = [CGPoint(x: 4, y: 3.5), CGPoint(x: 3, y: 3.5), CGPoint(x: 2, y: 3.5)]

        XCTAssertEqual(SnakeGeometry.tileOffsets(for: positions, columns: 8, rows: 8), [.zero])
    }

    func testHorizontalAndVerticalSeamsNeedOppositeCopies() {
        let cases: [(CGPoint, CGPoint)] = [
            (CGPoint(x: 8, y: 3.5), CGPoint(x: -8, y: 0)),
            (CGPoint(x: 0, y: 3.5), CGPoint(x: 8, y: 0)),
            (CGPoint(x: 3.5, y: 0), CGPoint(x: 0, y: 8)),
            (CGPoint(x: 3.5, y: 8), CGPoint(x: 0, y: -8))
        ]
        for (head, translatedCopy) in cases {
            XCTAssertEqual(SnakeGeometry.tileOffsets(for: [head], columns: 8, rows: 8),
                           [.zero, translatedCopy])
        }
    }

    func testCornerSeamIncludesDiagonalCopy() {
        let offsets = SnakeGeometry.tileOffsets(for: [CGPoint(x: 0, y: 0)], columns: 8, rows: 8)

        XCTAssertEqual(offsets.count, 4)
        XCTAssertTrue(offsets.contains(.zero))
        XCTAssertTrue(offsets.contains(CGPoint(x: 8, y: 0)))
        XCTAssertTrue(offsets.contains(CGPoint(x: 0, y: 8)))
        XCTAssertTrue(offsets.contains(CGPoint(x: 8, y: 8)))
    }

    func testLongWindingSnakeIncludesEveryIntersectingPeriod() {
        // This valid path crosses a width seam on three separate rows. Its
        // unwrapped tail lies more than two board widths from the head.
        let snake = [point(0, 1), point(7, 1), point(6, 1), point(5, 1), point(4, 1),
                     point(3, 1), point(2, 1), point(1, 1), point(1, 2), point(0, 2),
                     point(7, 2), point(6, 2), point(5, 2), point(4, 2), point(3, 2),
                     point(2, 2), point(2, 3), point(1, 3), point(0, 3), point(7, 3)]
        let positions = wrapped(snake, previous: snake, progress: 1)
        let offsets = SnakeGeometry.tileOffsets(for: positions, columns: 8, rows: 8)

        XCTAssertEqual(positions.map(project), snake)
        assertAdjacent(positions)
        XCTAssertEqual(offsets, [.zero, CGPoint(x: 8, y: 0), CGPoint(x: 16, y: 0),
                                 CGPoint(x: 24, y: 0)])
        for position in positions {
            XCTAssertTrue(offsets.contains { offset in
                let translated = CGPoint(x: position.x + offset.x, y: position.y + offset.y)
                return translated.x >= 0 && translated.x <= 8 && translated.y >= 0 && translated.y <= 8
            })
        }
    }

    func testEmptyGeometryHasNoPathOrCopies() {
        XCTAssertEqual(wrapped([], previous: []), [])
        XCTAssertEqual(SnakeGeometry.tileOffsets(for: [], columns: 8, rows: 8), [])
    }

    private func wrapped(_ snake: [GridPoint], previous: [GridPoint], direction: Direction = .right,
                         progress: CGFloat = 0.5) -> [CGPoint] {
        SnakeGeometry.positions(snake: snake, previous: previous, direction: direction,
                                progress: progress, columns: 8, rows: 8, wrapsEdges: true)
    }

    private func assertAdjacent(_ positions: [CGPoint], file: StaticString = #filePath, line: UInt = #line) {
        for (preceding, current) in zip(positions, positions.dropFirst()) {
            XCTAssertLessThanOrEqual(abs(preceding.x - current.x) + abs(preceding.y - current.y),
                                     1, file: file, line: line)
        }
    }

    private func project(_ point: CGPoint) -> GridPoint {
        GridPoint(x: (Int(floor(point.x)) % 8 + 8) % 8, y: (Int(floor(point.y)) % 8 + 8) % 8)
    }

    private func point(_ x: Int, _ y: Int) -> GridPoint { GridPoint(x: x, y: y) }
}
