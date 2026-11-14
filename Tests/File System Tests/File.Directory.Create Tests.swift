import File_System
import File_System_Test_Support
import Kernel
import Testing

#if Threads
    import Either
    import Thread_Pool
#endif

extension File.Directory.Create {
    @Suite
    struct Test {}
}

// These calls are written without `await` inside async functions. They compile, and stay synchronous with
// their own typed errors, whether the Threads trait is on or off: the trait only adds forms taking a pool.
extension File.Directory.Create.Test {
    private static func make(_ path: File.Path) async throws(File.System.Create.Directory.Error) {
        try File.Directory(path).create.recursive()
    }

    private static func remove(_ path: File.Path) async throws(File.System.Delete.Error) {
        try File.Directory(path).delete.recursive()
        try File(path / "gone").delete.ifExists()
    }

    @Test
    func `in an async context the synchronous create and delete keep their meaning`() async throws {
        try await File.Directory.temporary { dir in
            let path = dir.path / "a" / "b"
            try await Self.make(path)
            #expect(File.System.Stat.isDirectory(at: path))

            try await Self.remove(dir.path / "a")
            #expect(!File.System.Stat.exists(at: dir.path / "a"))
        }
    }
}

#if Threads
    extension File.Directory.Create.Test {
        @Test
        func `the thread pool forms create and delete on the pool they are given`() async throws {
            try await File.Directory.temporary { dir in
                let path = dir.path / "a" / "b"
                try await File.Directory(path).create.recursive(on: .shared)
                #expect(File.System.Stat.isDirectory(at: path))

                try await File.Directory(dir.path / "a").delete.recursive(on: .shared)
                #expect(!File.System.Stat.exists(at: dir.path / "a"))
                try await File(dir.path / "gone").delete.ifExists(on: .shared)
            }
        }
    }
#endif
