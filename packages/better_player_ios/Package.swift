// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "better_player_ios",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "better_player_ios", targets: ["better_player_ios"])
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
            path: "ios/Sources",
            resources: [
                .process("better_player/PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
