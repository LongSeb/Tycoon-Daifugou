import Foundation

enum UsernameValidator {

    /// Returns true if the username passes the content filter.
    static func isAppropriate(_ username: String) -> Bool {
        let normalized = normalize(username)
        return !blockedTerms.contains { normalized.contains($0) }
    }

    /// Strips separators and substitutes common leet-speak before checking,
    /// so variations like "f_u_c_k" or "sh1t" are still caught.
    private static func normalize(_ input: String) -> String {
        input
            .lowercased()
            .replacingOccurrences(of: "@", with: "a")
            .replacingOccurrences(of: "4", with: "a")
            .replacingOccurrences(of: "3", with: "e")
            .replacingOccurrences(of: "1", with: "i")
            .replacingOccurrences(of: "!", with: "i")
            .replacingOccurrences(of: "0", with: "o")
            .replacingOccurrences(of: "5", with: "s")
            .replacingOccurrences(of: "$", with: "s")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "-", with: "")
    }

    private static let blockedTerms: Set<String> = [
        // Profanity
        "fuck", "fvck", "shit", "shyt", "bitch", "btch",
        "cunt", "kunt", "whore", "slut",
        // Racial / ethnic slurs
        "nigger", "nigga", "chink", "spic", "wetback",
        "gook", "kike", "beaner", "zipperhead",
        // Homophobic / transphobic slurs
        "faggot", "faget", "dyke", "tranny",
        // Hate / extremism
        "nazi", "hitler", "kkk",
        // Sexual
        "dildo", "blowjob",
    ]
}
