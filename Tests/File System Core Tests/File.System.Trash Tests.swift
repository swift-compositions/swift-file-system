#if os(Linux)
    import File_System_Test_Support
    import ISO_9945_Kernel_Time
    import Kernel
    import Testing
    import Time

    #if canImport(Glibc)
        import Glibc
    #elseif canImport(Musl)
        import Musl
    #endif

    @testable import File_System_Core

    extension File.System.Trash {
        @Suite(.serialized)
        struct Test {
            @Suite(.serialized) struct Unit {}
        }
    }

    extension File.System.Trash.Test.Unit {

        private static func text(at path: File.Path) throws -> Swift.String {
            let bytes = try File.System.Read.Full.read(from: path) { $0.withUnsafeBytes { unsafe $0.map { $0 } } }
            return Swift.String(decoding: bytes, as: UTF8.self)
        }

        @Test
        func `The record percent-encodes the path, keeps its slashes, and dates it in the zone given`() throws {
            let path = try File.Path("/home/someone/Brief van de gemeente.pdf")
            let instant = Time.Instant(secondsSinceUnixEpoch: 1_798_675_200)
            #expect(File.System.Trash.date(instant, in: Time.Zone.Rule { _ in .utc }) == "2026-12-31T00:00:00")
            #expect(File.System.Trash.date(instant, in: Time.Zone.Rule { _ in .seconds(-3_600) }) == "2026-12-30T23:00:00")
            let record = Swift.String(decoding: File.System.Trash.record(path, at: instant).map(\.bitPattern), as: UTF8.self)
            #expect(record.hasPrefix("[Trash Info]\nPath=/home/someone/Brief%20van%20de%20gemeente.pdf\nDeletionDate="))
        }

        @Test
        func `A file moves into the XDG home trash with its record, and a second of its name is numbered`() throws {
            try File.Directory.temporary { dir in
                let previous = unsafe getenv("XDG_DATA_HOME").map { unsafe Swift.String(cString: $0) }
                unsafe setenv("XDG_DATA_HOME", (dir.path / "data").string, 1)
                defer { if let previous { unsafe setenv("XDG_DATA_HOME", previous, 1) } else { unsafe unsetenv("XDG_DATA_HOME") } }

                let trash = dir.path / "data" / "Trash"
                for text in ["first", "second"] {
                    let bytes = Swift.Array(text.utf8).map(Byte.init(bitPattern:))
                    try File.System.Write.Atomic.write(bytes.span, to: dir.path / "Report.txt")
                    _ = try File.System.Trash.move(dir.path / "Report.txt")
                }
                #expect(!File.System.Stat.exists(at: dir.path / "Report.txt"))
                #expect(try Self.text(at: trash / "files" / "Report.txt") == "first")
                #expect(try Self.text(at: trash / "files" / "Report 2.txt") == "second")
                #expect(try Self.text(at: trash / "info" / "Report 2.txt.trashinfo").contains("Path=\((dir.path / "Report.txt").string)\n"))
            }
        }

        @Test
        func `Trashing a missing file fails as missing`() throws {
            try File.Directory.temporary { dir in
                #expect(throws: File.System.Trash.Error.missing) {
                    try File.System.Trash.move(dir.path / "missing.txt")
                }
            }
        }
    }
#endif
