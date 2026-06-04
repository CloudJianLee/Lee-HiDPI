// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Lee-HiDPI",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "LeeHiDPICore",
            targets: ["LeeHiDPICore"]
        ),
        .executable(
            name: "lee-hidpi",
            targets: ["LeeHiDPIApp"]
        ),
    ],
    targets: [
        .target(
            name: "LeeHiDPICore",
            linkerSettings: [
                .linkedFramework("ApplicationServices"),
                .linkedFramework("IOKit")
            ]
        ),
        .executableTarget(
            name: "LeeHiDPIApp",
            dependencies: ["LeeHiDPICore"],
            linkerSettings: [
                .linkedFramework("AppKit")
            ]
        ),
        .testTarget(
            name: "LeeHiDPICoreTests",
            dependencies: ["LeeHiDPICore"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
