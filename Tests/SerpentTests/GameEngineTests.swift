import XCTest
@testable import Serpent

final class GameEngineTests: XCTestCase {
    func testInitialBoardIsStationaryAndCentered() {
        var game = GameEngine()
        let initialSnake = game.snake

        XCTAssertEqual(game.phase, .ready)
        XCTAssertFalse(game.wrapsEdges)
        XCTAssertEqual(game.direction, .right)
        XCTAssertEqual(game.snake, [point(15, 11), point(14, 11), point(13, 11), point(12, 11)])
        XCTAssertEqual(game.tick(), .idle)
        XCTAssertEqual(game.snake, initialSnake)
        XCTAssertNotNil(game.food)
        XCTAssertFalse(game.snake.contains(game.food!))
    }

    func testDirectReversalAndRepeatedDirectionAreIgnored() {
        var game = layout(head: point(5, 5))
        game.enqueue(.left)
        game.enqueue(.right)

        XCTAssertEqual(game.tick(), .moved)
        XCTAssertEqual(game.direction, .right)
        XCTAssertEqual(game.snake.first, point(6, 5))
    }

    func testRapidLegalTurnsAreAppliedAcrossSeparateTicks() {
        var game = layout(head: point(5, 5))
        game.enqueue(.up)
        game.enqueue(.left)
        game.enqueue(.down) // Only the first two legal turns fit in the queue.

        XCTAssertEqual(game.tick(), .moved)
        XCTAssertEqual(game.direction, .up)
        XCTAssertEqual(game.snake.first, point(5, 4))
        XCTAssertEqual(game.tick(), .moved)
        XCTAssertEqual(game.direction, .left)
        XCTAssertEqual(game.snake.first, point(4, 4))
        XCTAssertEqual(game.tick(), .moved)
        XCTAssertEqual(game.direction, .left)
        XCTAssertEqual(game.snake.first, point(3, 4))
    }

    func testQueuedReversalCannotUndoAValidTurn() {
        var game = layout(head: point(5, 5))
        game.enqueue(.up)
        game.enqueue(.down)
        game.enqueue(.up)
        game.enqueue(.left)

        XCTAssertEqual(game.tick(), .moved)
        XCTAssertEqual(game.direction, .up)
        XCTAssertEqual(game.tick(), .moved)
        XCTAssertEqual(game.direction, .left)
    }

    func testWallCollisionEndsGameWithoutMovingSnake() {
        var game = GameEngine(columns: 8, rows: 8, snake: [point(7, 3), point(6, 3), point(5, 3)], food: point(1, 1))
        let initialSnake = game.snake

        XCTAssertFalse(game.wrapsEdges)
        XCTAssertEqual(game.tick(), .gameOver)
        XCTAssertEqual(game.phase, .gameOver)
        XCTAssertEqual(game.snake, initialSnake)
        XCTAssertEqual(game.tick(), .idle)
    }

    func testEnabledWrappingCrossesAllFourEdges() {
        let crossings: [(GridPoint, Direction, GridPoint)] = [
            (point(7, 3), .right, point(0, 3)),
            (point(0, 3), .left, point(7, 3)),
            (point(3, 0), .up, point(3, 7)),
            (point(3, 7), .down, point(3, 0))
        ]

        for (head, direction, expectedHead) in crossings {
            var game = GameEngine(
                columns: 8, rows: 8, wrapsEdges: true,
                snake: [head], food: point(4, 4), direction: direction
            )

            XCTAssertEqual(game.tick(), .moved)
            XCTAssertEqual(game.snake, [expectedHead])
            XCTAssertEqual(game.direction, direction)
            XCTAssertEqual(game.phase, .running)
            XCTAssertEqual(game.score, 0)
        }
    }

    func testEatingAcrossAnEdgeGrowsAndAwardsDifficultyScore() {
        for difficulty in Difficulty.allCases {
            var game = GameEngine(
                columns: 8, rows: 8, difficulty: difficulty, wrapsEdges: true,
                snake: [point(7, 3), point(6, 3), point(5, 3)], food: point(0, 3)
            )

            XCTAssertEqual(game.tick(), .ate)
            XCTAssertEqual(game.snake, [point(0, 3), point(7, 3), point(6, 3), point(5, 3)])
            XCTAssertEqual(game.score, difficulty.pointsPerFood)
            XCTAssertEqual(game.foodsEaten, 1)
            XCTAssertEqual(game.phase, .running)
            XCTAssertNotNil(game.food)
            XCTAssertFalse(game.snake.contains(game.food!))
        }
    }

