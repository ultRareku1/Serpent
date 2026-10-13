import AppKit
import Combine
import SwiftUI

enum Appearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
    var symbol: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }
}

@MainActor
final class Preferences: ObservableObject {
    private let defaults: UserDefaults
    @Published var appearance: Appearance {
        didSet { defaults.set(appearance.rawValue, forKey: "serpent.appearance") }
    }
    @Published var difficulty: Difficulty {
        didSet { defaults.set(difficulty.rawValue, forKey: "serpent.difficulty") }
    }
    @Published var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: "serpent.sound") }
    }
    @Published var wrapsEdges: Bool {
        didSet { defaults.set(wrapsEdges, forKey: "serpent.wrapEdges") }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        appearance = Appearance(rawValue: defaults.string(forKey: "serpent.appearance") ?? "system") ?? .system
        difficulty = Difficulty(rawValue: defaults.string(forKey: "serpent.difficulty") ?? "normal") ?? .normal
        soundEnabled = defaults.object(forKey: "serpent.sound") as? Bool ?? true
        wrapsEdges = defaults.bool(forKey: "serpent.wrapEdges")
    }
}

struct Palette {
    let dark: Bool
    var background: Color { dark ? Color(hex: 0x131715) : Color(hex: 0xF7F8F3) }
    var surface: Color { dark ? Color(hex: 0x1C221E) : .white }
    var board: Color { dark ? Color(hex: 0x1B241F) : Color(hex: 0xECF1E8) }
    var foreground: Color { dark ? Color(hex: 0xEFF5ED) : Color(hex: 0x20352A) }
    var secondary: Color { dark ? Color(hex: 0x93A397) : Color(hex: 0x748478) }
    var accent: Color { dark ? Color(hex: 0xC8EEAE) : Color(hex: 0x2D6243) }
    var accentText: Color { dark ? Color(hex: 0x23341D) : .white }
    var line: Color { dark ? Color(hex: 0x2C372F) : Color(hex: 0xE0E6DB) }
    var subtle: Color { dark ? Color(hex: 0x253028) : Color(hex: 0xEFF3E9) }
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 255) / 255,
                  green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: 1)
    }
}

extension NSColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(srgbRed: CGFloat((hex >> 16) & 255) / 255,
                  green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: alpha)
    }
}
