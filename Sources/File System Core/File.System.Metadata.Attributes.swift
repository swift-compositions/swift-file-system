public import Kernel

extension File.System.Metadata {

    /// A file's extended attributes: named byte values the file system keeps beside its contents.
    public enum Attributes {}
}

extension File.System.Metadata.Attributes {

    public typealias Error = Kernel.File.Attributes.Extended.Error
}

extension File.System.Metadata.Attributes {

    /// The names of the attributes on the file at `path`.
    public static func list(
        at path: borrowing File.Path
    ) throws(Error) -> [Swift.String] {
        try Kernel.File.Attributes.Extended.list(path: path.view)
    }

    /// The value of the attribute `name`, or `nil` when the file has no such attribute.
    public static func get(
        _ name: Swift.String,
        at path: borrowing File.Path
    ) throws(Error) -> [Byte]? {
        do throws(Error) {
            return try Kernel.File.Attributes.Extended.get(name: name, path: path.view)
                .map(Byte.init(bitPattern:))
        } catch  where error.code == Error.notFound.code {
            return nil
        }
    }

    /// Sets the attribute `name` to `value`, replacing any value it had.
    public static func set(
        _ name: Swift.String,
        to value: borrowing Swift.Span<Byte>,
        at path: borrowing File.Path
    ) throws(Error) {
        try value.withUnsafeBytes { bytes throws(Error) in
            try unsafe Kernel.File.Attributes.Extended.set(
                name: name,
                value: bytes,
                path: path.view
            )
        }
    }

    /// Removes the attribute `name`. Removing an attribute the file does not have is not an error.
    public static func remove(
        _ name: Swift.String,
        at path: borrowing File.Path
    ) throws(Error) {
        do throws(Error) {
            try Kernel.File.Attributes.Extended.remove(name: name, path: path.view)
        } catch  where error.code == Error.notFound.code {
        }
    }
}