    func testWrappingIntoBodyStillEndsGameWithoutMovingSnake() {
        var game = GameEngine(
            columns: 8, rows: 8, wrapsEdges: true,
            snake: [point(7, 3), point(7, 4), point(0, 4), point(0, 3), point(1, 3)],
            food: point(4, 4)
        )
        let initialSnake = game.snake

        XCTAssertEqual(game.tick(), .gameOver)
        XCTAssertEqual(game.phase, .gameOver)
        XCTAssertEqual(game.snake, initialSnake)
        XCTAssertEqual(game.score, 0)
    }

    func testWrappingIntoDepartingTailIsLegal() {
        var game = GameEngine(
            columns: 8, rows: 8, wrapsEdges: true,
            snake: [point(7, 3), point(7, 4), point(0, 4), point(0, 3)],
            food: point(4, 4)
        )

        XCTAssertEqual(game.tick(), .moved)
        XCTAssertEqual(game.phase, .running)
        XCTAssertEqual(game.snake, [point(0, 3), point(7, 3), point(7, 4), point(0, 4)])
    }

    func testQueuedTurnsAndReversalProtectionContinueAfterWrapping() {
        var game = GameEngine(
            columns: 8, rows: 8, wrapsEdges: true,
            snake: [point(7, 0), point(6, 0), point(5, 0)], food: point(4, 4)
        )

        XCTAssertEqual(game.tick(), .moved)
        XCTAssertEqual(game.snake.first, point(0, 0))
        game.enqueue(.left) // Reversing toward the body remains forbidden at the seam.
        game.enqueue(.up)
        game.enqueue(.down) // A reversal of the queued turn is also forbidden.
        game.enqueue(.left)

        XCTAssertEqual(game.tick(), .moved)
        XCTAssertEqual(game.direction, .up)
        XCTAssertEqual(game.snake.first, point(0, 7))
        XCTAssertEqual(game.tick(), .moved)
        XCTAssertEqual(game.direction, .left)
        XCTAssertEqual(game.snake.first, point(7, 7))
        XCTAssertEqual(game.phase, .running)
    }

    func testEatingAcrossAnEdgeCanFillTheBoardAndWin() {
        var game = GameEngine(
            columns: 4, rows: 1, wrapsEdges: true,
            snake: [point(3, 0), point(2, 0), point(1, 0)], food: point(0, 0)
        )

        XCTAssertEqual(game.tick(), .won)
        XCTAssertEqual(game.snake, [point(0, 0), point(3, 0), point(2, 0), point(1, 0)])
        XCTAssertEqual(game.phase, .won)
        XCTAssertEqual(game.score, Difficulty.normal.pointsPerFood)
        XCTAssertEqual(game.foodsEaten, 1)
        XCTAssertNil(game.food)
        XCTAssertEqual(game.tick(), .idle)
    }

    func testResetPreservesEnabledWrapping() {
        var game = GameEngine(columns: 8, rows: 8, difficulty: .hard, wrapsEdges: true)
        game.start()
        game.enqueue(.up)
        game.reset()

        XCTAssertTrue(game.wrapsEdges)
        XCTAssertEqual(game.difficulty, .hard)
        XCTAssertEqual(game.phase, .ready)
        game.start()
        game.tick()
        XCTAssertEqual(game.direction, .right)
        XCTAssertEqual(game.snake.first, point(6, 4))
        XCTAssertEqual(game.phase, .running)
    }

    func testRepeatedWrappingKeepsEveryDirectionWithinBoard() {
        for direction in Direction.allCases {
            var game = GameEngine(
                columns: 5, rows: 3, wrapsEdges: true,
                snake: [point(0, 0)], food: nil, direction: direction
            )

            for _ in 0..<37 {
                XCTAssertEqual(game.tick(), .moved)
                XCTAssertEqual(game.phase, .running)
                XCTAssertTrue(game.snake.allSatisfy {
                    (0..<game.columns).contains($0.x) && (0..<game.rows).contains($0.y)
                })
                XCTAssertEqual(game.snake.count, 1)
                XCTAssertEqual(game.direction, direction)
            }
        }
    }

    func testBodyCollisionEndsGame() {
        var game = GameEngine(
            columns: 8, rows: 8,
            snake: [point(3, 3), point(3, 4), point(4, 4), point(4, 3), point(4, 2)],
            food: point(0, 0)
        )

        XCTAssertEqual(game.tick(), .gameOver)
        XCTAssertEqual(game.phase, .gameOver)
        XCTAssertEqual(game.score, 0)
    }

    func testMovingIntoDepartingTailIsLegal() {
        var game = GameEngine(
            columns: 8, rows: 8,
            snake: [point(3, 3), point(3, 4), point(4, 4), point(4, 3)],
            food: point(0, 0)
        )

        XCTAssertEqual(game.tick(), .moved)
        XCTAssertEqual(game.phase, .running)
        XCTAssertEqual(game.snake, [point(4, 3), point(3, 3), point(3, 4), point(4, 4)])
    }

