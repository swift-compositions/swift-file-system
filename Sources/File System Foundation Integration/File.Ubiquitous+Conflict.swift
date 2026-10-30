#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)

    import Foundation
    import Paths_Foundation_Integration

    extension File.Ubiquitous {

        /// Whether iCloud holds versions of the file at `path` that conflict with it: the file was changed on two
        /// devices before either change reached the other.
        public static func conflicted(_ path: File.Path) -> Bool {
            // swift-linter:disable:next try optional
            // REASON: URL.resourceValues throws untyped; a file whose values cannot be read has no conflict to settle.
            (try? URL(path).resourceValues(forKeys: [.ubiquitousItemHasUnresolvedConflictsKey]))?
                .ubiquitousItemHasUnresolvedConflicts == true
        }

        /// Keeps every version iCloud holds in conflict with the file at `path`, so no device's change is lost: a
        /// version with other bytes is written beside the file under the first free name, as
        /// ``File/System/Write/Atomic/free(_:to:options:createIntermediates:)`` gives (`Report 2.pdf`); one with the
        /// same bytes needs nothing. Each version kept is marked resolved, and once every one is, iCloud drops them.
        ///
        /// - Returns: The copies written beside the file.
        @discardableResult
        public static func settle(_ path: File.Path) -> [File.Path] {
            let url = URL(path)
            let versions = NSFileVersion.unresolvedConflictVersionsOfItem(at: url) ?? []
            // swift-linter:disable:next try optional
            // REASON: Data(contentsOf:) throws untyped; a file that cannot be read keeps every differing version.
            let current = try? Data(contentsOf: url)
            var copies: [File.Path] = []
            var kept = 0
            for version in versions {
                // swift-linter:disable:next try optional
                // REASON: Data(contentsOf:) throws untyped; a version that cannot be read stays unresolved.
                guard let bytes = try? Data(contentsOf: version.url) else { continue }
                if bytes != current {
                    let written = Swift.Array(bytes).map(Byte.init(bitPattern:))
                    do throws(File.System.Write.Atomic.Error) {
                        copies.append(try File.System.Write.Atomic.free(written.span, to: path))
                    } catch {
                        continue
                    }
                }
                version.isResolved = true
                kept += 1
            }
            if kept == versions.count {
                // swift-linter:disable:next try optional
                // REASON: NSFileVersion.removeOtherVersionsOfItem throws untyped; versions left are dropped on a later settle.
                try? NSFileVersion.removeOtherVersionsOfItem(at: url)
            }
            return copies
        }
    }

#endif
