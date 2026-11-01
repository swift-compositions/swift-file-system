import File_System_Core
import Testing

extension Path.Component {
    @Suite
    struct Cleaning {
        @Suite
        struct Unit {}

        @Suite
        struct `Edge Case` {}
    }
}

extension Path.Component.Cleaning.Unit {

    @Test
    func `text a portable name can hold is kept as it is`() {
        #expect(Path.Component(cleaning: "2025-03-14 Ancora Health B.V. – Certificaten")?.string == "2025-03-14 Ancora Health B.V. – Certificaten")
    }

    @Test
    func `characters no file system takes become spaces on every platform`() {
        #expect(Path.Component(cleaning: #"a/b\c:d*e?f"g<h>i|j"#)?.string == "a b c d e f g h i j")
    }

    @Test
    func `control characters and line breaks become spaces`() {
        #expect(Path.Component(cleaning: "one\ntwo\tthree\u{0}four\u{2028}five")?.string == "one two three four five")
    }

    @Test
    func `a bidirectional override becomes a space`() {
        #expect(Path.Component(cleaning: "invoice\u{202E}fdp.exe")?.string == "invoice fdp.exe")
    }

    @Test
    func `runs of white space collapse to one space`() {
        #expect(Path.Component(cleaning: "a  \t b \u{00A0}  c")?.string == "a b c")
    }

    @Test
    func `leading and trailing spaces and dots go, inner dots stay`() {
        #expect(Path.Component(cleaning: " . .profile. ")?.string == "profile")
        #expect(Path.Component(cleaning: "Ancora B.V.")?.string == "Ancora B.V")
        #expect(Path.Component(cleaning: "archive.tar.gz")?.string == "archive.tar.gz")
    }

    @Test
    func `a Windows device name gets an underscore before its first dot`() {
        #expect(Path.Component(cleaning: "con")?.string == "con_")
        #expect(Path.Component(cleaning: "COM1")?.string == "COM1_")
        #expect(Path.Component(cleaning: "Nul.tar.gz")?.string == "Nul_.tar.gz")
        #expect(Path.Component(cleaning: "lpt9.txt")?.string == "lpt9_.txt")
    }

    @Test
    func `a name that only starts like a device is not one`() {
        #expect(Path.Component(cleaning: "Console")?.string == "Console")
        #expect(Path.Component(cleaning: "COM10")?.string == "COM10")
        #expect(Path.Component(cleaning: "COM")?.string == "COM")
    }

    @Test
    func `text with nothing nameable becomes the fallback`() {
        let fallback: Path.Component = "untitled"
        #expect(Path.Component(cleaning: "  ", fallback: fallback) == fallback)
        #expect(Path.Component(cleaning: "/?.", fallback: fallback) == fallback)
        #expect(Path.Component(cleaning: "", fallback: fallback) == fallback)
        #expect(Path.Component(cleaning: "name", fallback: fallback).string == "name")
    }

    @Test
    func `a cleaned name is a lawful component`() throws {
        let cleaned = Path.Component(cleaning: "a/b\u{0}c", fallback: "x")
        #expect(try Path.Component(cleaned.string) == cleaned)
    }
}

extension Path.Component.Cleaning.`Edge Case` {

    @Test
    func `text with nothing nameable has no component`() {
        #expect(Path.Component(cleaning: "") == nil)
        #expect(Path.Component(cleaning: " \n\t ") == nil)
        #expect(Path.Component(cleaning: "...") == nil)
        #expect(Path.Component(cleaning: "*:?") == nil)
    }

    @Test
    func `cleaning a cleaned name changes nothing`() {
        let once = Path.Component(cleaning: " con / x. ", fallback: "x")
        #expect(Path.Component(cleaning: once.string) == once)
    }

    @Test
    func `a combining mark stays with its letter`() {
        #expect(Path.Component(cleaning: "e\u{301}e")?.string == "e\u{301}e")
    }
}
