#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)

    extension File.Directory.Watch {

        public struct Options: Sendable {

            /// Whether directories whose names start with a dot are watched.
            public var includeHidden: Bool

            /// The most directories watched at once, each holding one descriptor.
            public var limit: Int

            /// Whether a subdirectory is watched, and its subtree with it.
            public var descend: @Sendable (File.Directory.Entry) -> Bool

            public init(
                includeHidden: Bool = false,
                limit: Int = 1024,
                descend: @escaping @Sendable (File.Directory.Entry) -> Bool = { _ in true }
            ) {
                self.includeHidden = includeHidden
                self.limit = limit
                self.descend = descend
            }
        }
    }

#endif
