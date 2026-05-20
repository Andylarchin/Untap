import SwiftUI

// MARK: - UIColor Hex
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: CGFloat
        switch hex.count {
        case 6:
            r = CGFloat((int >> 16) & 0xFF) / 255
            g = CGFloat((int >> 8) & 0xFF) / 255
            b = CGFloat(int & 0xFF) / 255
        default:
            r = 0; g = 0; b = 0
        }
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}

// MARK: - Color Theme
extension Color {
    private static func adaptive(light: String, dark: String) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }

    // Background colors
    static let bg = adaptive(light: "FAF8F5", dark: "141211")
    static let bg2 = adaptive(light: "F0EDE8", dark: "1F1D1B")
    static let card = adaptive(light: "FFFFFF", dark: "1A1816")
    static let line = adaptive(light: "E8E4DD", dark: "2F2B28")

    // Text colors
    static let ink = adaptive(light: "1F1B16", dark: "F5F2ED")
    static let ink2 = adaptive(light: "6B6560", dark: "9C9690")
    static let ink3 = adaptive(light: "9C9690", dark: "6B6560")

    // Accent colors
    static let sage = Color(hex: "7A8F6A")
    static let sageDeep = Color(hex: "5A6F4A")
    static let sageSoft = adaptive(light: "E8EDE4", dark: "2A3A25")

    static let amber = Color(hex: "D68A3C")
    static let rose = Color(hex: "C97B6E")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Custom Fonts
extension Font {
    static func instrumentSerif(size: CGFloat) -> Font {
        .custom("InstrumentSerif-Regular", size: size)
    }

    static func instrumentSerifItalic(size: CGFloat) -> Font {
        .custom("InstrumentSerif-Italic", size: size)
    }

    static func geist(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let weightName: String
        switch weight {
        case .medium: weightName = "Medium"
        case .semibold: weightName = "SemiBold"
        case .bold: weightName = "Bold"
        default: weightName = "Regular"
        }
        return .custom("Geist-\(weightName)", size: size)
    }

    static func geistMono(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let weightName: String
        switch weight {
        case .medium: weightName = "Medium"
        case .semibold: weightName = "SemiBold"
        case .bold: weightName = "Bold"
        default: weightName = "Regular"
        }
        return .custom("GeistMono-\(weightName)", size: size)
    }
}

// MARK: - Reusable Styles
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.card)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.line, lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

// MARK: - Label Style
struct MonoLabelStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.geistMono(size: 10))
            .kerning(1.2)
            .textCase(.uppercase)
            .foregroundColor(.ink3)
    }
}

extension View {
    func monoLabel() -> some View {
        modifier(MonoLabelStyle())
    }
}
