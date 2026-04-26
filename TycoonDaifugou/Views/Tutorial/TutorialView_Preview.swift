import SwiftUI

#Preview("Full Tutorial") {
    TutorialView()
}

#Preview("Slide 2 — Card Strength") {
    TutorialSlideView(step: .cardStrength)
        .background(Color.tycoonBlack)
}

#Preview("Slide 6 — Card Exchange") {
    TutorialSlideView(step: .cardExchange)
        .background(Color.tycoonBlack)
}

#Preview("Slide 7 — Revolution") {
    TutorialSlideView(step: .revolution)
        .background(Color.tycoonBlack)
}