    func testEatingGrowsSnakeAndAwardsDifficultyScore() {
        for difficulty in Difficulty.allCases {
            var game = GameEngine(
                columns: 8, rows: 8, difficulty: difficulty,
                snake: [point(3, 3), point(2, 3), point(1, 3)],
                food: point(4, 3)
            )

            XCTAssertEqual(game.tick(), .ate)
            XCTAssertEqual(game.snake, [point(4, 3), point(3, 3), point(2, 3), point(1, 3)])
            XCTAssertEqual(game.score, difficulty.pointsPerFood)
            XCTAssertEqual(game.foodsEaten, 1)
            XCTAssertNotNil(game.food)
            XCTAssertFalse(game.snake.contains(game.food!))
            XCTAssertTrue((0..<game.columns).contains(game.food!.x))
            XCTAssertTrue((0..<game.rows).contains(game.food!.y))
        }
    }

    func testFillingTheBoardWinsAndClearsFood() {
        let food = point(1, 0)
        let snake = [point(0, 0), point(0, 1), point(1, 1), point(2, 1), point(2, 0)]
        var game = GameEngine(columns: 3, rows: 2, difficulty: .hard, snake: snake, food: food)

        XCTAssertEqual(game.tick(), .won)
        XCTAssertEqual(game.phase, .won)
        XCTAssertEqual(game.snake.count, 6)
        XCTAssertEqual(Set(game.snake).count, 6)
        XCTAssertEqual(game.score, 30)
        XCTAssertEqual(game.foodsEaten, 1)
        XCTAssertNil(game.food)
        XCTAssertEqual(game.tick(), .idle)
    }

    func testFoodSpawnsInTheOnlyRemainingFreeCell() {
        var game = GameEngine(
            columns: 5, rows: 1,
            snake: [point(3, 0), point(2, 0), point(1, 0)],
            food: point(4, 0)
        )

        XCTAssertEqual(game.tick(), .ate)
        XCTAssertEqual(game.food, point(0, 0))
        XCTAssertEqual(game.snake.count, 4)
        XCTAssertEqual(game.phase, .running)
    }

    func testPauseIsStationaryIgnoresInputAndClearsBufferedTurns() {
        var game = layout(head: point(5, 5))
        let initialSnake = game.snake
        game.enqueue(.up)
        game.pause()
        game.enqueue(.down)

        XCTAssertEqual(game.phase, .paused)
        XCTAssertEqual(game.tick(), .idle)
        XCTAssertEqual(game.snake, initialSnake)
        game.resume()
        XCTAssertEqual(game.tick(), .moved)
        XCTAssertEqual(game.direction, .right)
        XCTAssertEqual(game.snake.first, point(6, 5))
    }

    func testResetRestoresReadyBoardAndRemovesScoreAndQueuedTurns() {
        var game = GameEngine(
            columns: 12, rows: 10, difficulty: .hard,
            snake: [point(5, 5), point(4, 5), point(3, 5)],
            food: point(6, 5)
        )
        XCTAssertEqual(game.tick(), .ate)
        game.enqueue(.up)
        game.reset()

        XCTAssertEqual(game.phase, .ready)
        XCTAssertEqual(game.direction, .right)
        XCTAssertEqual(game.difficulty, .hard)
        XCTAssertEqual(game.score, 0)
        XCTAssertEqual(game.foodsEaten, 0)
        XCTAssertEqual(game.snake, [point(7, 5), point(6, 5), point(5, 5), point(4, 5)])
        XCTAssertFalse(game.snake.contains(game.food!))
        game.start()
        XCTAssertEqual(game.tick(), .moved)
        XCTAssertEqual(game.direction, .right)
    }

    func testStartRestartsAfterGameOver() {
        var game = GameEngine(columns: 8, rows: 8, snake: [point(7, 3), point(6, 3)], food: point(0, 0))
        XCTAssertEqual(game.tick(), .gameOver)
        game.start()

        XCTAssertEqual(game.phase, .running)
        XCTAssertEqual(game.snake.count, 4)
        XCTAssertEqual(game.score, 0)
        XCTAssertEqual(game.direction, .right)
    }

    func testDifficultyIntervalsIncreaseChallenge() {
        XCTAssertEqual(Difficulty.easy.stepInterval, 0.16)
        XCTAssertEqual(Difficulty.normal.stepInterval, 0.105)
        XCTAssertEqual(Difficulty.hard.stepInterval, 0.07)
        XCTAssertEqual(Difficulty.allCases.map(\.pointsPerFood), [10, 20, 30])
    }

    private func point(_ x: Int, _ y: Int) -> GridPoint { GridPoint(x: x, y: y) }

    private func layout(head: GridPoint) -> GameEngine {
        GameEngine(
            columns: 12, rows: 12,
            snake: [head, point(head.x - 1, head.y), point(head.x - 2, head.y), point(head.x - 3, head.y)],
            food: point(0, 0)
        )
    }
}
