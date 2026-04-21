import SwiftUI

struct ProfileStatCell: View {
    let value: String
    let label: String
    let sub: String
    var valueColor: Color = .textPrimary

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .font(.profileStatFigure)
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.bottom, 3)

            Text(label.uppercased())
                .font(.sectionLabel)
                .foregroundStyle(Color.white.opacity(0.28))
                .tracking(0.5)

            Text(sub)
                .font(.ruleCaption)
                .foregroundStyle(Color.white.opacity(0.18))
                .padding(.top, 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.tycoonSurface)
    }
}
