// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "MiddleClickScroll",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MiddleClickScroll", targets: ["MiddleClickScrollApp"])
    ],
    targets: [
        .executableTarget(
            name: "MiddleClickScrollApp",
            path: "Sources/MiddleClickScrollApp"
        )
    ]
)
