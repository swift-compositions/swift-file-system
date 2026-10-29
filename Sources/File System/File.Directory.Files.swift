extension File.Directory {

    public struct Files: Sendable {

        public let path: File.Path

        @usableFromInline
        internal init(_ path: File.Path) {
            self.path = path
        }
    }
}

extension File.Directory.Files {

    @inlinable
    public func callAsFunction() throws(File.Directory.Contents.Error) -> [File] {
        try File.Directory.Contents.list(at: File.Directory(path))
            .filter { $0.type == .file }
            .compactMap { $0.pathIfValid.map { File($0) } }
    }
}

extension File.Directory {

    public var files: Files {
        Files(path)
    }
}
