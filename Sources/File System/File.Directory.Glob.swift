#if Glob
    public import Glob

    extension File.Directory {

        public struct Glob: Sendable {

            @usableFromInline
            let directory: File.Directory

            @usableFromInline
            internal init(_ directory: File.Directory) {
                self.directory = directory
            }
        }
    }

    extension File.Directory {

        public var glob: Glob {
            Glob(self)
        }
    }

    extension File.Directory.Glob {

        @inlinable
        package func matchPaths(
            include: [Glob.Pattern],
            excluding: [Glob.Pattern],
            options: Glob.Options
        ) throws(Glob.Error) -> [Swift.String] {
            var results: [Swift.String] = []
            try Glob.match(
                include: include,
                excluding: excluding,
                in: directory.path.view,
                options: options
            ) { results.append($0) }

            return results
        }

        @inlinable
        package func matchPaths(
            include: [Swift.String],
            excluding: [Swift.String],
            options: Glob.Options
        ) throws(Glob.Error) -> [Swift.String] {
            var includePatterns: [Glob.Pattern] = []
            for pattern in include {
                includePatterns.append(try Glob.Pattern(pattern))
            }

            var excludePatterns: [Glob.Pattern] = []
            for pattern in excluding {
                excludePatterns.append(try Glob.Pattern(pattern))
            }

            return try matchPaths(
                include: includePatterns,
                excluding: excludePatterns,
                options: options
            )
        }
    }
#endif

#if Glob
    public import Either
    public import Glob
    import Kernel
    public import Thread_Pool

    extension File.Directory.Glob {

        @inlinable
        public func callAsFunction(
            include: [Glob.Pattern],
            excluding: [Glob.Pattern] = [],
            options: Glob.Options = .init()
        ) throws(Glob.Error) -> [Match] {
            let paths = try matchPaths(include: include, excluding: excluding, options: options)
            var results: [Match] = []
            for pathString in paths {
                let path = File.Path(__unchecked: (), pathString)
                if File.System.Stat.isDirectory(at: path) {
                    results.append(Match(directory: File.Directory(path)))
                } else {
                    results.append(Match(file: File(path)))
                }
            }
            return results
        }

        @inlinable
        public func callAsFunction(
            include: [Glob.Pattern],
            excluding: [Glob.Pattern] = [],
            options: Glob.Options = .init()
        ) async throws(Either<Kernel.Thread.Pool.Error, Glob.Error>) -> [Match] {
            let glob = self
            return try await Kernel.Thread.Pool.shared.run { () throws(Glob.Error) -> [Match] in
                try glob.callAsFunction(include: include, excluding: excluding, options: options)
            }
        }

        @inlinable
        public func callAsFunction(
            include: [Swift.String],
            excluding: [Swift.String] = [],
            options: Glob.Options = .init()
        ) throws(Glob.Error) -> [Match] {
            let paths = try matchPaths(include: include, excluding: excluding, options: options)
            var results: [Match] = []
            for pathString in paths {
                let path = File.Path(__unchecked: (), pathString)
                if File.System.Stat.isDirectory(at: path) {
                    results.append(Match(directory: File.Directory(path)))
                } else {
                    results.append(Match(file: File(path)))
                }
            }
            return results
        }

        @inlinable
        public func callAsFunction(
            include: [Swift.String],
            excluding: [Swift.String] = [],
            options: Glob.Options = .init()
        ) async throws(Either<Kernel.Thread.Pool.Error, Glob.Error>) -> [Match] {
            let glob = self
            return try await Kernel.Thread.Pool.shared.run { () throws(Glob.Error) -> [Match] in
                try glob.callAsFunction(include: include, excluding: excluding, options: options)
            }
        }
    }
#endif

