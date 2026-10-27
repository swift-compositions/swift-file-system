import File_System_Test_Support
import Kernel
import Testing

@testable import File_System_Core

extension File.System.Metadata.Attributes {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
        @Suite struct Integration {}
        @Suite(.serialized) struct Performance {}
    }
}

extension File.System.Metadata.Attributes.Test.Unit {

    @Test
    func `A set attribute reads back and is listed`() throws {
        try File.Directory.temporary { dir in
            let filePath = dir.path / "letter.txt"
            let empty: [Byte] = []
            try File.System.Write.Atomic.write(empty.span, to: filePath)

            let value = [Byte](utf8: "scan0042.txt")
            try File.System.Metadata.Attributes.set(
                "user.example.original-name",
                to: value.span,
                at: filePath
            )

            #expect(try File.System.Metadata.Attributes.get("user.example.original-name", at: filePath) == value)
            #expect(try File.System.Metadata.Attributes.list(at: filePath).contains("user.example.original-name"))
        }
    }

    @Test
    func `Setting an attribute again replaces its value`() throws {
        try File.Directory.temporary { dir in
            let filePath = dir.path / "letter.txt"
            let empty: [Byte] = []
            try File.System.Write.Atomic.write(empty.span, to: filePath)

            let first: [Byte] = ([1, 2, 3] as [UInt8]).map(Byte.init(bitPattern:))
            let second: [Byte] = [Byte(bitPattern: 0xFF)]
            try File.System.Metadata.Attributes.set("user.example.value", to: first.span, at: filePath)
            try File.System.Metadata.Attributes.set("user.example.value", to: second.span, at: filePath)

            #expect(try File.System.Metadata.Attributes.get("user.example.value", at: filePath) == second)
        }
    }

    @Test
    func `A removed attribute reads as absent`() throws {
        try File.Directory.temporary { dir in
            let filePath = dir.path / "letter.txt"
            let empty: [Byte] = []
            try File.System.Write.Atomic.write(empty.span, to: filePath)

            let value: [Byte] = [Byte(bitPattern: 0x2A)]
            try File.System.Metadata.Attributes.set("user.example.value", to: value.span, at: filePath)
            try File.System.Metadata.Attributes.remove("user.example.value", at: filePath)

            #expect(try File.System.Metadata.Attributes.get("user.example.value", at: filePath) == nil)
            #expect(try !File.System.Metadata.Attributes.list(at: filePath).contains("user.example.value"))
        }
    }
}

extension File.System.Metadata.Attributes.Test.`Edge Case` {

    @Test
    func `An attribute the file never had reads as absent`() throws {
        try File.Directory.temporary { dir in
            let filePath = dir.path / "letter.txt"
            let empty: [Byte] = []
            try File.System.Write.Atomic.write(empty.span, to: filePath)

            #expect(try File.System.Metadata.Attributes.get("user.example.missing", at: filePath) == nil)
        }
    }

    @Test
    func `Removing an attribute the file never had is not an error`() throws {
        try File.Directory.temporary { dir in
            let filePath = dir.path / "letter.txt"
            let empty: [Byte] = []
            try File.System.Write.Atomic.write(empty.span, to: filePath)

            try File.System.Metadata.Attributes.remove("user.example.missing", at: filePath)
        }
    }

    @Test
    func `An empty value is kept as empty, not as absent`() throws {
        try File.Directory.temporary { dir in
            let filePath = dir.path / "letter.txt"
            let empty: [Byte] = []
            try File.System.Write.Atomic.write(empty.span, to: filePath)

            try File.System.Metadata.Attributes.set("user.example.empty", to: empty.span, at: filePath)

            #expect(try File.System.Metadata.Attributes.get("user.example.empty", at: filePath) == [])
        }
    }

    @Test
    func `A missing file throws`() {
        let filePath = File.Path("/nonexistent-\(Swift.UInt64.random(in: 0 ... .max))/letter.txt")
        #expect(throws: File.System.Metadata.Attributes.Error.self) {
            try File.System.Metadata.Attributes.list(at: filePath)
        }
    }
}
