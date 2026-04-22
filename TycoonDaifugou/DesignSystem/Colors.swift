import SwiftUI

extension Color {
    // Backgrounds / surfaces
    static let tycoonBlack = Color(ds: 0x000000)
    static let tycoonBg = Color(ds: 0x0E0E0E)
    static let tycoonSurface = Color(ds: 0x161616)
    static let tycoonSheet = Color(ds: 0x141414)
    static let tycoonCard = Color(ds: 0x1D1D1D)
    static let tycoonBorder = Color(ds: 0x2A2A2A)

    // Pastel accents
    static let cardCream = Color(ds: 0xFFF4E6)
    static let cardBlush = Color(ds: 0xFFD4E5)
    static let cardLavender = Color(ds: 0xE5D4FF)
    static let cardMint = Color(ds: 0xD4FFE5)

    // Classic playing-card rank/suit colors — used on light card faces
    static let cardSuitRed = Color(ds: 0xEB3D42)
    static let cardSuitBlack = Color(ds: 0x1A1A1A)

    // Canonical aliases — map new names onto existing tokens with matching values
    static let tycoonPink = cardBlush
    static let tycoonLav = cardLavender
    static let tycoonCream = cardCream

    // Text
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
