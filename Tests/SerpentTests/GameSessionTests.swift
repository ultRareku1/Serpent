import AppKit
import XCTest
@testable import Serpent

@MainActor
final class GameSessionTests: XCTestCase {
    func testLosingAppFocusPausesAndReturningDoesNotAutoResume() async throws {
        let fixture = makeIsolatedSession()
        defer {
            fixture.session.pause()
            fixture.defaults.removePersistentDomain(forName: fixture.suiteName)
        }
        let session = fixture.session
        session.newGame()
        XCTAssertEqual(session.engine.phase, .running)

        NotificationCenter.default.post(name: NSApplication.didResignActiveNotification, object: nil)
        try await Task.sleep(nanoseconds: 20_000_000)

        XCTAssertEqual(session.engine.phase, .paused)
        XCTAssertTrue(session.automaticallyPaused)
        let pausedSnake = session.engine.snake
        let pausedScore = session.engine.score
        try await Task.sleep(nanoseconds: 30_000_000)
        XCTAssertEqual(session.engine.snake, pausedSnake)
        XCTAssertEqual(session.engine.score, pausedScore)

        NotificationCenter.default.post(name: NSApplication.didBecomeActiveNotification, object: nil)
        try await Task.sleep(nanoseconds: 20_000_000)
        XCTAssertEqual(session.engine.phase, .paused)
        XCTAssertTrue(session.automaticallyPaused)
        XCTAssertEqual(session.engine.snake, pausedSnake)
        XCTAssertEqual(session.engine.score, pausedScore)
    }

    func testWorkspaceSleepNotificationPausesTheRunningGame() async throws {
        let fixture = makeIsolatedSession()
        defer {
            fixture.session.pause()
            fixture.defaults.removePersistentDomain(forName: fixture.suiteName)
        }
        let session = fixture.session
        session.newGame()
        XCTAssertEqual(session.engine.phase, .running)

        NSWorkspace.shared.notificationCenter.post(name: NSWorkspace.willSleepNotification, object: nil)
        try await Task.sleep(nanoseconds: 20_000_000)

        XCTAssertEqual(session.engine.phase, .paused)
        XCTAssertTrue(session.automaticallyPaused)
        let pausedSnake = session.engine.snake
        let pausedScore = session.engine.score
        try await Task.sleep(nanoseconds: 30_000_000)
        XCTAssertEqual(session.engine.snake, pausedSnake)
        XCTAssertEqual(session.engine.score, pausedScore)
    }

    func testWindowMinimizingPausesTheRunningGame() async throws {
        let fixture = makeIsolatedSession()
        defer {
            fixture.session.pause()
            fixture.defaults.removePersistentDomain(forName: fixture.suiteName)
        }
        let session = fixture.session
        session.newGame()
        XCTAssertEqual(session.engine.phase, .running)

        NotificationCenter.default.post(name: NSWindow.didMiniaturizeNotification, object: nil)
        try await Task.sleep(nanoseconds: 20_000_000)

        XCTAssertEqual(session.engine.phase, .paused)
        XCTAssertTrue(session.automaticallyPaused)
        let pausedSnake = session.engine.snake
        let pausedScore = session.engine.score
        try await Task.sleep(nanoseconds: 30_000_000)
        XCTAssertEqual(session.engine.snake, pausedSnake)
        XCTAssertEqual(session.engine.score, pausedScore)
    }

    func testReadyGameRemainsReadyWhenAppLosesFocus() async throws {
        let fixture = makeIsolatedSession()
        defer {
            fixture.session.pause()
            fixture.defaults.removePersistentDomain(forName: fixture.suiteName)
        }
        let session = fixture.session
        let initialSnake = session.engine.snake
        XCTAssertEqual(session.engine.phase, .ready)

        NotificationCenter.default.post(name: NSApplication.didResignActiveNotification, object: nil)
        try await Task.sleep(nanoseconds: 20_000_000)

        XCTAssertEqual(session.engine.phase, .ready)
        XCTAssertFalse(session.automaticallyPaused)
        XCTAssertEqual(session.engine.snake, initialSnake)
        XCTAssertEqual(session.engine.score, 0)
    }

    func testWrapPreferenceDefaultsOffAndPersistsIndependently() {
        let fixture = makeIsolatedSession()
        defer {
            fixture.session.pause()
            fixture.defaults.removePersistentDomain(forName: fixture.suiteName)
        }
        let preferences = fixture.session.preferences
        XCTAssertFalse(preferences.wrapsEdges)
        preferences.wrapsEdges = true
        let restored = Preferences(defaults: fixture.defaults)
        XCTAssertTrue(restored.wrapsEdges)
        XCTAssertEqual(restored.difficulty, .easy)
        XCTAssertFalse(restored.soundEnabled)
        preferences.wrapsEdges = false
        XCTAssertFalse(Preferences(defaults: fixture.defaults).wrapsEdges)
    }

    func testWrapSettingUpdatesReadyBoardAndAppliesNextGameDuringRun() {
        let fixture = makeIsolatedSession()
        defer {
            fixture.session.pause()
            fixture.defaults.removePersistentDomain(forName: fixture.suiteName)
        }
        let session = fixture.session
        session.preferences.wrapsEdges = true
        session.updateReadyConfiguration()
        XCTAssertEqual(session.engine.phase, .ready)
        XCTAssertTrue(session.engine.wrapsEdges)
        session.newGame()
        let currentSnake = session.engine.snake
        session.preferences.wrapsEdges = false
        session.updateReadyConfiguration()
        XCTAssertTrue(session.engine.wrapsEdges)
        XCTAssertEqual(session.engine.snake, currentSnake)
        session.pause()
        session.closeSettings()
        XCTAssertTrue(session.engine.wrapsEdges)
        session.newGame()
        XCTAssertFalse(session.engine.wrapsEdges)
    }

    func testWrapModeLoadsSeparateRecordsAndPreservesClassicScores() {
        let fixture = makeIsolatedSession()
        defer {
            fixture.session.pause()
            fixture.defaults.removePersistentDomain(forName: fixture.suiteName)
        }
        fixture.defaults.set(200, forKey: "serpent.best.easy")
        fixture.defaults.set(50, forKey: "serpent.best.easy.wrap")
        let session = fixture.session
        session.updateReadyConfiguration()
        XCTAssertEqual(session.bestScore, 200)
        session.preferences.wrapsEdges = true
        session.updateReadyConfiguration()
        XCTAssertEqual(session.bestScore, 50)
        session.newGame()
        session.preferences.wrapsEdges = false
        session.updateReadyConfiguration()
        XCTAssertEqual(session.bestScore, 50)
        session.newGame()
        XCTAssertEqual(session.bestScore, 200)
        XCTAssertEqual(fixture.defaults.integer(forKey: "serpent.best.easy"), 200)
        XCTAssertEqual(fixture.defaults.integer(forKey: "serpent.best.easy.wrap"), 50)
    }

    private func makeIsolatedSession() -> (session: GameSession, defaults: UserDefaults, suiteName: String) {
        let suiteName = "SerpentTests.Lifecycle.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.set(false, forKey: "serpent.sound")
        defaults.set(Difficulty.easy.rawValue, forKey: "serpent.difficulty")
        let preferences = Preferences(defaults: defaults)
        return (GameSession(preferences: preferences, defaults: defaults), defaults, suiteName)
    }
}
