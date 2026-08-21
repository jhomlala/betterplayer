// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "better_player",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "better-player", targets: ["better_player_objc"])
    ],
    dependencies: [
        .package(url: "https://github.com/hyperoslo/Cache", from: "6.0.0"),
        .package(url: "https://github.com/yene/GCDWebServer", from: "3.5.7"),
        .package(url: "https://github.com/StyleShare/HLSCachingReverseProxyServer", from: "0.2.0"),
        .package(url: "https://github.com/pinterest/PINCache", from: "3.0.0")
    ],
    targets: [
        .target(
            name: "better_player",
            dependencies: [
                .product(name: "Cache", package: "Cache")
            ],
            path: "better_player/Sources/better_player_swift"
        ),
        .target(
            name: "better_player_objc",
            dependencies: [
                "better_player",
                .product(name: "GCDWebServer", package: "GCDWebServer"),
                .product(name: "HLSCachingReverseProxyServer", package: "HLSCachingReverseProxyServer"),
                .product(name: "PINCache", package: "PINCache")
            ],
            path: "better_player/Sources/better_player",
            publicHeadersPath: "include"
        )
    ]
)
