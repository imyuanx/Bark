// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "BarkMacCore",
    products: [
        .library(name: "BarkMacCore", targets: ["BarkMacCore"])
    ],
    targets: [
        .target(name: "BarkMacCore", path: "Sources/BarkMacCore"),
        .testTarget(name: "BarkMacCoreTests", dependencies: ["BarkMacCore"], path: "Tests/BarkMacCoreTests")
    ]
)
