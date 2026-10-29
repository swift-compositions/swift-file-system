#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)

    import Foundation
    import Paths_Foundation_Integration

    extension File {

        /// A security-scoped bookmark: the bytes that let a sandboxed app reach a file or folder the person
        /// chose again after a relaunch.
        ///
        /// Make one for a path the app can reach now, keep its ``bytes``, and ``resolve()`` them later. A
        /// resolution that comes back stale still reaches the item; make a fresh bookmark from the
        /// resolution and keep that instead.
        public struct Bookmark: Hashable, Sendable {

            /// The bookmark's opaque bytes, as they are kept.
            public let bytes: [Byte]

            /// A bookmark from bytes kept earlier.
            public init(bytes: [Byte]) {
                self.bytes = bytes
            }
        }
    }

    extension File.Bookmark {

        /// Makes a bookmark of the item at `path`.
        ///
        /// - Throws: ``File/Bookmark/Error/denied`` when the item cannot be bookmarked.
        public init(_ path: File.Path) throws(File.Bookmark.Error) {
            try self.init(URL(path))
        }

        /// Makes a fresh bookmark of a resolved item, through the resolution's own security scope, to keep in
        /// place of a stale one.
        ///
        /// - Throws: ``File/Bookmark/Error/denied`` when the item cannot be bookmarked.
        public init(_ resolution: File.Bookmark.Resolution) throws(File.Bookmark.Error) {
            try self.init(resolution.url)
        }

        /// Resolves the bookmark to the item it names and tells whether it is stale.
        ///
        /// - Throws: ``File/Bookmark/Error/unresolved`` when the bytes no longer name an item, and
        ///   ``File/Bookmark/Error/path(_:)`` when the item's location is no valid path.
        public func resolve() throws(File.Bookmark.Error) -> File.Bookmark.Resolution {
            var stale = false
            // swift-linter:disable:next try optional
            // REASON: URL(resolvingBookmarkData:) throws untyped; bytes that do not resolve are an unresolved bookmark.
            guard
                let url = try? URL(
                    resolvingBookmarkData: Data(bytes.map(UInt8.init(bitPattern:))),
                    options: Self.resolution,
                    relativeTo: nil,
                    bookmarkDataIsStale: &stale
                )
            else { throw .unresolved }
            let path: File.Path
            do throws(File.Path.Error) {
                path = try File.Path(url)
            } catch {
                throw .path(error)
            }
            return File.Bookmark.Resolution(path: path, stale: stale, url: url)
        }
    }

    extension File.Bookmark {

        fileprivate init(_ url: URL) throws(File.Bookmark.Error) {
            // swift-linter:disable:next try optional
            // REASON: URL.bookmarkData throws untyped; an item that cannot be bookmarked is denied.
            guard let data = try? url.bookmarkData(options: Self.creation, includingResourceValuesForKeys: nil, relativeTo: nil)
            else { throw .denied }
            self.init(bytes: data.map(Byte.init(bitPattern:)))
        }

        #if os(macOS) || targetEnvironment(macCatalyst)
            fileprivate static let creation: URL.BookmarkCreationOptions = .withSecurityScope
            fileprivate static let resolution: URL.BookmarkResolutionOptions = .withSecurityScope
        #else
            // On iOS, tvOS, watchOS and visionOS a bookmark of a security-scoped URL carries its scope implicitly.
            fileprivate static let creation: URL.BookmarkCreationOptions = []
            fileprivate static let resolution: URL.BookmarkResolutionOptions = []
        #endif
    }

#endif
