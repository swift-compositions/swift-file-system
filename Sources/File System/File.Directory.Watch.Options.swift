#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)

    extension File.Directory.Watch {

        public struct Options: Sendable {

            /// Whether directories whose names start with a dot are watched.
            public var includeHidden: Bool

            /// The most directories watched at once, each holding one descriptor.
            public var limit: Int

            /// How long to keep gathering changes after the first one before yielding, so a burst
            /// such as a copy of many files reports each directory once. Zero yields at once.
            public var latency: Swift.Duration

            /// Whether a subdirectory is watched, and its subtree with it.
            public var descend: @Sendable (File.Directory.Entry) -> Bool

            public init(
                includeHidden: Bool = false,
                limit: Int = 1024,
                latency: Swift.Duration = .zero,
                descend: @escaping @Sendable (File.Directory.Entry) -> Bool = { _ in true }
            ) {
                self.includeHidden = includeHidden
                self.limit = limit
                self.latency = latency
                self.descend = descend
            }
        }
    }

#endif
