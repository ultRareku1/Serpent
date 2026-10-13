import SwiftUI

struct ContentView: View {
    @ObservedObject var session: GameSession
    @ObservedObject var preferences: Preferences
    @ObservedObject var localization: Localization
    @Environment(\.colorScheme) private var colorScheme
    private var palette: Palette { Palette(dark: colorScheme == .dark) }

    var body: some View {
        VStack(spacing: 26) {
            header
            GeometryReader { geometry in
                let width = min(geometry.size.width - 280, geometry.size.height * 28 / 22)
                HStack(spacing: 32) {
                    board.frame(width: width, height: width * 22 / 28)
                    sidebar.frame(width: 248)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            footer
        }
        .padding(.horizontal, 48)
        .padding(.top, 40)
        .padding(.bottom, 30)
        .frame(minWidth: 940, minHeight: 730)
        .background(palette.background)
        .foregroundStyle(palette.foreground)
        .sheet(isPresented: $session.showSettings, onDismiss: { session.closeSettings() }) {
            SettingsView(preferences: preferences, localization: localization, palette: palette) { session.closeSettings() }
                .preferredColorScheme(preferences.appearance.colorScheme)
        }
        .sheet(isPresented: $session.showHelp) {
            helpView.preferredColorScheme(preferences.appearance.colorScheme)
        }
        .alert(localization.text("confirmation.restartTitle"), isPresented: $session.confirmRestart) {
            Button(localization.text("action.cancel"), role: .cancel) { session.cancelRestart() }
            Button(localization.text("action.newGame")) { session.newGame() }
        } message: { Text(localization.text("confirmation.restartBody")) }
        .onChange(of: preferences.difficulty) { _ in session.updateReadyConfiguration() }
        .onChange(of: preferences.wrapsEdges) { _ in session.updateReadyConfiguration() }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 8) {
                Text(localization.text("header.subtitle"))
                    .font(.system(size: 10, weight: .semibold)).tracking(2.5).foregroundStyle(palette.secondary)
                HStack(spacing: 12) {
                    SnakeMark().stroke(palette.accent, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                        .frame(width: 30, height: 34)
                    Text("serpent").font(.system(size: 44, weight: .semibold, design: .rounded)).tracking(-2)
                }
                Text(localization.text("app.tagline")).font(.system(size: 14)).foregroundStyle(palette.secondary)
            }
            Spacer()
            HStack(spacing: 12) {
                Menu {
                    ForEach(Appearance.allCases) { appearance in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { preferences.appearance = appearance }
                        } label: {
                            Label(localization.text("theme.\(appearance.rawValue)"),
                                  systemImage: preferences.appearance == appearance ? "checkmark" : appearance.symbol)
                        }
                    }
                } label: {
                    Image(systemName: preferences.appearance.symbol).font(.system(size: 16)).frame(width: 44, height: 44)
                }
                .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize().frame(width: 44, height: 44)
                .background(palette.surface, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(palette.line, lineWidth: 1))
                .help(localization.text("label.theme"))
                .accessibilityLabel(localization.text("label.theme"))
                Button { session.openSettings() } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "slider.horizontal.3")
                        Text(localization.text("action.settings"))
                    }.font(.system(size: 13, weight: .medium)).padding(.horizontal, 16).frame(height: 44)
                }
                .buttonStyle(.plain)
                .background(palette.surface, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(palette.line, lineWidth: 1))
            }
        }
    }

    private var board: some View {
        ZStack {
            BoardView(session: session, dark: palette.dark, accessibilityLabel: localization.text("accessibility.board"))
            if session.engine.phase != .running {
                palette.board.opacity(0.38)
                stateOverlay.transition(.opacity.combined(with: .scale(scale: 0.97)))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(palette.line, lineWidth: 1))
        .overlay(alignment: .topLeading) {
            if session.engine.wrapsEdges {
                Label(localization.text("status.wrapEdges"), systemImage: "arrow.left.arrow.right")
                    .font(.system(size: 10, weight: .medium)).foregroundStyle(palette.accent)
                    .padding(.horizontal, 10).padding(.vertical, 7)
                    .background(palette.surface.opacity(0.9), in: Capsule()).padding(16)
            }
        }
        .animation(.easeOut(duration: 0.18), value: session.engine.phase)
        .gesture(DragGesture(minimumDistance: 18).onEnded { value in
            if abs(value.translation.width) > abs(value.translation.height) {
                session.turn(value.translation.width > 0 ? .right : .left)
            } else { session.turn(value.translation.height > 0 ? .down : .up) }
        })
    }

    private var stateOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: overlaySymbol)
                .font(.system(size: 23, weight: .light)).foregroundStyle(palette.accent)
                .frame(width: 54, height: 54).background(palette.subtle, in: RoundedRectangle(cornerRadius: 17))
            VStack(spacing: 9) {
                Text(localization.text(overlayTitle)).font(.system(size: 27, weight: .semibold, design: .rounded))
                Text(overlayBody).font(.system(size: 13)).foregroundStyle(palette.secondary)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            }
            if session.isNewRecord && (session.engine.phase == .gameOver || session.engine.phase == .won) {
                Label(localization.text("over.record"), systemImage: "sparkles")
                    .font(.system(size: 12, weight: .medium)).foregroundStyle(palette.accent)
            }
            Button { session.primaryAction() } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill").font(.system(size: 11))
                    Text(localization.text(primaryKey)).font(.system(size: 13, weight: .semibold))
                }.frame(minWidth: 125).padding(.horizontal, 20).frame(height: 40)
            }.buttonStyle(AccentButtonStyle(palette: palette))
            if session.engine.phase == .ready {
                Text(localization.text("ready.hint")).font(.system(size: 11)).foregroundStyle(palette.secondary)
            }
        }
        .padding(28).frame(width: 340)
        .background(palette.surface.opacity(0.97), in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(palette.line, lineWidth: 1))
        .shadow(color: .black.opacity(palette.dark ? 0.12 : 0.04), radius: 18, y: 8)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 4) {
                eyebrow("label.score")
                Text(session.engine.score.formatted(.number.locale(Locale(identifier: localization.resolvedLanguage.localeIdentifier))))
                    .font(.system(size: 76, weight: .light, design: .rounded)).monospacedDigit().tracking(-3)
                    .lineLimit(1).minimumScaleFactor(0.6)
                    .scaleEffect(session.scorePulse ? 1.1 : 1, anchor: .leading)
                    .animation(.spring(response: 0.25, dampingFraction: 0.55), value: session.scorePulse)
                    .accessibilityLabel(localization.formatted("accessibility.score", session.engine.score))
            }
            HStack(spacing: 13) {
                Image(systemName: "laurel.leading").font(.system(size: 30, weight: .light)).foregroundStyle(palette.accent)
                VStack(alignment: .leading, spacing: 5) {
                    Text(localization.text("label.bestRun")).font(.system(size: 10, weight: .medium)).tracking(1).foregroundStyle(palette.secondary)
                    Text(session.bestScore.formatted(.number.locale(Locale(identifier: localization.resolvedLanguage.localeIdentifier))))
                        .font(.system(size: 24, weight: .medium, design: .rounded)).monospacedDigit()
                }
                Spacer(minLength: 0)
            }.padding(18).frame(maxWidth: .infinity, alignment: .leading)
                .background(palette.surface, in: RoundedRectangle(cornerRadius: 17))
                .overlay(RoundedRectangle(cornerRadius: 17).stroke(palette.line, lineWidth: 1))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(localization.formatted("accessibility.best", session.bestScore))
            VStack(alignment: .leading, spacing: 10) {
                eyebrow("label.difficulty")
                HStack(spacing: 6) {
                    ForEach(Difficulty.allCases, id: \.rawValue) { difficulty in
                        Button {
                            if session.engine.phase == .running { session.pause() }
                            preferences.difficulty = difficulty
                        } label: {
                            Text(localization.text("difficulty.\(difficulty.rawValue)"))
                                .font(.system(size: 11, weight: .medium))
                                .frame(maxWidth: .infinity).frame(height: 34)
                                .background(preferences.difficulty == difficulty ? palette.surface : .clear,
                                            in: RoundedRectangle(cornerRadius: 9))
                                .foregroundStyle(preferences.difficulty == difficulty ? palette.foreground : palette.secondary)
                        }.buttonStyle(.plain)
                    }
                }.padding(4).background(palette.subtle, in: RoundedRectangle(cornerRadius: 13))
                if preferences.difficulty != session.engine.difficulty || preferences.wrapsEdges != session.engine.wrapsEdges {
                    Text(localization.text(preferences.wrapsEdges != session.engine.wrapsEdges ? "settings.wrapEdgesPending" : "settings.difficultyNote"))
                        .font(.system(size: 10)).foregroundStyle(palette.secondary)
                } else {
                    HStack(spacing: 5) {
                        ForEach(0..<3) { index in
                            Capsule().fill(index < difficultyLevel ? palette.accent : palette.line).frame(width: 16, height: 3)
                        }
                        Text(localization.text("difficulty.\(session.engine.difficulty.rawValue)Detail"))
                            .font(.system(size: 10)).foregroundStyle(palette.secondary).padding(.leading, 3)
                    }
                }
            }
            VStack(spacing: 10) {
                Button { session.primaryAction() } label: {
                    HStack {
                        Image(systemName: session.engine.phase == .running ? "pause.fill" : "play.fill").font(.system(size: 12))
                        Text(localization.text(primaryKey)).font(.system(size: 14, weight: .semibold))
                        Spacer()
                        Image(systemName: "arrow.right").font(.system(size: 13))
                    }.padding(.horizontal, 19).frame(height: 48)
                }.buttonStyle(AccentButtonStyle(palette: palette))
                Button { session.requestRestart() } label: {
                    Label(localization.text("action.restart"), systemImage: "arrow.counterclockwise")
                        .font(.system(size: 12)).foregroundStyle(palette.secondary).frame(maxWidth: .infinity).frame(height: 30)
                }.buttonStyle(.plain)
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 20) {
            Rectangle().fill(palette.line).frame(height: 1)
            HStack(spacing: 24) {
                HStack(spacing: 8) {
                    keyCap("↑ ↓ ← →")
                    Text(localization.text("hint.move")).font(.system(size: 9, weight: .medium)).tracking(0.8)
                }.help(localization.text("hint.arrows"))
                HStack(spacing: 8) {
                    keyCap("␣")
                    Text(localization.text("hint.pause")).font(.system(size: 9, weight: .medium)).tracking(0.8)
                }
                HStack(spacing: 8) {
                    keyCap("R")
                    Text(localization.text("hint.restart")).font(.system(size: 9, weight: .medium)).tracking(0.8)
                }
                Spacer(minLength: 10)
                HStack(spacing: 7) {
                    Circle().fill(session.engine.phase == .running ? palette.accent : palette.secondary.opacity(0.6)).frame(width: 5, height: 5)
                    Text(localization.text(statusKey)).font(.system(size: 11))
                }
                Button { session.openHelp() } label: { Image(systemName: "questionmark.circle").font(.system(size: 16)) }
                    .buttonStyle(.plain).help(localization.text("action.help"))
                    .accessibilityLabel(localization.text("action.help"))
            }.foregroundStyle(palette.secondary)
        }
    }

    private var helpView: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text(localization.text("help.title")).font(.system(size: 28, weight: .semibold, design: .rounded))
            Text(localization.text("help.body")).font(.system(size: 14)).foregroundStyle(palette.secondary).fixedSize(horizontal: false, vertical: true)
            Text(localization.text("help.shortcuts")).font(.system(size: 13, design: .monospaced)).lineSpacing(10)
            Text(localization.text("help.touch")).font(.system(size: 12)).foregroundStyle(palette.secondary)
            HStack {
                Spacer()
                Button(localization.text("action.close")) { session.showHelp = false }
                    .buttonStyle(AccentButtonStyle(palette: palette)).keyboardShortcut(.defaultAction)
            }
        }.padding(36).frame(width: 460).background(palette.background).foregroundStyle(palette.foreground)
            .onExitCommand { session.showHelp = false }
    }

    private func eyebrow(_ key: String) -> some View {
        Text(localization.text(key).uppercased()).font(.system(size: 10, weight: .medium)).tracking(1.5).foregroundStyle(palette.secondary)
    }
    private func keyCap(_ label: String) -> some View {
        Text(label).font(.system(size: 11, weight: .medium, design: .monospaced))
            .padding(.horizontal, 8).frame(height: 27)
            .background(palette.surface, in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(palette.line, lineWidth: 1))
    }
    private var difficultyLevel: Int {
        switch session.engine.difficulty { case .easy: 1; case .normal: 2; case .hard: 3 }
    }
    private var primaryKey: String {
        switch session.engine.phase {
        case .ready: "action.play"
        case .running: "action.pause"
        case .paused: "action.resume"
        case .gameOver, .won: "action.newGame"
        }
    }
    private var overlayTitle: String {
        switch session.engine.phase {
        case .ready, .running: "ready.title"
        case .paused: "pause.title"
        case .gameOver: "over.title"
        case .won: "won.title"
        }
    }
    private var overlayBody: String {
        switch session.engine.phase {
        case .ready, .running: localization.text("ready.body")
        case .paused: localization.text(session.automaticallyPaused ? "pause.auto" : "pause.body")
        case .gameOver: localization.formatted("over.body", session.engine.score)
        case .won: localization.text("won.body")
        }
    }
    private var overlaySymbol: String {
        switch session.engine.phase {
        case .ready, .running: "leaf"
        case .paused: "pause"
        case .gameOver: session.isNewRecord ? "sparkles" : "arrow.counterclockwise"
        case .won: "crown"
        }
    }
    private var statusKey: String {
        switch session.engine.phase {
        case .ready: "status.ready"
        case .running: "status.running"
        case .paused: "status.paused"
        case .gameOver: "status.gameOver"
        case .won: "status.won"
        }
    }
}

struct SnakeMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width * 0.8, y: rect.height * 0.1))
        path.addLine(to: CGPoint(x: rect.width * 0.35, y: rect.height * 0.1))
        path.addQuadCurve(to: CGPoint(x: rect.width * 0.35, y: rect.height * 0.48),
                          control: CGPoint(x: -rect.width * 0.05, y: rect.height * 0.3))
        path.addLine(to: CGPoint(x: rect.width * 0.65, y: rect.height * 0.48))
        path.addQuadCurve(to: CGPoint(x: rect.width * 0.65, y: rect.height * 0.9),
                          control: CGPoint(x: rect.width * 1.08, y: rect.height * 0.7))
        path.addLine(to: CGPoint(x: rect.width * 0.2, y: rect.height * 0.9))
        return path
    }
}

struct AccentButtonStyle: ButtonStyle {
    let palette: Palette
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 5).padding(.vertical, 3)
            .foregroundStyle(palette.accentText)
            .background(palette.accent.opacity(configuration.isPressed ? 0.8 : 1), in: RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
