import SwiftUI

struct PillButton: View {
    let label: String
    let color: Color
    let action: () -> Void

    init(_ label: String, color: Color = .white, action: @escaping () -> Void) {
        self.label = label
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.tycoonTitle)
                .foregroundStyle(Color.tycoonBlack)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(color)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 16) {
        PillButton("Play Now") {}
        PillButton("Settings", color: .cardLavender) {}
        PillButton("Deal Cards", color: .cardBlush) {}
    }
    .padding()
    .background(Color.tycoonBlack)
}
