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
