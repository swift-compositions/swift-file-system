#if Threads
    public import Either
    public import Kernel
    public import Thread_Pool

    extension File.Delete {

        @inlinable
        public func callAsFunction() async throws(Either<
            Kernel.Thread.Pool.Error, File.System.Delete.Error
        >) {
            let path = self.path
            try await Kernel.Thread.Pool.shared.run { () throws(File.System.Delete.Error) in
                try File.System.Delete.delete(at: path)
            }
        }

        @inlinable
        public func ifExists() async throws(Either<Kernel.Thread.Pool.Error, File.System.Delete.Error>) {
            let path = self.path
            do throws(Either<Kernel.Thread.Pool.Error, File.System.Delete.Error>) {
                try await Kernel.Thread.Pool.shared.run { () throws(File.System.Delete.Error) in
                    try File.System.Delete.delete(at: path)
                }
            } catch {
                if case .right(let deleteError) = error, deleteError.isNotFound {
                    return
                }
                throw error
            }
        }
    }
#endif
