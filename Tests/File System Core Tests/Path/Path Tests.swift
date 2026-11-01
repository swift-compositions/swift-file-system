import File_System_Core
import Testing

extension Path {
    @Suite
    struct Test {

        @Test
        func `Valid absolute path initialization`() throws {
            let path = try Path(Swift.String("/Users/coen/Documents"))
            #expect(path.string == Path.Fixture.native("/Users/coen/Documents"))
        }

        @Test
        func `Valid relative path initialization`() throws {
            let path = try Path(Swift.String("foo/bar/baz"))
            #expect(path.string == Path.Fixture.native("foo/bar/baz"))
        }

        @Test
        func `Single component path`() throws {
            let path = try Path(Swift.String("file.txt"))
            #expect(path.string == "file.txt")
        }

        @Test
        func `Root path`() throws {
            let path = try Path(Swift.String("/"))
            #expect(path.string == Path.Fixture.native("/"))
            #if os(Windows)
                #expect(path.isAbsolute == false)
            #else
                #expect(path.isAbsolute == true)
            #endif
        }

        @Test
        func `Parent of nested path`() throws {
            let path = try Path(Swift.String("/usr/local/bin"))
            #expect(path.parent?.string == Path.Fixture.native("/usr/local"))
        }

        @Test
        func `Parent of root path is nil`() throws {
            let path = try Path(Swift.String("/"))
            #expect(path.parent == nil)
        }

        @Test
        func `Parent chain`() throws {
            let root = Path.Fixture.root
            let sep = Path.Fixture.separator
            let path = try Path(Swift.String("\(root)a\(sep)b\(sep)c"))
            #expect(path.parent?.string == "\(root)a\(sep)b")
            #expect(path.parent?.parent?.string == "\(root)a")
            #expect(path.parent?.parent?.parent?.string == root)
            #expect(path.parent?.parent?.parent?.parent == nil)
        }

        @Test
        func `Path components`() throws {
            let path = try Path(Swift.String("/Users/coen/Documents"))
            let components = path.components.map(\.string)
            #expect(components == ["Users", "coen", "Documents"])
        }

        @Test
        func `components.last on multi-component path`() throws {
            let path = try Path(Swift.String("/usr/local/bin"))
            #expect(path.components.last?.string == "bin")
        }

        @Test
        func `components.last on single-component path`() throws {
            let path = try Path(Swift.String("file.txt"))
            #expect(path.components.last?.string == "file.txt")
        }

        @Test
        func `Extension of file`() throws {
            let path = try Path(Swift.String("/tmp/file.txt"))
            #expect(path.extension == "txt")
        }

        @Test
        func `Extension with multiple dots`() throws {
            let path = try Path(Swift.String("/tmp/file.tar.gz"))
            #expect(path.extension == "gz")
        }

        @Test
        func `Extension of directory (none)`() throws {
            let path = try Path(Swift.String("/usr/local/bin"))
            #expect(path.extension == nil)
        }

        @Test
        func `Stem of file`() throws {
            let path = try Path(Swift.String("/tmp/file.txt"))
            #expect(path.stem == "file")
        }

        @Test
        func `Stem with multiple dots`() throws {
            let path = try Path(Swift.String("/tmp/file.tar.gz"))
            #expect(path.stem == "file.tar")
        }

        @Test
        func `isAbsolute for absolute path`() throws {
            let path = try Path(Swift.String("/usr/bin"))
            #if os(Windows)
                #expect(path.isAbsolute == false)
            #else
                #expect(path.isAbsolute == true)
            #endif
        }

        @Test
        func `isAbsolute for relative path`() throws {
            let path = try Path(Swift.String("usr/bin"))
            #expect(path.isAbsolute == false)
        }

        @Test
        func `Slash operator with string`() throws {
            let path = try Path(Swift.String("/usr"))
            let newPath = path / "local" / "bin"
            #expect(newPath.string == Path.Fixture.native("/usr/local/bin"))
        }

        @Test
        func `Slash operator with Component`() throws {
            let path = try Path(Swift.String("/usr"))
            let component = try Path.Component(Swift.String("local"))
            let newPath = path / component
            #expect(newPath.string == Path.Fixture.native("/usr/local"))
        }

