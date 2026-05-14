import SwiftUI

enum AppTheme {

    // MARK: - Colors

    enum Colors {
        static let black = Color(hex: "#000000")
        static let offWhite = Color(hex: "#F7F7F5")
        static let successGreen = Color(hex: "#5FD38D")
        static let streakDanger = Color(hex: "#FF6B6B")
        static let coolBlue = Color(hex: "#6BA8FF")
        static let darkBackground = Color(hex: "#111111")

        static var background: Color { Color(UIColor.systemBackground) }
        static var primaryText: Color { Color(UIColor.label) }
        static var secondaryText: Color { Color(UIColor.secondaryLabel) }
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 40
        static let xxl: CGFloat = 64
    }

    // MARK: - Corner Radius

    enum Radius {
        static let pill: CGFloat = 999
        static let card: CGFloat = 16
        static let small: CGFloat = 8
    }

    // MARK: - Font

    enum Font {
        static func display() -> SwiftUI.Font {
            .system(size: 64, weight: .heavy, design: .rounded)
        }
        static func title() -> SwiftUI.Font {
            .system(size: 32, weight: .bold, design: .rounded)
        }
        static func headline() -> SwiftUI.Font {
            .system(size: 18, weight: .semibold, design: .rounded)
        }
        static func body() -> SwiftUI.Font {
            .system(size: 16, weight: .regular, design: .default)
        }
        static func caption() -> SwiftUI.Font {
            .system(size: 13, weight: .regular, design: .default)
        }
    }
}

// MARK: - Color hex init

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
        default:
            r = 0; g = 0; b = 0
        }
        self.init(red: r, green: g, blue: b)
    }
}
