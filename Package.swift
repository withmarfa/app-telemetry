// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "WithMarfaTelemetry",
    platforms: [.iOS(.v27), .macOS(.v27)],
    products: [
        .library(name: "WithMarfaTelemetry", targets: ["WithMarfaTelemetry"])
    ],
    dependencies: [
        .package(url: "https://github.com/withmarfa/marfa-swift", from: "0.0.67")
    ],
    targets: [
        .target(
            name: "WithMarfaTelemetry",
            dependencies: [.product(name: "Marfa", package: "marfa-swift")],
            resources: [.process("PrivacyInfo.xcprivacy")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "WithMarfaTelemetryTests",
            dependencies: [
                "WithMarfaTelemetry",
                .product(name: "Marfa", package: "marfa-swift"),
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
