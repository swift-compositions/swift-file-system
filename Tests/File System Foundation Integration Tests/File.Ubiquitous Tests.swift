#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)

    import File_System_Foundation_Integration
    import Foundation
    import Paths_Foundation_Integration
    import Testing

    extension File.Ubiquitous {
        @Suite struct Test {
            @Suite struct Unit {}
        }
    }

    extension File.Ubiquitous.Test.Unit {
        @Test func `a plain file outside iCloud is local, and downloading it returns at once`() async throws {
            let url = FileManager.default.temporaryDirectory.appending(path: "file-ubiquitous-\(UUID().uuidString).txt")
            try Data("text".utf8).write(to: url)
            // swift-linter:disable:next try optional
            // REASON: FileManager.removeItem throws untyped; a temporary file left behind is no failure.
            defer { try? FileManager.default.removeItem(at: url) }
            let file = try File.Path(url)

            #expect(File.Ubiquitous.local(file))
            try await File.Ubiquitous.download(file, limit: .zero)
        }
    }

#endif
