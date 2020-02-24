// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ThirdPartyJWTAuthentication",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "ThirdPartyJWTAuthentication",
            targets: ["ThirdPartyJWTAuthentication"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0-beta"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0-beta"),
        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0-beta")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "ThirdPartyJWTAuthentication",
            dependencies: ["Vapor", "Fluent", "JWT"]),
        .testTarget(
            name: "ThirdPartyJWTAuthenticationTests",
            dependencies: ["ThirdPartyJWTAuthentication"]),
    ]
)
