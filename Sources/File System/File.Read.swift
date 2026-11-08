public import Either
public import Kernel

extension File {

    public struct Read: Sendable {

        public let path: File.Path

        @usableFromInline
        internal init(_ path: File.Path) {
            self.path = path
        }
    }
}

extension File.Read {

    @inlinable
    public func full<R, E: Swift.Error>(
        _ body: (Swift.Span<Byte>) throws(E) -> R
    ) throws(Either<File.System.Read.Full.Error, E>) -> R {
        try File.System.Read.Full.read(from: path, body: body)
    }

    @inlinable
    public func bytes() throws(File.System.Read.Full.Error) -> [Byte] {
        try File.System.Read.Full.bytes(at: path)
    }

    @inlinable
    public func bytes(
        from offset: Kernel.File.Offset,
        count: Kernel.File.Size
    ) throws(File.System.Read.Range.Error) -> [Byte] {
        try File.System.Read.Range.bytes(at: path, from: offset, count: count)
    }

    @inlinable
    public func ifExists() throws(File.System.Read.Full.Error) -> [Byte]? {
        do throws(File.System.Read.Full.Error) {
            return try File.System.Read.Full.bytes(at: path)
        } catch {
            if error.isNotFound {
                return nil
            }
            throw error
        }
    }
}

extension File {

    public var read: Read {
        Read(path)
    }
}

#if Threads
    public import Either
    public import Kernel
    public import Thread_Pool

    extension File.Read {

        @inlinable
        public func full<R: Sendable, E: Swift.Error>(
            _ body: @escaping @Sendable (Swift.Span<Byte>) throws(E) -> R
        ) async throws(Either<Kernel.Thread.Pool.Error, Either<File.System.Read.Full.Error, E>>) -> R {
            let path = self.path
            return try await Kernel.Thread.Pool.shared.run {
                () throws(Either<File.System.Read.Full.Error, E>) -> R in
                try File.System.Read.Full.read(from: path, body: body)
            }
        }
    }
#endif
