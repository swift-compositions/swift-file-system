#if Threads
    public import Either
    public import Kernel
    public import Thread_Pool

    extension File.Directory.Create {

        @inlinable
        public func callAsFunction(
            options: File.System.Create.Directory.Options = .init()
        ) async throws(Either<Kernel.Thread.Pool.Error, File.System.Create.Directory.Error>) {
            let path = self.path
            try await Kernel.Thread.Pool.shared.run { () throws(File.System.Create.Directory.Error) in
                try File.System.Create.Directory.create(at: path, options: options)
            }
        }

        @inlinable
        public func recursive(
            options: File.System.Create.Directory.Options = .init()
        ) async throws(Either<Kernel.Thread.Pool.Error, File.System.Create.Directory.Error>) {
            let path = self.path
            let opts = options
            try await Kernel.Thread.Pool.shared.run { () throws(File.System.Create.Directory.Error) in
                try File.System.Create.Directory.create(
                    at: path,
                    options: opts,
                    createIntermediates: true
                )
            }
        }
    }
#endif
