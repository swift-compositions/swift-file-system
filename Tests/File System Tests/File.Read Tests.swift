import File_System
import File_System_Test_Support
import Kernel
import Testing

extension File.Read {
    @Suite
    struct Test {}
}

extension File.Read.Test {
    @Test
    func `bytes reads the whole file`() throws {
        try File.Directory.temporary { dir in
            let path = dir.path / "whole.bin"
            let content: [Byte] = ([1, 2, 3, 4, 5] as [UInt8]).map(Byte.init(bitPattern:))
            try File.System.Write.Atomic.write(content.span, to: path)

            #expect(try File(path).read.bytes() == content)
        }
    }

    @Test
    func `a range reads from the offset`() throws {
        try File.Directory.temporary { dir in
            let path = dir.path / "range.bin"
            let content: [Byte] = ([1, 2, 3, 4, 5] as [UInt8]).map(Byte.init(bitPattern:))
            try File.System.Write.Atomic.write(content.span, to: path)

            #expect(try File(path).read.bytes(from: .init(1), count: .init(3)) == Array(content[1..<4]))
        }
    }

    @Test
    func `a range past the end returns what is there`() throws {
        try File.Directory.temporary { dir in
            let path = dir.path / "short.bin"
            let content: [Byte] = ([1, 2, 3] as [UInt8]).map(Byte.init(bitPattern:))
            try File.System.Write.Atomic.write(content.span, to: path)

            #expect(try File(path).read.bytes(from: .init(2), count: .init(10)) == [content[2]])
            #expect(try File(path).read.bytes(from: .init(5), count: .init(10)).isEmpty)
            #expect(try File(path).read.bytes(from: .init(0), count: .init(0)).isEmpty)
        }
    }

    @Test
    func `a range of a missing file is not found`() throws {
        try File.Directory.temporary { dir in
            do throws(File.System.Read.Range.Error) {
                _ = try File(dir.path / "missing.bin").read.bytes(from: .init(0), count: .init(1))
                Issue.record("a missing file was read")
            } catch {
                #expect(error.isNotFound)
            }
        }
    }

    @Test
    func `ifExists is nil for a missing file and the bytes otherwise`() throws {
        try File.Directory.temporary { dir in
            let path = dir.path / "present.bin"
            let content: [Byte] = ([7, 8] as [UInt8]).map(Byte.init(bitPattern:))
            #expect(try File(path).read.ifExists() == nil)

            try File.System.Write.Atomic.write(content.span, to: path)
            #expect(try File(path).read.ifExists() == content)
        }
    }

    @Test
    func `ifExists still throws for a directory`() throws {
        try File.Directory.temporary { dir in
            do throws(File.System.Read.Full.Error) {
                _ = try File(dir.path).read.ifExists()
                Issue.record("a directory was read")
            } catch {
                #expect(error.isDirectory)
            }
        }
    }
}
