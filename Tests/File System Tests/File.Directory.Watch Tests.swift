#if os(macOS)

    import Testing

    import Kernel
    @testable import File_System
    import File_System_Core
    import File_System_Test_Support

    extension File.Directory.Watch {
        @Suite(.timeLimit(.minutes(1)))
        struct Test {
            @Suite struct Unit {}
            @Suite struct `Edge Case` {}
            @Suite struct Integration {}
        }
    }

    extension File.Directory.Watch.Test {

        static func touch(_ path: File.Path) throws {
            let handle = try File.Handle.open(path, mode: .write, options: [.create, .execClose])
            try handle.close()
        }

        static func take(
            _ count: Int,
            from iterator: inout File.Directory.Watch.Iterator
        ) async throws -> Set<File.Path> {
            var paths: Set<File.Path> = []
            for _ in 0..<count {
                guard let directory = try await iterator.next() else { break }
                paths.insert(directory.path)
            }
            return paths
        }

        /// A directory, by inode alone: a stat through `/dev/fd` reports the descriptor table's
        /// device rather than the volume's.
        struct Node: Hashable {
            let inode: Kernel.Inode
        }

        static func node(_ path: File.Path) throws -> Node {
            Node(inode: try File.System.Stat.info(at: path).inode)
        }

        /// How many of this process's open descriptors are on one of the given directories.
        static func descriptors(on nodes: Set<Node>) throws -> Int {
            let table: File.Path = "/dev/fd"
            var count = 0
            for entry in try File.Directory.Contents.list(at: File.Directory(table)) {
                guard let path = entry.pathIfValid else { continue }
                do throws(Kernel.File.Stats.Error) {
                    let info = try File.System.Stat.info(at: path)
                    if info.type == .directory, nodes.contains(Node(inode: info.inode)) { count += 1 }
                } catch {
                    continue
                }
            }
            return count
        }
    }

    extension File.Directory.Watch.Test.Unit {

        @Test
        func `iteration first yields every watched directory and leaves out hidden and descended-against ones`()
            async throws
        {
            try await File.Directory.temporary { dir in
                let a = dir.path / "a"
                let b = a / "b"
                let modules = dir.path / "node_modules"
                let hidden = dir.path / ".build"
                let directories: [File.Path] = [a, b, modules, modules / "dependency", hidden]
                for path in directories {
                    try File.System.Create.Directory.create(at: path)
                }

                let watch = dir.watch(
                    options: .init(descend: { Swift.String($0.name) != "node_modules" })
                )
                var iterator = watch.makeAsyncIterator()
                let initial = try await File.Directory.Watch.Test.take(3, from: &iterator)

                #expect(initial == [dir.path, a, b])
            }
        }

        @Test
        func `a file created in a nested subfolder reports that subfolder`() async throws {
            try await File.Directory.temporary { dir in
                let nested = dir.path / "a" / "b"
                try File.System.Create.Directory.create(at: dir.path / "a")
                try File.System.Create.Directory.create(at: nested)

                var iterator = dir.watch().makeAsyncIterator()
                _ = try await File.Directory.Watch.Test.take(3, from: &iterator)

                try File.Directory.Watch.Test.touch(nested / "document.pdf")

                let changed = try await iterator.next()
                #expect(changed?.path == nested)
            }
        }

        @Test
        func `a new subfolder is watched and a file in it is reported`() async throws {
            try await File.Directory.temporary { dir in
                var iterator = dir.watch().makeAsyncIterator()
                _ = try await File.Directory.Watch.Test.take(1, from: &iterator)

                let added = dir.path / "added"
                try File.System.Create.Directory.create(at: added)

                let afterAdding = try await File.Directory.Watch.Test.take(2, from: &iterator)
                #expect(afterAdding == [added, dir.path])

                try File.Directory.Watch.Test.touch(added / "document.pdf")

                let changed = try await iterator.next()
                #expect(changed?.path == added)
            }
        }

        @Test
        func `a removed subfolder is dropped and its parent reported`() async throws {
            try await File.Directory.temporary { dir in
                let a = dir.path / "a"
                let b = a / "b"
                try File.System.Create.Directory.create(at: a)
                try File.System.Create.Directory.create(at: b)
                let nodeB = try File.Directory.Watch.Test.node(b)

                var iterator = dir.watch().makeAsyncIterator()
                _ = try await File.Directory.Watch.Test.take(3, from: &iterator)
                #expect(try File.Directory.Watch.Test.descriptors(on: [nodeB]) == 1)

                try File.System.Delete.delete(at: b, recursive: true)

                let changed = try await iterator.next()
                #expect(changed?.path == a)
                #expect(try File.Directory.Watch.Test.descriptors(on: [nodeB]) == 0)

                try File.Directory.Watch.Test.touch(a / "document.pdf")
                let again = try await iterator.next()
                #expect(again?.path == a)
            }
        }
    }

    extension File.Directory.Watch.Test.`Edge Case` {

        @Test
        func `passing the limit throws`() async throws {
            try await File.Directory.temporary { dir in
                try File.System.Create.Directory.create(at: dir.path / "a")

                var iterator = dir.watch(options: .init(limit: 1)).makeAsyncIterator()
                await #expect(throws: File.Directory.Watch.Error.limit(1)) {
                    _ = try await iterator.next()
                }
            }
        }

        @Test
        func `removing the watched directory throws`() async throws {
            try await File.Directory.temporary { dir in
                let root = dir.path / "root"
                try File.System.Create.Directory.create(at: root)

                var iterator = File.Directory(root).watch().makeAsyncIterator()
                _ = try await File.Directory.Watch.Test.take(1, from: &iterator)

                try File.System.Delete.delete(at: root, recursive: true)

                await #expect(throws: File.Directory.Watch.Error.removed(root)) {
                    _ = try await iterator.next()
                }
            }
        }
    }

    extension File.Directory.Watch.Test.Integration {

        @Test
        func `cancelling the consuming task closes every descriptor`() async throws {
            try await File.Directory.temporary { dir in
                let a = dir.path / "a"
                let b = a / "b"
                try File.System.Create.Directory.create(at: a)
                try File.System.Create.Directory.create(at: b)
                let nodes: Set<File.Directory.Watch.Test.Node> = [
                    try File.Directory.Watch.Test.node(dir.path),
                    try File.Directory.Watch.Test.node(a),
                    try File.Directory.Watch.Test.node(b),
                ]
                #expect(try File.Directory.Watch.Test.descriptors(on: nodes) == 0)

                let watch = dir.watch()
                let task = Task {
                    var yielded = 0
                    for try await _ in watch { yielded += 1 }
                    return yielded
                }

                var open = 0
                for _ in 0..<200 {
                    open = try File.Directory.Watch.Test.descriptors(on: nodes)
                    if open == 3 { break }
                    try await Task.sleep(for: .milliseconds(10))
                }
                #expect(open == 3)

                task.cancel()
                let yielded = try await task.value

                // The descriptors open before the initial directories are all yielded, so the
                // cancellation may land before the third.
                #expect(yielded <= 3)
                #expect(try File.Directory.Watch.Test.descriptors(on: nodes) == 0)
            }
        }

        @Test
        func `a cancelled next closes every descriptor while the iterator lives on`() async throws {
            try await File.Directory.temporary { dir in
                try File.System.Create.Directory.create(at: dir.path / "a")
                let nodes: Set<File.Directory.Watch.Test.Node> = [
                    try File.Directory.Watch.Test.node(dir.path),
                    try File.Directory.Watch.Test.node(dir.path / "a"),
                ]

                var iterator = dir.watch().makeAsyncIterator()
                _ = try await File.Directory.Watch.Test.take(2, from: &iterator)
                #expect(try File.Directory.Watch.Test.descriptors(on: nodes) == 2)

                let waiting = iterator
                let task = Task {
                    var iterator = waiting
                    return try await iterator.next()
                }
                task.cancel()
                let last = try await task.value

                #expect(last == nil)
                #expect(try File.Directory.Watch.Test.descriptors(on: nodes) == 0)
                #expect(try await iterator.next() == nil)
            }
        }
    }

#endif
