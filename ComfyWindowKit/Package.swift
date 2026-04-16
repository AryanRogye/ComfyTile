// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "ComfyWindowKit",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "ComfyWindowKit",
            targets: ["ComfyWindowKit"],
        ),
    ],
    targets: [
        .target(
            name: "ComfyWindowKit"
        ),
    ],
    swiftLanguageModes: [
        .v5,
    ]
)
