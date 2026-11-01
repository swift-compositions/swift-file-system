import File_System_Core
import Testing

extension Path.Component {
    @Suite
    struct Bound {
        @Suite
        struct Unit {}

        @Suite
        struct `Edge Case` {}
    }
}

extension Path.Component.Bound.Unit {

    @Test
    func `a component within the bound comes back unchanged`() {
        let component: Path.Component = "report.pdf"
        #expect(component.bounded(to: 10) == component)
        #expect(component.bounded() == component)
    }

    @Test
    func `a long component is cut to the byte count`() {
        let component: Path.Component = "abcdefghij"
        #expect(component.bounded(to: 4)?.string == "abcd")
    }

    @Test
    func `the cut never splits a character`() {
        // "é" as one scalar is two UTF-8 bytes; "e" + U+0301 is one character of three bytes.
        let composed: Path.Component = "ab\u{E9}"
        #expect(composed.bounded(to: 3)?.string == "ab")
        let decomposed: Path.Component = "ab\u{65}\u{301}"
        #expect(decomposed.bounded(to: 4)?.string == "ab")
        #expect(decomposed.bounded(to: 5)?.string == "ab\u{65}\u{301}")
    }

    @Test
    func `the default bound is the portable 255 bytes`() {
        let long = Path.Component(cleaning: Swift.String(repeating: "\u{E9}", count: 200), fallback: "x")
        let bounded = long.bounded()
        #expect(Path.Component.limit == 255)
        #expect(bounded?.string.utf8.count == 254)
        #expect(bounded?.string.utf16.count == 127)
    }
}

extension Path.Component.Bound.`Edge Case` {

    @Test
    func `nothing fits when the first character is larger than the bound`() {
        let component: Path.Component = "\u{1F600}x"
        #expect(component.bounded(to: 3) == nil)
        #expect(component.bounded(to: 0) == nil)
        #expect(component.bounded(to: 4)?.string == "\u{1F600}")
    }

    @Test
    func `the cut keeps a trailing space for the caller to resolve`() {
        let component: Path.Component = "ab cd"
        #expect(component.bounded(to: 3)?.string == "ab ")
    }
}
