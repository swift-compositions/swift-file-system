#if Threads
    public import Either
    public import Kernel
    public import Thread_Pool

    extension File.Copy {

        @discardableResult
        @inlinable
        public func to(
            _ destination: File.Path,
            options: File.System.Copy.Options = .init()
        ) async throws(Either<Kernel.Thread.Pool.Error, File.System.Copy.Error>) -> File {
            let source = self.path
            try await Kernel.Thread.Pool.shared.run { () throws(File.System.Copy.Error) in
                try File.System.Copy.copy(from: source, to: destination, options: options)
            }
            return File(destination)
        }

        @discardableResult
        @inlinable
        public func to(
            _ destination: File,
            options: File.System.Copy.Options = .init()
        ) async throws(Either<Kernel.Thread.Pool.Error, File.System.Copy.Error>) -> File {
            let source = self.path
            try await Kernel.Thread.Pool.shared.run { () throws(File.System.Copy.Error) in
                try File.System.Copy.copy(from: source, to: destination.path, options: options)
            }
            return destination
        }
    }
#endif
