#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)

    import File_System_Foundation_Integration
    import Foundation
    import Paths_Foundation_Integration
    import Testing

    extension File.Bookmark {
        @Suite struct Test {
            @Suite struct Unit {}
            @Suite struct `Edge Case` {}

            static func folder() throws -> File.Path {
                let url = FileManager.default.temporaryDirectory
                    .appending(path: "file-bookmark-\(UUID().uuidString)", directoryHint: .isDirectory)
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
                return try File.System.Canonical.resolve(try File.Path(url))
            }

            static func remove(_ path: File.Path) {
                // swift-linter:disable:next try optional
                // REASON: FileManager.removeItem throws untyped; a temporary folder left behind is no failure.
                try? FileManager.default.removeItem(at: URL(path))
            }
        }
    }

    extension File.Bookmark.Test.Unit {
        @Test func `a folder's bookmark resolves to the folder, not stale`() throws {
            let folder = try File.Bookmark.Test.folder()
            defer { File.Bookmark.Test.remove(folder) }

            let bookmark = try File.Bookmark(folder)
            #expect(bookmark.bytes.isEmpty == false)

            let resolution = try File.Bookmark(bytes: bookmark.bytes).resolve()
            #expect(try File.System.Canonical.resolve(resolution.path) == folder)
            #expect(resolution.stale == false)
        }

        @Test func `a resolved folder is bookmarked again, and its scope opens and closes under a key`() throws {
            let folder = try File.Bookmark.Test.folder()
            defer { File.Bookmark.Test.remove(folder) }

            let resolution = try File.Bookmark(folder).resolve()
            let renewed = try File.Bookmark(resolution)
            #expect(try File.System.Canonical.resolve(renewed.resolve().path) == folder)

            let scopes = File.Bookmark.Scopes()
            scopes.open(resolution, as: "folder")
            scopes.open(folder, as: "folder")
            scopes.close("folder")
            scopes.close("never opened")
        }
    }

    extension File.Bookmark.Test.`Edge Case` {
        @Test func `bytes that are no bookmark do not resolve`() {
            #expect(throws: File.Bookmark.Error.unresolved) {
                try File.Bookmark(bytes: "not a bookmark").resolve()
            }
        }

        @Test func `a missing folder cannot be bookmarked`() {
            let missing = File.Path("/nonexistent-\(UUID().uuidString)/folder")
            #expect(throws: File.Bookmark.Error.denied) {
                try File.Bookmark(missing)
            }
        }
    }

#endif
