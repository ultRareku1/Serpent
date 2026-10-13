import AppKit
import SwiftUI

@main
struct SerpentApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var preferences: Preferences
    @StateObject private var localization: Localization
    @StateObject private var session: GameSession

    init() {
        let preferences = Preferences()
        _preferences = StateObject(wrappedValue: preferences)
        _localization = StateObject(wrappedValue: Localization())
        _session = StateObject(wrappedValue: GameSession(preferences: preferences))
    }

    var body: some Scene {
        Window(localization.text("app.name"), id: "main") {
            ContentView(session: session, preferences: preferences, localization: localization)
                .preferredColorScheme(preferences.appearance.colorScheme)
                .environment(\.locale, Locale(identifier: localization.resolvedLanguage.localeIdentifier))
                .background(WindowAccessor(session: session))
        }
        .defaultSize(width: 1080, height: 800)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button(localization.text("action.newGame")) { session.requestRestart() }
                    .keyboardShortcut("n", modifiers: .command)
            }
            CommandGroup(replacing: .appSettings) {
                Button(localization.text("action.settings") + "…") { session.openSettings() }
                    .keyboardShortcut(",", modifiers: .command)
            }
            CommandMenu(localization.text("menu.game")) {
                Button(localization.text(session.engine.phase == .paused ? "action.resume" : "action.pause")) {
                    session.primaryAction()
                }.keyboardShortcut("p", modifiers: .command)
                Button(localization.text("action.restart")) { session.requestRestart() }
                    .keyboardShortcut("r", modifiers: .command)
            }
            CommandGroup(replacing: .help) {
                Button(localization.text("action.help")) { session.openHelp() }
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

struct WindowAccessor: NSViewRepresentable {
    let session: GameSession
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        context.coordinator.session = session
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.titlebarAppearsTransparent = true
            window.isMovableByWindowBackground = true
            window.backgroundColor = .windowBackgroundColor
            window.collectionBehavior.insert(.fullScreenPrimary)
        }
        context.coordinator.install()
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator() }
    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) { coordinator.uninstall() }

    @MainActor
    final class Coordinator {
        weak var session: GameSession?
        private var keyMonitor: Any?
        func install() {
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard event.window?.sheetParent == nil, event.window?.attachedSheet == nil else { return event }
                return self?.session?.handleKey(event) == true ? nil : event
            }
        }
        func uninstall() {
            if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
            keyMonitor = nil
        }
    }
}
