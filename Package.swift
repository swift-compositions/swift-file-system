// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-file-system",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(name: "File System", targets: ["File System"]),
        .library(name: "File System Test Support", targets: ["File System Test Support"]),
        .library(name: "File System Foundation Integration", targets: ["File System Foundation Integration"]),
    ],
    traits: [
        .trait(name: "Watch", description: "Directory change notification"),
        .trait(name: "Threads", description: "Asynchronous overloads that run on the thread pool"),
        .trait(name: "Glob", description: "Directory matching by glob pattern", enabledTraits: ["Threads"]),
        .trait(name: "IO", description: "The file system's capabilities for the IO executor model"),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-compositions/swift-environment.git", branch: "main"),
        .package(url: "https://github.com/swift-compositions/swift-kernel.git", branch: "main"),
        .package(url: "https://github.com/swift-compositions/swift-paths.git", branch: "main"),
        .package(url: "https://github.com/swift-compositions/swift-strings.git", branch: "main"),
        .package(url: "https://github.com/swift-compositions/swift-io-kernel.git", branch: "main"),
        .package(url: "https://github.com/swift-compositions/swift-threads.git", branch: "main"),
        .package(url: "https://github.com/swift-compositions/swift-executors.git", branch: "main"),
        .package(
            url: "https://github.com/swift-atoms/swift-either.git",
            branch: "main"
        ),
        .package(url: "https://github.com/swift-atoms/swift-binary.git", branch: "main", traits: ["Serializer"]),
        .package(
            url: "https://github.com/swift-atoms/swift-glob.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-path.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-tagged.git",
            branch: "main"
        ),
        .package(url: "https://github.com/swift-ietf/swift-rfc-4648.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-span.git", branch: "main", traits: ["Byte"]),
        .package(url: "https://github.com/swift-atoms/swift-memory.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "File System Core",
            dependencies: [
                .product(name: "Environment", package: "swift-environment"),
                .product(name: "Kernel", package: "swift-kernel"),
                .product(name: "Path", package: "swift-path"),
                .product(name: "Paths", package: "swift-paths"),
                .product(name: "Strings", package: "swift-strings"),
                .product(name: "Either", package: "swift-either"),
                .product(name: "Binary", package: "swift-binary"),
                .product(name: "RFC 4648", package: "swift-rfc-4648"),
            ]
        ),
        .target(
            name: "File System",
            dependencies: [
                "File System Core",
                .product(name: "Kernel", package: "swift-kernel"),
                .product(name: "Either", package: "swift-either"),
                .product(name: "Executors", package: "swift-executors", condition: .when(traits: ["Watch", "IO"])),
                .product(name: "Thread Pool", package: "swift-threads", condition: .when(traits: ["Threads"])),
                .product(name: "Glob", package: "swift-glob", condition: .when(traits: ["Glob"])),
                .product(name: "IO Kernel", package: "swift-io-kernel", condition: .when(traits: ["IO"])),
                .product(name: "Thread Actor", package: "swift-threads", condition: .when(traits: ["IO"])),
                .product(name: "Span", package: "swift-span", condition: .when(traits: ["IO"])),
                .product(name: "Memory", package: "swift-memory", condition: .when(traits: ["IO"])),
            ]
        ),
        .target(
            name: "File System Test Support",
            dependencies: [
                "File System Core",
                "File System",
                .product(name: "Kernel", package: "swift-kernel"),
                .product(name: "Kernel Test Support", package: "swift-kernel"),
            ],
            path: "Tests/Support"
        ),
        .target(
            name: "File System Foundation Integration",
            dependencies: [
                "File System Core",
                .product(
                    name: "Paths Foundation Integration",
                    package: "swift-paths",
                    condition: .when(platforms: [.macOS, .iOS, .tvOS, .watchOS, .visionOS])
                ),
            ]
        ),
        .testTarget(
            name: "File System Foundation Integration Tests",
            dependencies: [
                "File System Foundation Integration",
                .product(
                    name: "Paths Foundation Integration",
                    package: "swift-paths",
                    condition: .when(platforms: [.macOS, .iOS, .tvOS, .watchOS, .visionOS])
                ),
            ]
        ),
        .testTarget(
            name: "File System Core Tests",
            dependencies: [
                "File System Core",
                "File System Test Support",
                .product(name: "Kernel", package: "swift-kernel"),
                .product(
                    name: "Tagged",
                    package: "swift-tagged"
                ),
            ]
        ),
        .testTarget(
            name: "File System Tests",
            dependencies: [
                "File System",
                "File System Test Support",
                .product(name: "Kernel", package: "swift-kernel"),
                .product(
                    name: "Tagged",
                    package: "swift-tagged"
                ),
                .product(name: "Span", package: "swift-span"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