#if Glob
    public import Either
    public import Glob
    import Kernel
    public import Thread_Pool

    extension File.Directory.Glob {

        @inlinable
        public func directories(
            include: [Glob.Pattern],
            excluding: [Glob.Pattern] = [],
            options: Glob.Options = .init()
        ) throws(Glob.Error) -> [File.Directory] {
            let paths = try matchPaths(include: include, excluding: excluding, options: options)
            var results: [File.Directory] = []
            for pathString in paths {
                let path = File.Path(__unchecked: (), pathString)
                if File.System.Stat.isDirectory(at: path) {
                    results.append(File.Directory(path))
                }
            }
            return results
        }

        @inlinable
        public func directories(
            include: [Glob.Pattern],
            excluding: [Glob.Pattern] = [],
            options: Glob.Options = .init()
        ) async throws(Either<Kernel.Thread.Pool.Error, Glob.Error>) -> [File.Directory] {
            let glob = self
            return try await Kernel.Thread.Pool.shared.run {
                () throws(Glob.Error) -> [File.Directory] in
                try glob.directories(include: include, excluding: excluding, options: options)
            }
        }

        @inlinable
        public func directories(
            include: [Swift.String],
            excluding: [Swift.String] = [],
            options: Glob.Options = .init()
        ) throws(Glob.Error) -> [File.Directory] {
            let paths = try matchPaths(include: include, excluding: excluding, options: options)
            var results: [File.Directory] = []
            for pathString in paths {
                let path = File.Path(__unchecked: (), pathString)
                if File.System.Stat.isDirectory(at: path) {
                    results.append(File.Directory(path))
                }
            }
            return results
        }

        @inlinable
        public func directories(
            include: [Swift.String],
            excluding: [Swift.String] = [],
            options: Glob.Options = .init()
        ) async throws(Either<Kernel.Thread.Pool.Error, Glob.Error>) -> [File.Directory] {
            let glob = self
            return try await Kernel.Thread.Pool.shared.run {
                () throws(Glob.Error) -> [File.Directory] in
                try glob.directories(include: include, excluding: excluding, options: options)
            }
        }
    }
#endif

#if Glob
    public import Either
    public import Glob
    import Kernel
    public import Thread_Pool

    extension File.Directory.Glob {

        @inlinable
        public func files(
            include: [Glob.Pattern],
            excluding: [Glob.Pattern] = [],
            options: Glob.Options = .init()
        ) throws(Glob.Error) -> [File] {
            let paths = try matchPaths(include: include, excluding: excluding, options: options)
            var results: [File] = []
            for pathString in paths {
                let path = File.Path(__unchecked: (), pathString)
                if !File.System.Stat.isDirectory(at: path) {
                    results.append(File(path))
                }
            }
            return results
        }

        @inlinable
        public func files(
            include: [Glob.Pattern],
            excluding: [Glob.Pattern] = [],
            options: Glob.Options = .init()
        ) async throws(Either<Kernel.Thread.Pool.Error, Glob.Error>) -> [File] {
            let glob = self
            return try await Kernel.Thread.Pool.shared.run { () throws(Glob.Error) -> [File] in
                try glob.files(include: include, excluding: excluding, options: options)
            }
        }

        @inlinable
        public func files(
            include: [Swift.String],
            excluding: [Swift.String] = [],
            options: Glob.Options = .init()
        ) throws(Glob.Error) -> [File] {
            let paths = try matchPaths(include: include, excluding: excluding, options: options)
            var results: [File] = []
            for pathString in paths {
                let path = File.Path(__unchecked: (), pathString)
                if !File.System.Stat.isDirectory(at: path) {
                    results.append(File(path))
                }
            }
            return results
        }

        @inlinable
        public func files(
            include: [Swift.String],
            excluding: [Swift.String] = [],
            options: Glob.Options = .init()
        ) async throws(Either<Kernel.Thread.Pool.Error, Glob.Error>) -> [File] {
            let glob = self
            return try await Kernel.Thread.Pool.shared.run { () throws(Glob.Error) -> [File] in
                try glob.files(include: include, excluding: excluding, options: options)
            }
        }
    }
#endif
