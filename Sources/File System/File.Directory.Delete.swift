extension File.Directory {

    public struct Delete: Sendable {

        public let path: File.Path

        @usableFromInline
        internal init(_ path: File.Path) {
            self.path = path
        }
    }
}

extension File.Directory.Delete {

    @inlinable
    public func callAsFunction() throws(File.System.Delete.Error) {
        try File.System.Delete.delete(at: path)
    }

    @inlinable
    public func recursive() throws(File.System.Delete.Error) {
        try File.System.Delete.delete(at: path, recursive: true)
    }

    @inlinable
    public func ifExists() throws(File.System.Delete.Error) {
        do throws(File.System.Delete.Error) {
            try File.System.Delete.delete(at: path)
        } catch {
            if error.isNotFound {
                return
            }
            throw error
        }
    }
}

extension File.Directory {

    public var delete: Delete {
        Delete(path)
    }
}
