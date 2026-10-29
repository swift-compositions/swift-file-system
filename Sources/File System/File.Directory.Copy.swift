public import Kernel

extension File.Directory {

    public struct Copy: Sendable {

        public let path: File.Path

        @usableFromInline
        internal init(_ path: File.Path) {
            self.path = path
        }
    }
}

extension File.Directory.Copy {

    @discardableResult
    @inlinable
    public func to(
        _ destination: File.Path,
        options: File.System.Copy.Options = .init()
    ) throws(File.System.Copy.Error) -> File.Directory {
        try File.System.Copy.recursive(from: path, to: destination, options: options)
        return File.Directory(destination)
    }

    @discardableResult
    @inlinable
    public func to(
        _ destination: File.Directory,
        options: File.System.Copy.Options = .init()
    ) throws(File.System.Copy.Error) -> File.Directory {
        try File.System.Copy.recursive(from: path, to: destination.path, options: options)
        return destination
    }
}

extension File.Directory {

    public var copy: Copy {
        Copy(path)
    }
}
