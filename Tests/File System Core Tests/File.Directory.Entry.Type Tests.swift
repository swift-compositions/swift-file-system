import Kernel
import Testing

@testable import File_System_Core

@Suite
struct `File.Directory.Entry.Kind Tests` {
    @Suite
    struct `Unit` {
        @Test
        func `all cases are distinct`() {
            let allCases: [File.Directory.Entry.Kind] = [.file, .directory, .symbolicLink, .other]
            let rawValues = allCases.map(\.rawValue)
            #expect(Set(rawValues).count == allCases.count)
        }

        @Test
        func `rawValue for .file`() {
            #expect(File.Directory.Entry.Kind.file.rawValue.bitPattern == 0)
        }

        @Test
        func `rawValue for .directory`() {
            #expect(File.Directory.Entry.Kind.directory.rawValue.bitPattern == 1)
        }

        @Test
        func `rawValue for .symbolicLink`() {
            #expect(File.Directory.Entry.Kind.symbolicLink.rawValue.bitPattern == 2)
        }

        @Test
        func `rawValue for .other`() {
            #expect(File.Directory.Entry.Kind.other.rawValue.bitPattern == 3)
        }

        @Test
        func `rawValue round-trip for .file`() {
            let type = File.Directory.Entry.Kind.file
            let restored = File.Directory.Entry.Kind(rawValue: type.rawValue)
            #expect(restored == type)
        }

        @Test
        func `rawValue round-trip for .directory`() {
            let type = File.Directory.Entry.Kind.directory
            let restored = File.Directory.Entry.Kind(rawValue: type.rawValue)
            #expect(restored == type)
        }

        @Test
        func `rawValue round-trip for .symbolicLink`() {
            let type = File.Directory.Entry.Kind.symbolicLink
            let restored = File.Directory.Entry.Kind(rawValue: type.rawValue)
            #expect(restored == type)
        }

        @Test
        func `rawValue round-trip for .other`() {
            let type = File.Directory.Entry.Kind.other
            let restored = File.Directory.Entry.Kind(rawValue: type.rawValue)
            #expect(restored == type)
        }

        @Test
        func `Binary.Serializable - serialize produces correct byte`() {
            var buffer: [Byte] = []
            File.Directory.Entry.Kind.serialize(.file, into: &buffer)
            #expect(buffer == ([0] as [UInt8]).map(Byte.init(bitPattern:)))

            buffer = []
            File.Directory.Entry.Kind.serialize(.directory, into: &buffer)
            #expect(buffer == ([1] as [UInt8]).map(Byte.init(bitPattern:)))

            buffer = []
            File.Directory.Entry.Kind.serialize(.symbolicLink, into: &buffer)
            #expect(buffer == ([2] as [UInt8]).map(Byte.init(bitPattern:)))

            buffer = []
            File.Directory.Entry.Kind.serialize(.other, into: &buffer)
            #expect(buffer == ([3] as [UInt8]).map(Byte.init(bitPattern:)))
        }
    }

    @Suite
    struct `EdgeCase` {
        @Test
        func `invalid rawValue returns nil`() {
            #expect(File.Directory.Entry.Kind(rawValue: Byte(bitPattern: 255)) == nil)
        }

        @Test
        func `boundary rawValue (just past valid)`() {
            #expect(File.Directory.Entry.Kind(rawValue: Byte(bitPattern: 4)) == nil)
        }

        @Test
        func `all invalid rawValues from 4 to 255 return nil`() {
            (UInt8(4)...UInt8(255)).forEach { rawValue in
                #expect(File.Directory.Entry.Kind(rawValue: Byte(rawValue)) == nil)
            }
        }
    }
}
