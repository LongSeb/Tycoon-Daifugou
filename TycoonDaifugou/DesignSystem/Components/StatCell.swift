import SwiftUI

struct StatCell: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.statFigure)
                .foregroundStyle(Color.textPrimary)
                .tracking(-0.3)

            Text(label.uppercased())
                .font(.tycoonCaption)
                .foregroundStyle(Color.textTertiary)
                .tracking(1.3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
    }
}

#Preview {
    HStack(spacing: 1) {
        StatCell(label: "Rounds", value: "2/3")
        StatCell(label: "Cards", value: "31")
        StatCell(label: "Time", value: "8m 42s")
    }
    .background(Color.white.opacity(0.06))
    .clipShape(RoundedRectangle(cornerRadius: 14))
    .padding()
    .background(Color.tycoonBlack)
}
