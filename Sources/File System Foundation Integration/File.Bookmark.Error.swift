#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)

    extension File.Bookmark {

        /// Why a bookmark could not be made or resolved.
        public enum Error: Swift.Error, Equatable, Sendable {

            /// The item cannot be bookmarked: it is missing, or the app has no access to it.
            case denied

            /// The bookmark's bytes no longer name an item.
            case unresolved

            /// The item resolved to a location that is no valid path.
            case path(File.Path.Error)
        }
    }

#endif
