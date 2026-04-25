import AVFoundation

final class SoundManager {
    static let shared = SoundManager()

    private var cardPlayPlayer: AVAudioPlayer?
    private var revolutionPlayer: AVAudioPlayer?
    private var roundEndPlayer: AVAudioPlayer?

    private var isEnabled: Bool {
        UserDefaults.standard.object(forKey: AppSettings.Key.soundEffectsEnabled) as? Bool ?? true
    }

    private init() {
        cardPlayPlayer = makePlayer(resource: "card_play")
        revolutionPlayer = makePlayer(resource: "revolution")
        roundEndPlayer = makePlayer(resource: "round_end")
    }

    private func makePlayer(resource: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "caf") else {
            return nil
        }
        let player = try? AVAudioPlayer(contentsOf: url)
        player?.prepareToPlay()
        return player
    }

    func playCardPlay() {
        guard isEnabled else { return }
        cardPlayPlayer?.currentTime = 0
        cardPlayPlayer?.play()
    }

    func playRevolution() {
        guard isEnabled else { return }
        revolutionPlayer?.currentTime = 0
        revolutionPlayer?.play()
    }

    func playRoundEnd() {
        guard isEnabled else { return }
        roundEndPlayer?.currentTime = 0
        roundEndPlayer?.play()
    }
}
