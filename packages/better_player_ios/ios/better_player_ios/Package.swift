// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "better_player_ios",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "better-player-ios", targets: ["better_player_ios", "better_player_ios_objc"])
    ],
    dependencies: [
        .package(url: "https://github.com/hyperoslo/Cache", from: "6.0.0")
    ],
    targets: [
        .target(
            name: "better_player_ios",
            dependencies: [
                .product(name: "Cache", package: "Cache")
            ],
            path: "Sources/better_player_ios",
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        ),
        .target(
            name: "better_player_ios_objc",
            dependencies: ["better_player_ios"],
            path: "Sources/better_player_ios_objc"
        )
    ]
)
