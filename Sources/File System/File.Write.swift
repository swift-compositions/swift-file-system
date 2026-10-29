extension File {

    public struct Write: Sendable {

        public let path: File.Path

        @usableFromInline
        internal init(_ path: File.Path) {
            self.path = path
        }
    }
}

extension File.Write {

    @inlinable
    public func atomic(
        _ bytes: borrowing Swift.Span<Byte>,
        options: File.System.Write.Atomic.Options = .init()
    ) throws(File.System.Write.Atomic.Error) {
        try File.System.Write.Atomic.write(bytes, to: path, options: options)
    }

    @inlinable
    public func atomic(
        _ string: Swift.String,
        options: File.System.Write.Atomic.Options = .init()
    ) throws(File.System.Write.Atomic.Error) {
        let utf8 = [Byte](utf8: string)
        try atomic(utf8.span, options: options)
    }

    @inlinable
    public func atomic<S: Swift.Sequence>(
        contentsOf bytes: S,
        options: File.System.Write.Atomic.Options = .init()
    ) throws(File.System.Write.Atomic.Error) where S.Element == Byte {
        let array = Array(bytes)
        try atomic(array.span, options: options)
    }

    @inlinable
    public func append(_ bytes: borrowing Swift.Span<Byte>) throws(File.System.Write.Append.Error) {
        try File.System.Write.Append.append(bytes, to: path)
    }

    @inlinable
    public func append(_ string: Swift.String) throws(File.System.Write.Append.Error) {
        let utf8 = [Byte](utf8: string)
        try append(utf8.span)
    }

    @inlinable
    public func streaming<Chunks: Swift.Sequence>(
        _ chunks: Chunks,
        options: File.System.Write.Streaming.Options = .init()
    ) throws(File.System.Write.Streaming.Error) where Chunks.Element == [Byte] {
        try File.System.Write.Streaming.write(chunks, to: path, options: options)
    }
}

extension File {

    public var write: File.Write {
        Self.Write(path)
    }
}
