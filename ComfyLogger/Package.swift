// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ComfyLogger",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ComfyLogger",
            targets: ["ComfyLogger"]
        ),
    ],
    targets: [
        .target(
            name: "ComfyLogger"
        ),
    ],
    swiftLanguageModes: [
        .v6
    ],
)
