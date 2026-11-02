import File_System
import File_System_Test_Support
import Kernel
import Testing

#if !os(Windows)
    extension File.Write {
        @Suite
        struct Test {}
    }

    extension File.Write.Test {
        @Test
        func `a file append creates gets the permissions asked for`() throws {
            try File.Directory.temporary { dir in
                let path = dir.path / "private.log"
                try File(path).write.append("line\n", options: .init(permissions: .init(rawValue: 0o600)))
                try File(path).write.append("more\n", options: .init(permissions: .init(rawValue: 0o644)))

                #expect(try File(path).stat.permissions.rawValue & 0o777 == 0o600)
                #expect(try File(path).read.bytes().count == 10)
            }
        }
    }
#endif
