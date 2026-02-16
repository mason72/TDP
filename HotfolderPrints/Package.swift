// swift-tools-version: 5.9
// This Package.swift is provided as an alternative to the Xcode project.
// Open HotfolderPrints.xcodeproj in Xcode for the best experience.

import PackageDescription

let package = Package(
    name: "HotfolderPrints",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "HotfolderPrints",
            path: "HotfolderPrints",
            exclude: ["Info.plist", "HotfolderPrints.entitlements", "Resources/Assets.xcassets"],
            sources: [
                "App",
                "Models",
                "Services",
                "Utilities",
                "Views"
            ]
        )
    ]
)
