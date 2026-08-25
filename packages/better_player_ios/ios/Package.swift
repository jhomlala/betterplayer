// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "better_player_ios",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "better-player-ios", targets: ["better_player_ios"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(url: "https://github.com/hyperoslo/Cache", from: "6.0.0")
    ],
    targets: [
        .target(
            name: "better_player_ios",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "Cache", package: "Cache")
            ],
            path: "Sources",
            resources: [
                .process("better_player/PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
