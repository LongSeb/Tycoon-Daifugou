import SwiftUI

extension Color {
    static let tycoonBlack = Color(ds: 0x000000)
    static let tycoonSurface = Color(ds: 0x0E0E0E)
    static let cardCream = Color(ds: 0xFFF4E6)
    static let cardBlush = Color(ds: 0xFFD4E5)
    static let cardLavender = Color(ds: 0xE5D4FF)
    static let cardMint = Color(ds: 0xD4FFE5)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let textTertiary = Color.white.opacity(0.4)
}

private extension Color {
    init(ds hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
