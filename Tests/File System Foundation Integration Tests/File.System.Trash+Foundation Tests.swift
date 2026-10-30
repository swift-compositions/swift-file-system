#if os(macOS)

    import File_System_Foundation_Integration
    import Foundation
    import Paths_Foundation_Integration
    import Testing

    extension File.System.Trash {
        @Suite struct Test {
            @Suite struct Unit {}
        }
    }

    extension File.System.Trash.Test.Unit {
        @Test func `a file moves to the trash with its bytes, and is no longer where it was`() throws {
            let url = FileManager.default.temporaryDirectory.appending(path: "file-trash-\(UUID().uuidString).txt")
            try Data("text".utf8).write(to: url)
            let file = try File.Path(url)

            let trashed = try File.System.Trash.move(file)
            // swift-linter:disable:next try optional
            // REASON: FileManager.removeItem throws untyped; a test file left in the trash is no failure.
            defer { try? FileManager.default.removeItem(at: URL(trashed)) }

            #expect(!FileManager.default.fileExists(atPath: url.path(percentEncoded: false)))
            #expect(try Data(contentsOf: URL(trashed)) == Data("text".utf8))
            #expect(trashed != file)
        }

        @Test func `trashing a missing file fails as missing`() throws {
            let url = FileManager.default.temporaryDirectory.appending(path: "file-trash-\(UUID().uuidString).txt")
            #expect(throws: File.System.Trash.Error.missing) {
                try File.System.Trash.move(try File.Path(url))
            }
        }
    }

#endif
