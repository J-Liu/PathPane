// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PathPane",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "PathPane",
            path: "Sources/PathPane",
            linkerSettings: [
                .unsafeFlags(["-framework", "QuickLookThumbnailing"], .when(platforms: [.macOS]))
            ]
        )
    ]
)