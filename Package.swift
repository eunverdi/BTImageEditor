// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BTImageEditor",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "BTImageEditor",
            targets: ["BTImageEditor"])
    ],
    dependencies: [
        .package(url: "https://github.com/htmlprogrammist/EmojiPicker", .upToNextMajor(from: "3.0.0"))
    ],
    targets: [
        .target(
            name: "BTImageEditor",
            dependencies: [
                .product(name: "EmojiPicker", package: "EmojiPicker")
            ], 
            path: "Sources"
        )
    ]
)

