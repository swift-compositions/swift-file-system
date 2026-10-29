extension File {

    public struct Copy: Sendable {

        public let path: File.Path

        @usableFromInline
        internal init(_ path: File.Path) {
            self.path = path
        }
    }
}

extension File.Copy {

    @discardableResult
    @inlinable
    public func to(
        _ destination: File.Path,
        options: File.System.Copy.Options = .init()
    ) throws(File.System.Copy.Error) -> File {
        try File.System.Copy.copy(from: path, to: destination, options: options)
        return File(destination)
    }

    @discardableResult
    @inlinable
    public func to(
        _ destination: File,
        options: File.System.Copy.Options = .init()
    ) throws(File.System.Copy.Error) -> File {
        try File.System.Copy.copy(from: path, to: destination.path, options: options)
        return destination
    }
}

extension File {

    public var copy: Copy {
        Copy(path)
    }
}
