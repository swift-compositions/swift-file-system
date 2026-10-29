extension File.Directory {

    public struct Entries: Sendable {

        public let path: File.Path

        @usableFromInline
        internal init(_ path: File.Path) {
            self.path = path
        }
    }
}

extension File.Directory.Entries {

    @inlinable
    public func callAsFunction() throws(File.Directory.Contents.Error) -> [File.Directory.Entry] {
        try File.Directory.Contents.list(at: File.Directory(path))
    }
}

extension File.Directory {

    public var entries: Entries {
        Entries(path)
    }
}
