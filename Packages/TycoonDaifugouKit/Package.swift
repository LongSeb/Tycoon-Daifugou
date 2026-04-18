// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TycoonDaifugouKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "TycoonDaifugouKit",
            targets: ["TycoonDaifugouKit"]
        ),
    ],
    dependencies: [
        // SwiftLint as a build-tool plugin. Runs on every build.
        // Pin minor version — avoid silent major upgrades.
        //.package(url: "https://github.com/realm/SwiftLint.git", from: "0.54.0"),
    ],
    targets: [
        .target(
            name: "TycoonDaifugouKit",
            dependencies: [],
            plugins: [
                //.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint"),
            ]
        ),
        .testTarget(
            name: "TycoonDaifugouKitTests",
            dependencies: ["TycoonDaifugouKit"]
            // Swift Testing is built into the Swift 5.10+ toolchain —
            // no separate package dependency needed. Just `import Testing`.
        ),
    ]
)
