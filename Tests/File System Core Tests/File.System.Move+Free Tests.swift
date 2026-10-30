import File_System_Test_Support
import Kernel
import Testing

@testable import File_System_Core

extension File.System.Move.Test.Unit {

    private static func write(_ text: Swift.String, to path: File.Path) throws {
        let bytes = text.utf8.map(Byte.init(bitPattern:))
        try File.System.Write.Atomic.write(bytes.span, to: path)
    }

    private static func text(at path: File.Path) throws -> Swift.String {
        let bytes = try File.System.Read.Full.read(from: path) {
            $0.withUnsafeBytes { unsafe $0.map { $0 } }
        }
        return Swift.String(decoding: bytes, as: UTF8.self)
    }

    @Test
    func `A name is numbered after its stem, as Finder numbers a copy`() throws {
        let name = try File.Path.Component("Report.pdf")
        #expect(name.numbered(1).string == "Report.pdf")
        #expect(name.numbered(2).string == "Report 2.pdf")
        #expect(name.numbered(12).string == "Report 12.pdf")
        #expect(try File.Path.Component("Report").numbered(3).string == "Report 3")
        #expect(try File.Path.Component("archive.tar.gz").numbered(2).string == "archive.tar 2.gz")
    }

    @Test
    func `A free move to a free name keeps that name`() throws {
        try File.Directory.temporary { dir in
            try Self.write("a", to: dir.path / "a.txt")
            let placed = try File.System.Move.free(from: dir.path / "a.txt", to: dir.path / "Report.txt")
            #expect(placed == dir.path / "Report.txt")
            #expect(try Self.text(at: placed) == "a")
            #expect(!File.System.Stat.exists(at: dir.path / "a.txt"))
        }
    }

    @Test
    func `A free move to a taken name takes the first free numbered name and replaces nothing`() throws {
        try File.Directory.temporary { dir in
            try Self.write("first", to: dir.path / "Report.txt")
            try Self.write("second", to: dir.path / "Report 2.txt")
            try Self.write("new", to: dir.path / "new.txt")
            let placed = try File.System.Move.free(from: dir.path / "new.txt", to: dir.path / "Report.txt")
            #expect(placed == dir.path / "Report 3.txt")
            #expect(try Self.text(at: dir.path / "Report.txt") == "first")
            #expect(try Self.text(at: dir.path / "Report 2.txt") == "second")
            #expect(try Self.text(at: placed) == "new")
        }
    }

    @Test
    func `A free move of a file that already has the name leaves it where it is`() throws {
        try File.Directory.temporary { dir in
            try Self.write("a", to: dir.path / "Report.txt")
            let placed = try File.System.Move.free(from: dir.path / "Report.txt", to: dir.path / "Report.txt")
            #expect(placed == dir.path / "Report.txt")
            #expect(try Self.text(at: placed) == "a")
        }
    }

    @Test
    func `A free move of a missing file fails as not found`() throws {
        try File.Directory.temporary { dir in
            #expect(throws: File.System.Move.Error.self) {
                try File.System.Move.free(from: dir.path / "missing.txt", to: dir.path / "Report.txt")
            }
        }
    }
}

extension File.System.Write.Atomic {
    @Suite
    struct `Free Test` {
        @Suite struct Unit {}
    }
}

extension File.System.Write.Atomic.`Free Test`.Unit {

    @Test
    func `A free write takes the first free numbered name and replaces nothing`() throws {
        try File.Directory.temporary { dir in
            let path = dir.path / "Report.txt"
            let (one, two, three) = (
                Swift.Array("first".utf8).map(Byte.init(bitPattern:)),
                Swift.Array("second".utf8).map(Byte.init(bitPattern:)),
                Swift.Array("third".utf8).map(Byte.init(bitPattern:))
            )
            let first = try File.System.Write.Atomic.free(one.span, to: path)
            let second = try File.System.Write.Atomic.free(two.span, to: path)
            let third = try File.System.Write.Atomic.free(three.span, to: path, options: .init(strategy: .replaceExisting))
            #expect(first == path)
            #expect(second == dir.path / "Report 2.txt")
            #expect(third == dir.path / "Report 3.txt")
            let bytes = try File.System.Read.Full.read(from: path) { $0.withUnsafeBytes { unsafe $0.map { $0 } } }
            #expect(Swift.String(decoding: bytes, as: UTF8.self) == "first")
        }
    }
}

extension File.System.Read.Full {
    @Suite
    struct `Bytes Test` {
        @Suite struct Unit {}
    }
}

extension File.System.Read.Full.`Bytes Test`.Unit {

    @Test
    func `The whole file reads as its bytes, and a missing one fails as not found`() throws {
        try File.Directory.temporary { dir in
            let bytes = Swift.Array("letter".utf8).map(Byte.init(bitPattern:))
            try File.System.Write.Atomic.write(bytes.span, to: dir.path / "a.txt")
            #expect(try File.System.Read.Full.bytes(at: dir.path / "a.txt") == bytes)
            #expect(throws: File.System.Read.Full.Error.self) { try File.System.Read.Full.bytes(at: dir.path / "missing.txt") }
        }
    }
}
