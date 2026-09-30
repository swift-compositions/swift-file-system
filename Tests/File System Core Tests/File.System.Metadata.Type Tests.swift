import Kernel
import Testing

@testable import File_System_Core

@Suite
struct `File.System.Metadata.Kind Tests` {
    @Suite
    struct `Unit` {
        @Test
        func `all cases are distinct`() {
            let allCases: [File.System.Metadata.Kind] = [
                .regular, .directory, .symbolicLink, .blockDevice,
                .characterDevice, .fifo, .socket,
            ]
            let rawValues = allCases.map(\.rawValue)
            #expect(Set(rawValues).count == allCases.count)
        }

        @Test
        func `rawValue for .regular`() {
            #expect(File.System.Metadata.Kind.regular.rawValue.bitPattern == 0)
        }

        @Test
        func `rawValue for .directory`() {
            #expect(File.System.Metadata.Kind.directory.rawValue.bitPattern == 1)
        }

        @Test
        func `rawValue for .symbolicLink`() {
            #expect(File.System.Metadata.Kind.symbolicLink.rawValue.bitPattern == 2)
        }

        @Test
        func `rawValue for .blockDevice`() {
            #expect(File.System.Metadata.Kind.blockDevice.rawValue.bitPattern == 3)
        }

        @Test
        func `rawValue for .characterDevice`() {
            #expect(File.System.Metadata.Kind.characterDevice.rawValue.bitPattern == 4)
        }

        @Test
        func `rawValue for .fifo`() {
            #expect(File.System.Metadata.Kind.fifo.rawValue.bitPattern == 5)
        }

        @Test
        func `rawValue for .socket`() {
            #expect(File.System.Metadata.Kind.socket.rawValue.bitPattern == 6)
        }

        @Test
        func `rawValue round-trip for all cases`() {
            let allCases: [File.System.Metadata.Kind] = [
                .regular, .directory, .symbolicLink, .blockDevice,
                .characterDevice, .fifo, .socket,
            ]
            for type in allCases {
                let restored = File.System.Metadata.Kind(rawValue: type.rawValue)
                #expect(restored == type)
            }
        }

        @Test
        func `Binary.Serializable - serialize produces correct bytes`() {
            var buffer: [Byte] = []
            File.System.Metadata.Kind.serialize(.regular, into: &buffer)
            #expect(buffer == ([0] as [UInt8]).map(Byte.init(bitPattern:)))

            buffer = []
            File.System.Metadata.Kind.serialize(.directory, into: &buffer)
            #expect(buffer == ([1] as [UInt8]).map(Byte.init(bitPattern:)))

            buffer = []
            File.System.Metadata.Kind.serialize(.symbolicLink, into: &buffer)
            #expect(buffer == ([2] as [UInt8]).map(Byte.init(bitPattern:)))

            buffer = []
            File.System.Metadata.Kind.serialize(.blockDevice, into: &buffer)
            #expect(buffer == ([3] as [UInt8]).map(Byte.init(bitPattern:)))

            buffer = []
            File.System.Metadata.Kind.serialize(.characterDevice, into: &buffer)
            #expect(buffer == ([4] as [UInt8]).map(Byte.init(bitPattern:)))

            buffer = []
            File.System.Metadata.Kind.serialize(.fifo, into: &buffer)
            #expect(buffer == ([5] as [UInt8]).map(Byte.init(bitPattern:)))

            buffer = []
            File.System.Metadata.Kind.serialize(.socket, into: &buffer)
            #expect(buffer == ([6] as [UInt8]).map(Byte.init(bitPattern:)))
        }
    }

    @Suite
    struct `EdgeCase` {
        @Test
        func `invalid rawValue returns nil`() {
            #expect(File.System.Metadata.Kind(rawValue: Byte(bitPattern: 255)) == nil)
        }

        @Test
        func `boundary rawValue (just past valid)`() {
            #expect(File.System.Metadata.Kind(rawValue: Byte(bitPattern: 7)) == nil)
        }

        @Test
        func `all invalid rawValues from 7 to 255 return nil`() {
            (UInt8(7)...UInt8(255)).forEach { rawValue in
                #expect(File.System.Metadata.Kind(rawValue: Byte(rawValue)) == nil)
            }
        }
    }
}
