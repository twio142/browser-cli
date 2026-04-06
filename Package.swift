// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "browser-cli",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/apple/swift-testing.git", from: "6.0.0"),
    ],
    targets: [
        .target(
            name: "BrowserCore",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/BrowserCore",
            linkerSettings: [
                .linkedFramework("ScriptingBridge"),
                .linkedFramework("OSAKit"),
                .linkedFramework("ApplicationServices"),
            ]
        ),
        .executableTarget(
            name: "browser-cli",
            dependencies: ["BrowserCore"],
            path: "Sources/browser-cli",
            exclude: ["Info.plist"],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/browser-cli/Info.plist",
                ]),
            ]
        ),
        .testTarget(
            name: "browser-cliTests",
            dependencies: [
                "BrowserCore",
                .product(name: "Testing", package: "swift-testing"),
            ],
            path: "Tests/browser-cliTests"
        ),
    ]
)
