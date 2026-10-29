#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)

    import Foundation
    import Paths_Foundation_Integration
    import Synchronization

    extension File.Bookmark {

        /// The security scopes an app holds open, each under a key, until it gives the item up.
        ///
        /// Opening a key again closes the scope it held before; every scope still open closes with the holder.
        public final class Scopes: Sendable {

            private let open = Mutex<[Swift.String: URL]>([:])

            public init() {}

            deinit {
                for url in open.withLock({ $0.values }) { url.stopAccessingSecurityScopedResource() }
            }
        }
    }

    extension File.Bookmark.Scopes {

        /// Opens a resolved bookmark's security scope and holds it under `key`.
        public func open(_ resolution: File.Bookmark.Resolution, as key: Swift.String) {
            hold(resolution.url, as: key)
        }

        /// Opens the security scope of the item at `path`, if the app was granted one for it in this run, and
        /// holds it under `key`.
        public func open(_ path: File.Path, as key: Swift.String) {
            hold(URL(path), as: key)
        }

        /// Closes the scope held under `key`, if any.
        public func close(_ key: Swift.String) {
            open.withLock { $0.removeValue(forKey: key) }?.stopAccessingSecurityScopedResource()
        }

        private func hold(_ url: URL, as key: Swift.String) {
            guard url.startAccessingSecurityScopedResource() else { return }
            let previous = open.withLock { $0.updateValue(url, forKey: key) }
            previous?.stopAccessingSecurityScopedResource()
        }
    }

#endif
