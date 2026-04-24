import TycoonDaifugouKit

enum RoundPointValue {
    static let millionaire = 30
    static let rich = 20
    static let poor = 10
    static let beggar = 0
}

func roundPoints(for title: Title) -> Int {
    switch title {
    case .millionaire: return RoundPointValue.millionaire
    case .rich:        return RoundPointValue.rich
    case .commoner:    return RoundPointValue.poor
    case .poor:        return RoundPointValue.poor
    case .beggar:      return RoundPointValue.beggar
    }
}
