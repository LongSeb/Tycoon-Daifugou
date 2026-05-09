import SwiftUI

enum UnlockRegistry {
    static let all: [UnlockDefinition] = [
        .init(level: 1,  type: .title("Commoner"),         displayName: "Title: Commoner"),
        .init(level: 2,  type: .title("The Joker"),        displayName: "Title: The Joker"),
        .init(level: 3,  type: .cardSkin(.init(
            id: "royal_red", name: "Royal Red",
            color: Color(hex: "#AC2317"), isFoil: true, isDark: true,
            jokerImageName: "RoyalRedCrown",
            jokerImagePadding: 12,
            numberFontName: "FranklinGothicITALIC",
            overlayImageName: "RoyalRedSparkles",
            jokerImageUseTemplate: true,
            cornerPaddingOverride: 7,
            cornerLabelSpacing: 0)),                                        displayName: "Card Skin: Royal Red"),
        .init(level: 4,  type: .title("Flower Queen"),     displayName: "Title: Flower Queen"),
        .init(level: 5,  type: .featureGate("extendedStats"), displayName: "Extended Stats Unlocked"),
        .init(level: 5,  type: .title("Card Shark"),       displayName: "Title: Card Shark"),
        .init(level: 6,  type: .cardSkin(.init(
            id: "luck_of_the_irish", name: "Luck of The Irish",
            color: Color(hex: "#039442"), isFoil: false,
            jokerImageName: "PotOfGold",
            jokerImagePadding: 8,
            numberFontName: "URWAgendaW01-Light",
            selectionColor: Color(hex: "#09CF6D"),
            inkColorOverride: Color(hex: "#F7D21E"),
            showTextShadow: true,
            strongTextShadow: true)),                       displayName: "Card Skin: Luck of The Irish"),
        .init(level: 7,  type: .profileBorder(.init(
            id: "bronze", name: "Bronze",
            color: Color(hex: "#CD7F32"), isAnimated: false)), displayName: "Border: Bronze"),
        .init(level: 8,  type: .cardSkin(.init(
            id: "monkey_business", name: "Monkey Business",
            color: Color(hex: "#f9fad9"), isFoil: true,
            jokerImageName: "Banana2",
            jokerImagePadding: 12,
            numberFontName: "ScriptMTBold",
            selectionColor: Color(hex: "#fff9a3"),
            overlayImageName: "VinesOverlay",
            inkColorOverride: Color(hex: "#7f4f24"),
            showBorder: false,
            showTextShadow: true,
            foilColor: Color(hex: "#fff0b9"))),             displayName: "Card Skin: Monkey Business"),
        .init(level: 9,  type: .profileBorder(.init(
            id: "royal_red_border", name: "Royal Red",
            color: Color(hex: "#AC2317"), isAnimated: false)), displayName: "Border: Royal Red"),
        .init(level: 10, type: .title("All The Primes"),   displayName: "Title: All The Primes"),
        .init(level: 11, type: .title("Lady Amagi"),       displayName: "Title: Lady Amagi"),
        .init(level: 12, type: .cardSkin(.init(
            id: "pretty_pink", name: "Cherry Blossom",
            color: Color(hex: "#f0e4e6"), isFoil: false,
            numberFontName: "KeinannPOP",
            selectionColor: Color(hex: "#fff0f3"),
            overlayImageName: "CherryBlossomOverlay",
            inkColorOverride: .white,
            showTextShadow: true,
            showKanjiCorners: true,
            textShadowOpacity: 0.5,
            showFallingPetals: true)),  displayName: "Card Skin: Cherry Blossom"),
        .init(level: 13, type: .profileBorder(.init(
            id: "silver", name: "Silver",
            color: Color(hex: "#C0C0C0"), isAnimated: false)), displayName: "Border: Silver"),
        .init(level: 14, type: .cardSkin(.init(
            id: "repeat_blue", name: "Repeat Blue",
            color: Color(hex: "#99DAFF"), isFoil: false)),  displayName: "Card Skin: Repeat Blue"),
        .init(level: 15, type: .title("Kissing Kings"),    displayName: "Title: Kissing Kings"),
        .init(level: 16, type: .title("Truth Seeker"),     displayName: "Title: Truth Seeker"),
        .init(level: 17, type: .profileBorder(.init(
            id: "purple", name: "Purple",
            color: Color(hex: "#766ED9"), isAnimated: false)), displayName: "Border: Purple"),
        .init(level: 18, type: .title("Kingpin of Steel"), displayName: "Title: Kingpin of Steel"),
        .init(level: 19, type: .cardSkin(.init(
            id: "orange", name: "Orange",
            color: Color(hex: "#FFDCA9"), isFoil: false)),  displayName: "Card Skin: Orange"),
        .init(level: 20, type: .featureGate("expertDifficulty"), displayName: "Expert Difficulty Unlocked"),
        .init(level: 21, type: .title("The High Roller"),  displayName: "Title: The High Roller"),
        .init(level: 22, type: .profileBorder(.init(
            id: "gold_foil", name: "Gold Foil",
            color: Color(hex: "#C9A84C"), isAnimated: true)), displayName: "Border: Gold Foil"),
        .init(level: 23, type: .title("Chad"),             displayName: "Title: Chad"),
        .init(level: 24, type: .cardSkin(.init(
            id: "plum_purple", name: "Plum Purple",
            color: Color(hex: "#545B77"), isFoil: false, isDark: true)),  displayName: "Card Skin: Plum Purple"),
        .init(level: 25, type: .title("Tycoon"),           displayName: "Title: Tycoon"),
        .init(level: 28, type: .cardSkin(.init(
            id: "subway", name: "Subway",
            color: Color(hex: "#DEDEDE"), isFoil: false,
            jokerImageName: "SubwayJoker",
            jokerImagePadding: 8,
            numberFontName: "Helvetica-Bold",
            inkColorOverride: Color(hex: "#1A1A1A"),
            showBorder: true,
            showTextShadow: true,
            strongTextShadow: true,
            textShadowColor: .white,
            customAnimation: .subway)),                     displayName: "Card Skin: Subway"),
        .init(level: 50, type: .prestigeBadge,             displayName: "Prestige Badge"),
        .init(level: 50, type: .cardSkin(.init(
            id: "shiny_black", name: "Shiny Black",
            color: Color(hex: "#171616"), isFoil: true, isDark: true)),   displayName: "Card Skin: Shiny Black"),
    ]

    static func unlocks(upToLevel level: Int) -> [UnlockDefinition] {
        all.filter { $0.level <= level }
    }

    static func unlocks(forLevel level: Int) -> [UnlockDefinition] {
        all.filter { $0.level == level }
    }
}
