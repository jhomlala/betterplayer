// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "better_player",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "better-player", targets: ["better_player"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(url: "https://github.com/hyperoslo/Cache", from: "6.0.0"),
        .package(url: "https://github.com/yene/GCDWebServer", from: "3.5.7"),
        .package(url: "https://github.com/StyleShare/HLSCachingReverseProxyServer", from: "0.2.0"),
        .package(url: "https://github.com/pinterest/PINCache", from: "3.0.0")
    ],
    targets: [
        .target(
            name: "better_player",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "Cache", package: "Cache"),
                .product(name: "GCDWebServer", package: "GCDWebServer"),
                .product(name: "HLSCachingReverseProxyServer", package: "HLSCachingReverseProxyServer"),
                .product(name: "PINCache", package: "PINCache")
            ],
            path: "Sources/better_player",
            cSettings: [
                .headerSearchPath("include/better_player")
            ]
        )
    ]
)
