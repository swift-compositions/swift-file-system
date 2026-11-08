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
        func matchPaths(
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
        func matchPaths(
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