        @Test
        func `Slash operator with chained components`() throws {
            let dir = try Path(Swift.String("/Users/coen"))
            let nested = dir / "Documents" / "Projects" / "readme.txt"
            #expect(nested.string == Path.Fixture.native("/Users/coen/Documents/Projects/readme.txt"))
        }

        @Test
        func `Slash operator with relative path`() throws {
            let dir = try Path(Swift.String("/Users/coen"))
            let rel = try Path(Swift.String("Documents/Projects/readme.txt"))
            let nested = dir / rel

            #expect(nested.string == Path.Fixture.native("/Users/coen/Documents/Projects/readme.txt"))
        }

        @Test
        func `hasPrefix returns true for proper prefix`() throws {
            let path = try Path(Swift.String("/Users/coen/Documents"))
            #expect(path.hasPrefix(try Path(Swift.String("/Users"))))
            #expect(path.hasPrefix(try Path(Swift.String("/Users/coen"))))
            #expect(path.hasPrefix(try Path(Swift.String("/Users/coen/Documents"))))
        }

        @Test
        func `hasPrefix returns false for mismatch`() throws {
            let path = try Path(Swift.String("/Users/coen/Documents"))
            #expect(!path.hasPrefix(try Path(Swift.String("/var"))))
            #expect(!path.hasPrefix(try Path(Swift.String("/Users/bob"))))
        }

        @Test
        func `hasPrefix returns false when other is longer`() throws {
            let path = try Path(Swift.String("/Users"))
            #expect(!path.hasPrefix(try Path(Swift.String("/Users/coen/Documents"))))
        }

        @Test
        func `hasPrefix with relative paths`() throws {
            let path = try Path(Swift.String("foo/bar/baz"))
            #expect(path.hasPrefix(try Path(Swift.String("foo"))))
            #expect(path.hasPrefix(try Path(Swift.String("foo/bar"))))
            #expect(!path.hasPrefix(try Path(Swift.String("bar"))))
        }

        @Test
        func `relative(to:) strips the base prefix`() throws {
            let full = try Path(Swift.String("/Users/coen/Documents/file.txt"))
            let base = try Path(Swift.String("/Users/coen"))
            let rel = full.relative(to: base)
            #expect(rel?.string == "Documents\(Path.Fixture.separator)file.txt")
        }

        @Test
        func `Relative(to:) returns . for equal paths`() throws {
            let p = try Path(Swift.String("/Users/coen"))
            let rel = p.relative(to: p)
            #expect(rel?.string == ".")
        }

        @Test
        func `relative(to:) returns nil when base isn't a prefix`() throws {
            let full = try Path(Swift.String("/Users/coen/Documents"))
            let base = try Path(Swift.String("/var/log"))
            #expect(full.relative(to: base) == nil)
        }

        @Test
        func `components.last with trailing separator omits empty`() throws {
            #expect(try Path(Swift.String("backup/")).components.last?.string == "backup")
            #expect(try Path(Swift.String("/foo/")).components.last?.string == "foo")
            #expect(try Path(Swift.String("/")).components.last == nil)
        }

        @Test
        func `components.first returns the first non-empty segment`() throws {
            #expect(try Path(Swift.String("/foo/bar")).components.first?.string == "foo")
            #expect(try Path(Swift.String("//foo")).components.first?.string == "foo")
            #expect(try Path(Swift.String("foo/bar")).components.first?.string == "foo")
        }

        @Test
        func `components iteration omits empty segments`() throws {
            let path = try Path(Swift.String("/foo//bar/"))
            let names = path.components.map(\.string)
            #expect(names == ["foo", "bar"])
        }

        @Test
        func `components.count matches eager materialization`() throws {
            let path = try Path(Swift.String("/a/b/c/d/e"))
            #expect(path.components.count == 5)
        }

        @Test
        func `ExpressibleByStringLiteral`() {
            let path: Path = "/usr/local/bin"
            #expect(path.string == Path.Fixture.native("/usr/local/bin"))
        }

        @Test
        func `Hashable conformance`() throws {
            let path1 = try Path(Swift.String("/usr/local"))
            let path2 = try Path(Swift.String("/usr/local"))
            let path3 = try Path(Swift.String("/usr/bin"))

            #expect(path1.hashValue == path2.hashValue)
            #expect(path1.hashValue != path3.hashValue)
        }

