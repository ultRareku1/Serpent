import SwiftUI

struct SettingsView: View {
    @ObservedObject var preferences: Preferences
    @ObservedObject var localization: Localization
    let palette: Palette
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(localization.text("settings.title")).font(.system(size: 29, weight: .semibold, design: .rounded))
                    Text(localization.text("settings.subtitle")).font(.system(size: 13)).foregroundStyle(palette.secondary)
                }
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark").font(.system(size: 12, weight: .medium)).frame(width: 28, height: 28)
                        .background(palette.subtle, in: Circle())
                }.buttonStyle(.plain).help(localization.text("action.close"))
                    .accessibilityLabel(localization.text("action.close"))
            }
            sectionLabel("settings.gameplay")
            VStack(spacing: 0) {
                settingRow(title: "label.difficulty", note: "settings.difficultyNote", symbol: "speedometer") {
                    Picker(localization.text("label.difficulty"), selection: $preferences.difficulty) {
                        ForEach(Difficulty.allCases, id: \.rawValue) { difficulty in
                            Text(localization.text("difficulty.\(difficulty.rawValue)")).tag(difficulty)
                        }
                    }.labelsHidden().frame(width: 175)
                }
                Divider().overlay(palette.line).padding(.leading, 54)
                settingRow(title: "label.wrapEdges", note: "settings.wrapEdgesNote", symbol: "arrow.left.arrow.right") {
                    Toggle(localization.text("label.wrapEdges"), isOn: $preferences.wrapsEdges)
                        .toggleStyle(.switch).tint(palette.accent).labelsHidden()
                }
                Divider().overlay(palette.line).padding(.leading, 54)
                settingRow(title: "label.sound", note: "settings.soundNote", symbol: "speaker.wave.2") {
                    Toggle(localization.text("label.sound"), isOn: $preferences.soundEnabled)
                        .toggleStyle(.switch).tint(palette.accent).labelsHidden()
                }
            }.background(palette.surface, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(palette.line, lineWidth: 1))
            sectionLabel("settings.personalize")
            VStack(spacing: 0) {
                settingRow(title: "label.theme", note: "settings.themeNote", symbol: "circle.lefthalf.filled") {
                    Picker(localization.text("label.theme"), selection: $preferences.appearance) {
                        ForEach(Appearance.allCases) { appearance in
                            Text(localization.text("theme.\(appearance.rawValue)")).tag(appearance)
                        }
                    }.labelsHidden().frame(width: 175)
                }
                Divider().overlay(palette.line).padding(.leading, 54)
                settingRow(title: "label.language", note: "settings.languageNote", symbol: "globe") {
                    Picker(localization.text("label.language"), selection: $localization.language) {
                        ForEach(AppLanguage.allCases) { language in
                            Text("\(language.flag)  \(language == .system ? localization.text("label.system") : language.nativeName)")
                                .tag(language)
                        }
                    }.labelsHidden().frame(width: 175)
                }
            }.background(palette.surface, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(palette.line, lineWidth: 1))
            HStack {
                Text(localization.text("footer.note")).font(.system(size: 11)).foregroundStyle(palette.secondary)
                Spacer()
                Button(localization.text("action.close"), action: onClose)
                    .font(.system(size: 13, weight: .medium)).padding(.horizontal, 16).padding(.vertical, 6)
                    .buttonStyle(AccentButtonStyle(palette: palette)).keyboardShortcut(.defaultAction)
            }
        }
        .padding(32).frame(width: 570).background(palette.background).foregroundStyle(palette.foreground)
        .onExitCommand(perform: onClose)
    }

    private func sectionLabel(_ key: String) -> some View {
        Text(localization.text(key)).font(.system(size: 10, weight: .semibold)).tracking(1.8).foregroundStyle(palette.secondary)
    }

    private func settingRow<Control: View>(title: String, note: String, symbol: String,
                                         @ViewBuilder control: () -> Control) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol).font(.system(size: 17, weight: .light)).foregroundStyle(palette.accent).frame(width: 24)
            VStack(alignment: .leading, spacing: 5) {
                Text(localization.text(title)).font(.system(size: 13, weight: .medium))
                Text(localization.text(note)).font(.system(size: 10)).foregroundStyle(palette.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 12)
            control()
        }.padding(16).frame(minHeight: 74)
    }
}
