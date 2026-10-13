import AppKit
import Combine
import Foundation

@MainActor
final class GameSession: ObservableObject {
    @Published private(set) var engine: GameEngine
    @Published private(set) var previousSnake: [GridPoint]
    @Published private(set) var tickTime = ProcessInfo.processInfo.systemUptime
    @Published private(set) var bestScore: Int
    @Published private(set) var scorePulse = false
    @Published private(set) var isNewRecord = false
    @Published private(set) var automaticallyPaused = false
    @Published var showSettings = false
    @Published var showHelp = false
    @Published var confirmRestart = false
    let preferences: Preferences
    private let defaults: UserDefaults
    private let sound = SoundEngine()
    private var timer: Timer?
    private var pulseTask: Task<Void, Never>?
    private var bestAtStart: Int
    private var observers: [NSObjectProtocol] = []
    private var restartWasRunning = false

    init(preferences: Preferences, defaults: UserDefaults = .standard) {
        self.preferences = preferences
        self.defaults = defaults
        let initial = GameEngine(difficulty: preferences.difficulty, wrapsEdges: preferences.wrapsEdges)
        engine = initial
        previousSnake = initial.snake
        let best = defaults.integer(forKey: Self.bestKey(initial.difficulty, wrapsEdges: initial.wrapsEdges))
        bestScore = best
        bestAtStart = best
        observers.append(NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.pause(automatic: true) }
        })
        observers.append(NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.pause(automatic: true) }
        })
        observers.append(NotificationCenter.default.addObserver(
            forName: NSWindow.didMiniaturizeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.pause(automatic: true) }
        })
    }

    private static func bestKey(_ difficulty: Difficulty, wrapsEdges: Bool) -> String {
        "serpent.best.\(difficulty.rawValue)" + (wrapsEdges ? ".wrap" : "")
    }

    func primaryAction() {
        guard !showSettings && !showHelp && !confirmRestart else { return }
        switch engine.phase {
        case .ready, .gameOver, .won: newGame()
        case .running: pause()
        case .paused: resume()
        }
    }

    func newGame() {
        stopTimer()
        pulseTask?.cancel()
        scorePulse = false
        confirmRestart = false
        engine = GameEngine(difficulty: preferences.difficulty, wrapsEdges: preferences.wrapsEdges)
        previousSnake = engine.snake
        bestScore = defaults.integer(forKey: Self.bestKey(engine.difficulty, wrapsEdges: engine.wrapsEdges))
        bestAtStart = bestScore
        isNewRecord = false
        automaticallyPaused = false
        engine.start()
        tickTime = ProcessInfo.processInfo.systemUptime
        sound.play(.start, enabled: preferences.soundEnabled)
        startTimer()
    }

    func requestRestart() {
        guard !showSettings && !showHelp else { return }
        if (engine.phase == .running || engine.phase == .paused) && engine.foodsEaten > 0 {
            restartWasRunning = engine.phase == .running
            pause()
            confirmRestart = true
        } else { newGame() }
    }

    func cancelRestart() {
        confirmRestart = false
        if restartWasRunning { resume() }
        restartWasRunning = false
    }

    func pause(automatic: Bool = false) {
        guard engine.phase == .running else { return }
        engine.pause()
        stopTimer()
        automaticallyPaused = automatic
        if !automatic { sound.play(.pause, enabled: preferences.soundEnabled) }
    }

    func resume() {
        guard engine.phase == .paused, !showSettings, !showHelp, !confirmRestart,
              NSApp.isActive else { return }
        automaticallyPaused = false
        previousSnake = engine.snake
        tickTime = ProcessInfo.processInfo.systemUptime
        engine.resume()
        startTimer()
    }

    func turn(_ direction: Direction) {
        guard !showSettings && !showHelp && !confirmRestart else { return }
        if engine.phase == .ready { newGame() }
        guard engine.phase == .running else { return }
        engine.enqueue(direction)
    }

    func openSettings() {
        pause()
        showSettings = true
    }

    func closeSettings() {
        showSettings = false
        if engine.phase == .ready { updateReadyConfiguration() }
        // A paused game resumes only after an explicit Play/Space action.
    }

    func openHelp() { pause(); showHelp = true }

    func updateReadyConfiguration() {
        guard engine.phase == .ready || engine.phase == .gameOver || engine.phase == .won else { return }
        if engine.phase == .ready {
            engine = GameEngine(difficulty: preferences.difficulty, wrapsEdges: preferences.wrapsEdges)
            previousSnake = engine.snake
        }
        bestScore = defaults.integer(forKey: Self.bestKey(engine.difficulty, wrapsEdges: engine.wrapsEdges))
    }

    func handleKey(_ event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command) || event.modifierFlags.contains(.control) || event.modifierFlags.contains(.option) { return false }
        if event.keyCode == 53 {
            if showSettings { closeSettings() }
            else if showHelp { showHelp = false }
            else if !confirmRestart { pause() }
            return !confirmRestart
        }
        guard !showSettings && !showHelp && !confirmRestart else { return false }
        switch event.keyCode {
        case 49: primaryAction()
        case 123: turn(.left)
        case 124: turn(.right)
        case 125: turn(.down)
        case 126: turn(.up)
        default:
            switch event.charactersIgnoringModifiers?.lowercased() {
            case "a": turn(.left)
            case "d": turn(.right)
            case "s": turn(.down)
            case "w": turn(.up)
            case "r": requestRestart()
            default: return false
            }
        }
        return true
    }

    private func startTimer() {
        stopTimer()
        let next = Timer(timeInterval: engine.difficulty.stepInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.advance() }
        }
        next.tolerance = 0.002
        RunLoop.main.add(next, forMode: .common)
        timer = next
    }

    private func stopTimer() { timer?.invalidate(); timer = nil }

    private func advance() {
        previousSnake = engine.snake
        tickTime = ProcessInfo.processInfo.systemUptime
        let result = engine.tick()
        switch result {
        case .ate, .won:
            if engine.score > bestScore {
                bestScore = engine.score
                isNewRecord = engine.score > bestAtStart
                defaults.set(bestScore, forKey: Self.bestKey(engine.difficulty, wrapsEdges: engine.wrapsEdges))
            }
            pulseTask?.cancel()
            scorePulse = true
            pulseTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: 180_000_000)
                guard !Task.isCancelled else { return }
                self?.scorePulse = false
            }
            sound.play(result == .won ? .record : .eat, enabled: preferences.soundEnabled)
            if result == .won { stopTimer() }
        case .gameOver:
            stopTimer()
            sound.play(isNewRecord ? .record : .gameOver, enabled: preferences.soundEnabled)
        case .idle, .moved: break
        }
    }
}
