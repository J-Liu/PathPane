// swift-tools-version: 6.0
//
// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright © 2026 Jia Liu

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
