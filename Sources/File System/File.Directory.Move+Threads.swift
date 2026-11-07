#if Threads
    public import Either
    public import Kernel
    public import Thread_Pool

    extension File.Directory.Move {

        @discardableResult
        @inlinable
        public func to(
            _ destination: File.Path,
            options: File.System.Move.Options = .init()
        ) async throws(Either<Kernel.Thread.Pool.Error, File.System.Move.Error>) -> File.Directory {
            let source = self.path
            try await Kernel.Thread.Pool.shared.run { () throws(File.System.Move.Error) in
                try File.System.Move.move(from: source, to: destination, options: options)
            }
            return File.Directory(destination)
        }

        @discardableResult
        @inlinable
        public func to(
            _ destination: File.Directory,
            options: File.System.Move.Options = .init()
        ) async throws(Either<Kernel.Thread.Pool.Error, File.System.Move.Error>) -> File.Directory {
            let source = self.path
            try await Kernel.Thread.Pool.shared.run { () throws(File.System.Move.Error) in
                try File.System.Move.move(from: source, to: destination.path, options: options)
            }
            return destination
        }

        @discardableResult
        @inlinable
        public func rename(
            to newName: File.Path.Component,
            options: File.System.Move.Options = .init()
        ) async throws(Either<Kernel.Thread.Pool.Error, File.System.Move.Error>) -> File.Directory {
            guard let parent = path.parent else {

                throw .right(.rename(.invalidArgument))
            }
            let destination = parent / newName
            let source = self.path
            try await Kernel.Thread.Pool.shared.run { () throws(File.System.Move.Error) in
                try File.System.Move.move(from: source, to: destination, options: options)
            }
            return File.Directory(destination)
        }
    }
#endif
