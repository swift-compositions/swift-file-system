import File_System_Core
import Testing

extension `Path Tests` {
    @Suite
    struct Navigation {
        @Suite
        struct `Edge Case` {}
    }
}

extension `Path Tests`.Navigation.`Edge Case` {

    @Test
    func
        `hasPrefix is false when self is absolute and other is relative with the same leading component`()
        throws
    {
        let path = try Path(Swift.String("\(Path.Fixture.root)foo\(Path.Fixture.separator)bar"))
        let other = try Path(Swift.String("foo"))
        #expect(path.hasPrefix(other) == false)
    }

    @Test
    func `hasPrefix is false when self is relative and other is the absolute root`() throws {
        let path = try Path(Swift.String("foo"))
        let other = try Path(Path.Fixture.root)
        #expect(path.hasPrefix(other) == false)
    }

    @Test
    func
        `hasPrefix is false when self is relative and other is absolute with the same leading component`()
        throws
    {
        let path = try Path(Swift.String("foo/etc"))
        let other = try Path(Swift.String("\(Path.Fixture.root)foo"))
        #expect(path.hasPrefix(other) == false)
    }

    @Test
    func `hasPrefix still returns true for a genuine absolute prefix`() throws {
        let path = try Path(Swift.String("/Users/coen/Documents/file.txt"))
        let other = try Path(Swift.String("/Users/coen"))
        #expect(path.hasPrefix(other))
    }

    @Test
    func `hasPrefix still returns true for a genuine relative prefix`() throws {
        let path = try Path(Swift.String("foo/bar/baz"))
        let other = try Path(Swift.String("foo/bar"))
        #expect(path.hasPrefix(other))
    }

    @Test
    func
        `relative(to:) is nil when self is absolute and base is relative with the same leading component`()
        throws
    {
        let path = try Path(Swift.String("\(Path.Fixture.root)foo\(Path.Fixture.separator)bar"))
        let base = try Path(Swift.String("foo"))
        #expect(path.relative(to: base) == nil)
    }

    @Test
    func `relative(to:) is nil when self is relative and base is the absolute root`() throws {
        let path = try Path(Swift.String("foo"))
        let base = try Path(Path.Fixture.root)
        #expect(path.relative(to: base) == nil)
    }

    @Test
    func
        `relative(to:) is nil when self is relative and base is absolute with the same leading component`()
        throws
    {
        let path = try Path(Swift.String("foo/etc"))
        let base = try Path(Swift.String("\(Path.Fixture.root)foo"))
        #expect(path.relative(to: base) == nil)
    }

    @Test
    func `relative(to:) still strips a genuine absolute base`() throws {
        let root = Path.Fixture.root
        let sep = Path.Fixture.separator
        let path = try Path(Swift.String("\(root)Users\(sep)coen\(sep)Documents\(sep)file.txt"))
        let base = try Path(Swift.String("\(root)Users\(sep)coen"))
        #expect(path.relative(to: base)?.string == "Documents\(sep)file.txt")
    }

    #if os(Windows)
        @Test
        func `hasPrefix is false across differing Windows drive-letter roots`() throws {
            let path = try Path(Swift.String("D:\\Users\\foo"))
            let other = try Path(Swift.String("C:\\"))
            #expect(path.hasPrefix(other) == false)
        }

        @Test
        func `hasPrefix is false between a drive-absolute path and a UNC-absolute root`() throws {
            let path = try Path(Swift.String("C:\\Users\\foo"))
            let other = try Path(Swift.String("\\\\server\\Users"))
            #expect(path.hasPrefix(other) == false)
        }

        @Test
        func `hasPrefix still returns true for a genuine Windows drive-letter prefix`() throws {
            let path = try Path(Swift.String("C:\\Users\\coen\\file.txt"))
            let other = try Path(Swift.String("C:\\Users\\coen"))
            #expect(path.hasPrefix(other))
        }
    #endif
}
