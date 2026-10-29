#if Threads
    public import Either
    public import Kernel
    public import Thread_Pool

    extension File.Directory.Entries {

        @inlinable
        public func callAsFunction() async throws(Either<
            Kernel.Thread.Pool.Error, File.Directory.Contents.Error
        >) -> [File.Directory.Entry] {
            let path = self.path
            return try await Kernel.Thread.Pool.shared.run { () throws(File.Directory.Contents.Error) in
                try File.Directory.Contents.list(at: File.Directory(path))
            }
        }
    }
#endif