        @Test
        func `Equatable conformance`() throws {
            let path1 = try Path(Swift.String("/usr/local"))
            let path2 = try Path(Swift.String("/usr/local"))
            let path3 = try Path(Swift.String("/usr/bin"))

            #expect(path1 == path2)
            #expect(path1 != path3)
        }

        @Test
        func `Use in Set`() throws {
            let path1 = try Path(Swift.String("/usr/local"))
            let path2 = try Path(Swift.String("/usr/local"))
            let path3 = try Path(Swift.String("/usr/bin"))

            let set: Set<Path> = [path1, path2, path3]
            #expect(set.count == 2)
        }

        @Test
        func `Use as Dictionary key`() throws {
            let path1 = try Path(Swift.String("/usr/local"))
            let path2 = try Path(Swift.String("/usr/bin"))

            var dict: [Path: Int] = [:]
            dict[path1] = 1
            dict[path2] = 2

            #expect(dict[path1] == 1)
            #expect(dict[path2] == 2)
        }

        @Test
        func `String conversion`() throws {
            let path = try Path(Swift.String("/usr/local/bin"))
            #expect(Swift.String(path) == Path.Fixture.native("/usr/local/bin"))
        }
    }
}

extension Path.Error {
    @Suite
    struct Test {

        @Test
        func `Empty path throws empty error`() {
            let invalid: Swift.String = ""
            #expect(throws: Path.Error.empty) {
                try Path(invalid)
            }
        }

        @Test
        func `Interior NUL byte throws containsInteriorNUL`() {
            let invalid: Swift.String = "/tmp/file\0.txt"
            #expect(throws: Path.Error.containsInteriorNUL) {
                try Path(invalid)
            }
        }

        @Test
        func `Newline character throws containsControlCharacters`() {
            let invalid: Swift.String = "/tmp/file\n.txt"
            #expect(throws: Path.Error.containsControlCharacters) {
                try Path(invalid)
            }
        }

        @Test
        func `Carriage return throws containsControlCharacters`() {
            let invalid: Swift.String = "/tmp/file\r.txt"
            #expect(throws: Path.Error.containsControlCharacters) {
                try Path(invalid)
            }
        }

        @Test
        func `Tab character throws containsControlCharacters`() {
            let invalid: Swift.String = "/tmp/file\t.txt"
            #expect(throws: Path.Error.containsControlCharacters) {
                try Path(invalid)
            }
        }

        @Test
        func `Bell character throws containsControlCharacters`() {
            let invalid: Swift.String = "/tmp/file\u{07}.txt"
            #expect(throws: Path.Error.containsControlCharacters) {
                try Path(invalid)
            }
        }

        @Test
        func `Error cases are equatable`() {
            #expect(Path.Error.empty == Path.Error.empty)
            #expect(Path.Error.containsControlCharacters == Path.Error.containsControlCharacters)
            #expect(Path.Error.containsInteriorNUL == Path.Error.containsInteriorNUL)
            #expect(Path.Error.empty != Path.Error.containsControlCharacters)
            #expect(Path.Error.containsControlCharacters != Path.Error.containsInteriorNUL)
        }

        @Test
        func `Error is Sendable`() async {
            let error = Path.Error.empty

            await Task {
                #expect(error == .empty)
            }.value
        }

        @Test
        func `Error descriptions`() {
            #expect(Path.Error.empty.description.contains("empty"))
            #expect(Path.Error.containsControlCharacters.description.contains("control"))
            #expect(Path.Error.containsInteriorNUL.description.contains("NUL"))
        }
    }
}

extension Path.Component {
    @Suite
    struct Test {

        @Test
        func `Valid component initialization`() throws {
            let component = try Path.Component(Swift.String("file.txt"))
            #expect(component.string == "file.txt")
        }

        @Test
        func `Component with special characters`() throws {
            let component = try Path.Component(Swift.String("file-name_v2.0.txt"))
            #expect(component.string == "file-name_v2.0.txt")
        }

        @Test
        func `Component with spaces`() throws {
            let component = try Path.Component(Swift.String("my file.txt"))
            #expect(component.string == "my file.txt")
        }

        @Test
        func `Extension of component`() throws {
            let component = try Path.Component(Swift.String("readme.txt"))
            #expect(component.extension == "txt")
        }

