// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "embrace_ios",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "embrace-ios", targets: ["embrace_ios"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(url: "https://github.com/embrace-io/embrace-apple-sdk", .exact("6.21.0")),
        .package(url: "https://github.com/open-telemetry/opentelemetry-swift-core", from: "2.1.1")
    ],
    targets: [
        .target(
            name: "embrace_ios",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "EmbraceIO", package: "embrace-apple-sdk"),
                .product(name: "EmbraceSemantics", package: "embrace-apple-sdk"),
                .product(name: "OpenTelemetryApi", package: "opentelemetry-swift-core")
            ]
        )
    ]
)
