import File_System
import File_System_Test_Support
import Kernel
import Testing

extension File.Stat {
    @Suite
    struct Test {}
}

extension File.Stat.Test {
    @Test
    func `ifExists is nil for a missing file and the info otherwise`() throws {
        try File.Directory.temporary { dir in
            let path = dir.path / "stat.bin"
            #expect(try File(path).stat.ifExists() == nil)

            let content: [Byte] = ([1, 2, 3] as [UInt8]).map(Byte.init(bitPattern:))
            try File.System.Write.Atomic.write(content.span, to: path)
            #expect(try File(path).stat.ifExists()?.size.underlying == 3)
        }
    }
}