        @Test
        func `Extension of dotfile (none)`() throws {
            let component = try Path.Component(Swift.String(".gitignore"))
            #expect(component.extension == nil)
        }

        @Test
        func `Extension with multiple dots`() throws {
            let component = try Path.Component(Swift.String("file.tar.gz"))
            #expect(component.extension == "gz")
        }

        @Test
        func `Extension when none`() throws {
            let component = try Path.Component(Swift.String("Makefile"))
            #expect(component.extension == nil)
        }

        @Test
        func `Stem of component`() throws {
            let component = try Path.Component(Swift.String("readme.txt"))
            #expect(component.stem == "readme")
        }

        @Test
        func `Stem of dotfile`() throws {
            let component = try Path.Component(Swift.String(".gitignore"))
            #expect(component.stem == ".gitignore")
        }

        @Test
        func `Stem with multiple dots`() throws {
            let component = try Path.Component(Swift.String("archive.tar.gz"))
            #expect(component.stem == "archive.tar")
        }

        @Test
        func `Stem when no extension`() throws {
            let component = try Path.Component(Swift.String("Makefile"))
            #expect(component.stem == "Makefile")
        }

        @Test
        func `ExpressibleByStringLiteral`() {
            let component: Path.Component = "file.txt"
            #expect(component.string == "file.txt")
        }

        @Test
        func `Hashable conformance`() throws {
            let comp1 = try Path.Component(Swift.String("file.txt"))
            let comp2 = try Path.Component(Swift.String("file.txt"))
            let comp3 = try Path.Component(Swift.String("other.txt"))

            #expect(comp1.hashValue == comp2.hashValue)
            #expect(comp1.hashValue != comp3.hashValue)
        }

        @Test
        func `Equatable conformance`() throws {
            let comp1 = try Path.Component(Swift.String("file.txt"))
            let comp2 = try Path.Component(Swift.String("file.txt"))
            let comp3 = try Path.Component(Swift.String("other.txt"))

            #expect(comp1 == comp2)
            #expect(comp1 != comp3)
        }

        @Test
        func `String conversion`() throws {
            let component = try Path.Component(Swift.String("file.txt"))
            #expect(Swift.String(component) == "file.txt")
        }

        @Test
        func `Component can be appended to path`() throws {
            let path = try Path(Swift.String("/usr/local"))
            let component = try Path.Component(Swift.String("bin"))
            let newPath = path / component
            #expect(newPath.string == Path.Fixture.native("/usr/local/bin"))
        }
    }
}

extension Path.Component.Error {
    @Suite
    struct Test {

        @Test
        func `Empty component throws empty error`() {
            let invalid: Swift.String = ""
            #expect(throws: Path.Component.Error.empty) {
                try Path.Component(invalid)
            }
        }

        @Test
        func `Component with path separator throws error`() {
            let invalid: Swift.String = "foo/bar"
            #expect(throws: Path.Component.Error.containsPathSeparator) {
                try Path.Component(invalid)
            }
        }

        @Test
        func `Interior NUL byte throws containsInteriorNUL`() {
            let invalid: Swift.String = "file\0.txt"
            #expect(throws: Path.Component.Error.containsInteriorNUL) {
                try Path.Component(invalid)
            }
        }

        @Test
        func `Control character throws containsControlCharacters`() {
            let invalid: Swift.String = "file\n.txt"
            #expect(throws: Path.Component.Error.containsControlCharacters) {
                try Path.Component(invalid)
            }
        }

        @Test
        func `Error cases are equatable`() {
            #expect(Path.Component.Error.empty == Path.Component.Error.empty)
            #expect(
                Path.Component.Error.containsPathSeparator
                    == Path.Component.Error.containsPathSeparator
            )
            #expect(Path.Component.Error.empty != Path.Component.Error.containsPathSeparator)
        }

        @Test
        func `Error descriptions`() {
            #expect(Path.Component.Error.empty.description.contains("empty"))
            #expect(Path.Component.Error.containsPathSeparator.description.contains("separator"))
            #expect(Path.Component.Error.containsControlCharacters.description.contains("control"))
            #expect(Path.Component.Error.containsInteriorNUL.description.contains("NUL"))
        }
    }
}
