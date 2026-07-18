// swift-tools-version: 6.3.3

import PackageDescription

let package = Package(
    name: "swift-http-redirect",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26)
    ],
    products: [
        .library(name: "HTTP Redirect", targets: ["HTTP Redirect"])
    ],
    dependencies: [
        .package(url: "https://github.com/swift-foundations/swift-server.git", branch: "main"),
        .package(url: "https://github.com/swift-ietf/swift-rfc-6797.git", branch: "main")
    ],
    targets: [
        .target(
            name: "HTTP Redirect",
            dependencies: [
                .product(name: "Server", package: "swift-server"),
                .product(name: "RFC 6797", package: "swift-rfc-6797")
            ]
        ),
        .testTarget(
            name: "HTTP Redirect Tests",
            dependencies: ["HTTP Redirect"]
        )
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    target.swiftSettings = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes")
    ]
}
