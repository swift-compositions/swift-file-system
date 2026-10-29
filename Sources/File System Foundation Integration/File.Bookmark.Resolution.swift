#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)

    import Foundation

    extension File.Bookmark {

        /// A resolved bookmark: the item's path, whether the bookmark is stale, and the item's security scope,
        /// which ``File/Bookmark/Scopes`` opens and a fresh ``File/Bookmark`` is made through.
        public struct Resolution: Sendable {

            /// Where the item is now.
            public let path: File.Path

            /// Whether the bookmark should be made again and kept in place of the old one.
            public let stale: Bool

            /// The resolved URL, which carries the item's security scope; a URL made from ``path`` does not.
            let url: URL
        }
    }

#endif
