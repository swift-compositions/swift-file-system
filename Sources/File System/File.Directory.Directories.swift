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
