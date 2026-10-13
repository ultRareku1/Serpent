import Foundation

struct GridPoint: Equatable, Hashable {
    let x: Int
    let y: Int

    static func + (lhs: GridPoint, rhs: GridPoint) -> GridPoint {
        GridPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
}

enum Direction: CaseIterable, Equatable {
    case up, right, down, left

    var vector: GridPoint {
        switch self {
        case .up: GridPoint(x: 0, y: -1)
        case .right: GridPoint(x: 1, y: 0)
        case .down: GridPoint(x: 0, y: 1)
        case .left: GridPoint(x: -1, y: 0)
        }
    }

    var opposite: Direction {
        switch self {
        case .up: .down
        case .right: .left
        case .down: .up
        case .left: .right
        }
    }
}

enum Difficulty: String, CaseIterable {
    case easy, normal, hard

    var stepInterval: TimeInterval {
        switch self {
        case .easy: 0.16
        case .normal: 0.105
        case .hard: 0.07
        }
    }

    var pointsPerFood: Int {
        switch self {
        case .easy: 10
        case .normal: 20
        case .hard: 30
        }
    }

    var key: String { rawValue }
}

enum GamePhase: Equatable {
    case ready, running, paused, gameOver, won
}

enum TickResult: Equatable {
    case idle, moved, ate, gameOver, won
}

/// The board uses integer cells; rendering and timing are handled by the UI.
struct GameEngine {
    private(set) var snake: [GridPoint]
    private(set) var food: GridPoint?
    private(set) var direction: Direction
    private(set) var phase: GamePhase
    private(set) var score: Int
    private(set) var foodsEaten: Int

    var columns: Int
    var rows: Int
    var difficulty: Difficulty
    var wrapsEdges: Bool

    private var pendingDirections: [Direction] = []

    init(columns: Int = 28, rows: Int = 22, difficulty: Difficulty = .normal, wrapsEdges: Bool = false) {
        precondition(columns > 0 && rows > 0, "The board must contain at least one cell.")
        self.columns = columns
        self.rows = rows
        self.difficulty = difficulty
        self.wrapsEdges = wrapsEdges
        snake = Self.initialSnake(columns: columns, rows: rows)
        food = nil
        direction = .right
        phase = .ready
        score = 0
        foodsEaten = 0
        placeFood()
        if food == nil { phase = .won }
    }

    /// An explicit starting layout makes collision and growth rules reproducible.
    init(
        columns: Int,
        rows: Int,
        difficulty: Difficulty = .normal,
        wrapsEdges: Bool = false,
        snake: [GridPoint],
        food: GridPoint?,
        direction: Direction = .right,
        phase: GamePhase = .running,
        score: Int = 0,
        foodsEaten: Int = 0
    ) {
        precondition(columns > 0 && rows > 0)
        precondition(!snake.isEmpty && Set(snake).count == snake.count)
        precondition(snake.allSatisfy { $0.x >= 0 && $0.x < columns && $0.y >= 0 && $0.y < rows })
        if let food {
            precondition(food.x >= 0 && food.x < columns && food.y >= 0 && food.y < rows)
            precondition(!snake.contains(food))
        }
        self.columns = columns
        self.rows = rows
        self.difficulty = difficulty
        self.wrapsEdges = wrapsEdges
        self.snake = snake
        self.food = food
        self.direction = direction
        self.phase = phase
        self.score = score
        self.foodsEaten = foodsEaten
    }

    mutating func start() {
        if phase == .gameOver || phase == .won { reset() }
        if phase == .ready || phase == .paused { phase = .running }
    }

    mutating func reset() {
        precondition(columns > 0 && rows > 0)
        snake = Self.initialSnake(columns: columns, rows: rows)
        direction = .right
        phase = .ready
        score = 0
        foodsEaten = 0
        pendingDirections.removeAll(keepingCapacity: true)
        placeFood()
        if food == nil { phase = .won }
    }

    mutating func pause() {
        guard phase == .running else { return }
        phase = .paused
        pendingDirections.removeAll(keepingCapacity: true)
    }

    mutating func resume() {
        guard phase == .paused else { return }
        phase = .running
    }

    mutating func enqueue(_ nextDirection: Direction) {
        guard phase == .running || phase == .ready else { return }
        guard pendingDirections.count < 2 else { return }
        let lastDirection = pendingDirections.last ?? direction
        guard nextDirection != lastDirection, nextDirection != lastDirection.opposite else { return }
        pendingDirections.append(nextDirection)
    }

    @discardableResult
    mutating func tick() -> TickResult {
        guard phase == .running else { return .idle }
        if !pendingDirections.isEmpty {
            direction = pendingDirections.removeFirst()
        }

        let candidateHead = snake[0] + direction.vector
        let nextHead = wrapsEdges
            ? GridPoint(
                x: (candidateHead.x % columns + columns) % columns,
                y: (candidateHead.y % rows + rows) % rows
            )
            : candidateHead
        guard nextHead.x >= 0 && nextHead.x < columns,
              nextHead.y >= 0 && nextHead.y < rows else {
            phase = .gameOver
            pendingDirections.removeAll(keepingCapacity: true)
            return .gameOver
        }

        let willEat = nextHead == food
        // A non-growing move may enter the cell that the tail vacates this tick.
        let occupiedCells = willEat ? snake[...] : snake.dropLast()
        guard !occupiedCells.contains(nextHead) else {
            phase = .gameOver
            pendingDirections.removeAll(keepingCapacity: true)
            return .gameOver
        }

        snake.insert(nextHead, at: 0)
        if !willEat {
            snake.removeLast()
            return .moved
        }

        score += difficulty.pointsPerFood
        foodsEaten += 1
        placeFood()
        if food == nil {
            phase = .won
            pendingDirections.removeAll(keepingCapacity: true)
            return .won
        }
        return .ate
    }

    private static func initialSnake(columns: Int, rows: Int) -> [GridPoint] {
        let length = min(4, columns)
        let left = (columns - length) / 2
        return (0..<length).reversed().map { GridPoint(x: left + $0, y: rows / 2) }
    }

    private mutating func placeFood() {
        let occupied = Set(snake)
        var freeCells: [GridPoint] = []
        freeCells.reserveCapacity(max(0, columns * rows - snake.count))
        for y in 0..<rows {
            for x in 0..<columns {
                let point = GridPoint(x: x, y: y)
                if !occupied.contains(point) { freeCells.append(point) }
            }
        }
        food = freeCells.randomElement()
    }
}
