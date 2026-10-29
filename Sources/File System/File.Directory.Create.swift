extension File.Directory {

    public struct Create: Sendable {

        public let path: File.Path

        @usableFromInline
        internal init(_ path: File.Path) {
            self.path = path
        }
    }
}

extension File.Directory.Create {

    @inlinable
    public func callAsFunction(
        options: File.System.Create.Directory.Options = .init()
    ) throws(File.System.Create.Directory.Error) {
        try File.System.Create.Directory.create(at: path, options: options)
    }

    @inlinable
    public func recursive(
        options: File.System.Create.Directory.Options = .init()
    ) throws(File.System.Create.Directory.Error) {
        try File.System.Create.Directory.create(
            at: path,
            options: options,
            createIntermediates: true
        )
    }
}

extension File.Directory {

    public var create: Create {
        Create(path)
    }
}
