import File_System_Test_Support
import Kernel
import Testing

@testable import File_System_Core

enum `File.System.Canonical Tests` {}

extension `File.System.Canonical Tests` {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
        @Suite struct Integration {}
    }
}

extension `File.System.Canonical Tests`.Test.Unit {
    @Test
    func `Resolve existing directory`() throws {
        try File.Directory.temporary { directory in
            let resolved = try File.System.Canonical.resolve(directory.path)
            #expect(try File.System.same(resolved, directory.path))
        }
    }

    #if !os(Windows)
        @Test
        func `Resolve symbolic link target`() throws {
            try File.Directory.temporary { directory in
                let target = directory.path / "target"
                try File.System.Create.Directory.create(at: target)

                let link = directory.path / "link"
                try File.System.Link.Symbolic.create(at: link, pointingTo: target)

                let resolved = try File.System.Canonical.resolve(link)
                #expect(try File.System.same(resolved, target))
            }
        }

        #if os(Linux) || os(Android)
            @Test
            func `Resolve preserves native path code units`() throws {
                try File.Directory.temporary { directory in
                    let bytes: [File.Path.Char] = [0xFF]
                    let component = File.Path(bytes.span)
                    let target = directory.path / component
                    try File.System.Create.Directory.create(at: target)

                    let resolved = try File.System.Canonical.resolve(target)
                    #expect(try File.System.same(resolved, target))
                    #expect(resolved.components.last == component.components.last)
                }
            }
        #endif

        @Test
        func `Resolve represents a physical target with a control character`() throws {
            try File.Directory.temporary { directory in
                var rawTarget: [File.Path.Char] = []
                rawTarget.reserveCapacity(directory.path.count + 3)
                (0..<directory.path.count).forEach { index in
                    rawTarget.append(directory.path.unit(at: index))
                }
                rawTarget.append(0x2F)
                rawTarget.append(0x01)
                rawTarget.append(0)

                try rawTarget.withUnsafeBufferPointer {
                    pointer throws(Kernel.Directory.Create.Error) in
                    let path = unsafe Path.Borrowed(
                        pointer.baseAddress!,
                        count: pointer.count - 1
                    )
                    try Kernel.Directory.Create.create(path)
                }
                defer {
                    try? rawTarget.withUnsafeBufferPointer {
                        pointer throws(Kernel.Directory.Remove.Error) in
                        let path = unsafe Path.Borrowed(
                            pointer.baseAddress!,
                            count: pointer.count - 1
                        )
                        try Kernel.Directory.Remove.remove(path)
                    }
                }

                let link = directory.path / "link"
                try rawTarget.withUnsafeBufferPointer {
                    targetPointer throws(Kernel.Link.Symbolic.Error) in
                    let target = unsafe Path.Borrowed(
                        targetPointer.baseAddress!,
                        count: targetPointer.count - 1
                    )
                    try Kernel.Link.Symbolic.create(target: target, at: link.view)
                }
                defer { try? File.System.Delete.delete(at: link) }

                // What the system returns is always a path: control characters included.
                let resolved = try File.System.Canonical.resolve(link)
                #expect(resolved.unit(at: resolved.count - 1) == 0x01)
            }
        }
    #endif

    @Test
    func `Resolve nonexistent path reports not found`() throws {
        try File.Directory.temporary { directory in
            let nonexistent = directory.path / "nonexistent"

            do throws(File.System.Canonical.Error) {
                _ = try File.System.Canonical.resolve(nonexistent)
                Issue.record("Expected nonexistent path to fail resolution")
            } catch {
                #expect(error == .resolution(.path(.notFound)))
                #expect(error.isNotFound)
            }
        }
    }
}

#if !os(Windows)
    extension `File.System.Canonical Tests`.Test.`Edge Case` {
        @Test
        func `Resolve symbolic link loop reports loop`() throws {
            try File.Directory.temporary { directory in
                let first = directory.path / "first"
                let second = directory.path / "second"
                try File.System.Link.Symbolic.create(at: first, pointingTo: second)
                try File.System.Link.Symbolic.create(at: second, pointingTo: first)

                do throws(File.System.Canonical.Error) {
                    _ = try File.System.Canonical.resolve(first)
                    Issue.record("Expected symbolic-link loop to fail resolution")
                } catch {
                    #expect(error == .resolution(.path(.loop)))
                    #expect(error.isLoop)
                }
            }
        }
    }
#endif
