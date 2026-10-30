#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)

    import File_System_Foundation_Integration
    import Foundation
    import Paths_Foundation_Integration
    import Testing

    extension File.Ubiquitous.Test.Unit {
        private static func folder() throws -> URL {
            let url = FileManager.default.temporaryDirectory.appending(path: "file-ubiquitous-\(UUID().uuidString)", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            return url
        }

        @Test func `a coordinated move to a taken name takes the first free numbered name and replaces nothing`() throws {
            let folder = try Self.folder()
            // swift-linter:disable:next try optional
            // REASON: FileManager.removeItem throws untyped; a temporary folder left behind is no failure.
            defer { try? FileManager.default.removeItem(at: folder) }
            try Data("kept".utf8).write(to: folder.appending(path: "Report.pdf"))
            try Data("moved".utf8).write(to: folder.appending(path: "scan.pdf"))

            let placed = try File.Ubiquitous.move(
                from: try File.Path(folder.appending(path: "scan.pdf")),
                to: try File.Path(folder.appending(path: "Report.pdf"))
            )

            #expect(placed == (try File.Path(folder.appending(path: "Report 2.pdf"))))
            #expect(try Data(contentsOf: folder.appending(path: "Report.pdf")) == Data("kept".utf8))
            #expect(try Data(contentsOf: folder.appending(path: "Report 2.pdf")) == Data("moved".utf8))
            #expect(!FileManager.default.fileExists(atPath: folder.appending(path: "scan.pdf").path(percentEncoded: false)))
        }

        @Test func `a file outside iCloud has no conflict, and settling it writes nothing`() throws {
            let folder = try Self.folder()
            // swift-linter:disable:next try optional
            // REASON: FileManager.removeItem throws untyped; a temporary folder left behind is no failure.
            defer { try? FileManager.default.removeItem(at: folder) }
            try Data("text".utf8).write(to: folder.appending(path: "Report.pdf"))
            let file = try File.Path(folder.appending(path: "Report.pdf"))

            #expect(!File.Ubiquitous.conflicted(file))
            #expect(File.Ubiquitous.settle(file).isEmpty)
            #expect(try FileManager.default.contentsOfDirectory(atPath: folder.path(percentEncoded: false)) == ["Report.pdf"])
        }
    }

#endif

#if os(macOS)

    import File_System_Foundation_Integration
    import Foundation
    import Testing

    extension File.Ubiquitous.Test.Unit {
        @Test func `a container that is not the app's is not given`() {
            #expect(File.Ubiquitous.container("iCloud.com.example.not-this-app") == nil)
        }
    }

#endif
