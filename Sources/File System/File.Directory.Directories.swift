extension File.Directory {

    public struct Directories: Sendable {

        public let path: File.Path

        @usableFromInline
        internal init(_ path: File.Path) {
            self.path = path
        }
    }
}

extension File.Directory.Directories {

    @inlinable
    public func callAsFunction() throws(File.Directory.Contents.Error) -> [File.Directory] {
        try File.Directory.Contents.list(at: File.Directory(path))
            .filter { $0.type == .directory }
            .compactMap { $0.pathIfValid.map { File.Directory($0) } }
    }
}

extension File.Directory {

    public var directories: Directories {
        Directories(path)
    }
}

#if Threads
    public import Either
    public import Kernel
    public import Thread_Pool

    extension File.Directory.Directories {

        @inlinable
        public func callAsFunction(
            on pool: Kernel.Thread.Pool
        ) async throws(Either<
            Kernel.Thread.Pool.Error, File.Directory.Contents.Error
        >) -> [File.Directory] {
            let path = self.path
            return try await pool.run { () throws(File.Directory.Contents.Error) in
                try File.Directory.Contents.list(at: File.Directory(path))
                    .filter { $0.type == .directory }
                    .compactMap { $0.pathIfValid.map { File.Directory($0) } }
            }
        }
    }
#endif
