// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "better_player_macos",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "better-player-macos", targets: ["better_player_macos", "better_player_macos_objc"])
    ],
    dependencies: [
        .package(url: "https://github.com/hyperoslo/Cache", from: "6.0.0")
    ],
    targets: [
        .target(
            name: "better_player_macos",
            dependencies: [
                .product(name: "Cache", package: "Cache")
            ],
            path: "Sources/better_player_macos",
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        ),
        .target(
            name: "better_player_macos_objc",
            dependencies: ["better_player_macos"],
            path: "Sources/better_player_macos_objc",
            publicHeadersPath: ""
        )
    ]
)
