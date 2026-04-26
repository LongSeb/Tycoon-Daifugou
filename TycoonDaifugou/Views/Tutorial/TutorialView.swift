import SwiftUI
import UIKit

// TutorialStep drives TutorialSlideView (title, body copy, house-rule badge).
// CaseIterable and Identifiable removed — navigation uses Int currentIndex.
enum TutorialStep: Int {
    case welcome = 0
    case cardStrength
    case howATurnWorks
    case tricks
    case ranksAndScoring
    case cardExchange
    case revolution
    case specialCards
    case strategyTip
    case youreReady

    var isHouseRule: Bool { self == .revolution || self == .specialCards }
}

struct TutorialView: View {
    var isReplay: Bool = false

    @AppStorage(TutorialState.storageKey) private var hasCompleted: Bool = false
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int = 0

    private let totalSteps = 10
    private var isLastSlide: Bool { currentIndex == totalSteps - 1 }

    var body: some View {
        ZStack {
            Color.tycoonBlack.ignoresSafeArea()
            pageView
            overlayControls
        }
        .preferredColorScheme(.dark)
        .onAppear {
            UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(Color.tycoonMint)
            UIPageControl.appearance().pageIndicatorTintColor = UIColor(Color.tycoonMint.opacity(0.3))
        }
    }

    // MARK: - Page view

    private var pageView: some View {
        TabView(selection: $currentIndex) {
            slidesFirst
            slidesSecond
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }

    @ViewBuilder
    private var slidesFirst: some View {
        TutorialSlideView(step: .welcome).tag(0)
        TutorialSlideView(step: .cardStrength).tag(1)
        TutorialSlideView(step: .howATurnWorks).tag(2)
        TutorialSlideView(step: .tricks).tag(3)
        TutorialSlideView(step: .ranksAndScoring).tag(4)
    }

    @ViewBuilder
    private var slidesSecond: some View {
        TutorialSlideView(step: .cardExchange).tag(5)
        TutorialSlideView(step: .revolution).tag(6)
        TutorialSlideView(step: .specialCards).tag(7)
        TutorialSlideView(step: .strategyTip).tag(8)
        TutorialSlideView(step: .youreReady, onComplete: complete).tag(9)
    }

    // MARK: - Overlays

    @ViewBuilder
    private var overlayControls: some View {
        if !isLastSlide {
            skipButton
            nextButton
        }
    }

    private var skipButton: some View {
        VStack {
            HStack {
                Spacer()
                Button("Skip") { complete() }
                    .font(.tycoonBody)
                    .foregroundStyle(Color.textSecondary)
                    .padding(.trailing, 24)
                    .padding(.top, 60)
            }
            Spacer()
        }
    }

    private var nextButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: advance) {
                    Text("Next →")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.tycoonBlack)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 12)
                        .background(Color.tycoonMint)
                        .clipShape(Capsule())
                }
                .padding(.trailing, 24)
                .padding(.bottom, 80)
            }
        }
    }

    // MARK: - Actions

    private func advance() {
        guard currentIndex < totalSteps - 1 else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            currentIndex += 1
        }
    }

    private func complete() {
        if !isReplay { hasCompleted = true }
        dismiss()
    }
}
