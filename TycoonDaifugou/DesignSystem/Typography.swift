import SwiftUI

extension Font {
    static let displayXL = Font.custom("Fraunces-9ptBlackItalic", size: 96, relativeTo: .largeTitle)
    static let displayL = Font.custom("Fraunces-9ptBlackItalic", size: 64, relativeTo: .title)
    static let displayWins = Font.custom("Fraunces-9ptBlackItalic", size: 104, relativeTo: .largeTitle)
    static let brandTitle = Font.custom("Fraunces-9ptBlackItalic", size: 19, relativeTo: .headline)
    static let cardTitle = Font.custom("Fraunces-9ptBlackItalic", size: 22, relativeTo: .title2)
    static let statFigure = Font.custom("Fraunces-9ptBlackItalic", size: 17, relativeTo: .headline)
    static let tycoonTitle = Font.custom("InstrumentSans-Regular", size: 24, relativeTo: .title3).weight(.semibold)
    static let tycoonBody = Font.custom("InstrumentSans-Regular", size: 16, relativeTo: .body)
    static let tycoonCaption = Font.custom("InstrumentSans-Regular", size: 11, relativeTo: .caption).weight(.medium)
    static let bodyMono = Font.system(size: 13, design: .monospaced)
}

#Preview {
    VStack(alignment: .leading, spacing: 20) {
        Text("96")
            .font(.displayXL)
            .foregroundStyle(Color.cardCream)
        Text("Display L")
            .font(.displayL)
            .foregroundStyle(Color.cardLavender)
        Text("Title — Semibold")
            .font(.tycoonTitle)
            .foregroundStyle(Color.textPrimary)
        Text("Body — Regular")
            .font(.tycoonBody)
            .foregroundStyle(Color.textSecondary)
        Text("CAPTION — MEDIUM")
            .font(.tycoonCaption)
            .textCase(.uppercase)
            .foregroundStyle(Color.textTertiary)
        Text("0x1A3F monospaced")
            .font(.bodyMono)
            .foregroundStyle(Color.cardMint)
    }
    .padding(32)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.tycoonBlack)
}
