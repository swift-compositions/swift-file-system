public import Kernel

extension File.System.Write {

    public enum Append {}
}

extension File.System.Write.Append {

    public static func append<S: Binary.Serializable>(
        _ value: S,
        to path: borrowing File.Path,
        options: File.System.Create.Options = .init()
    ) throws(Self.Error) {
        try S.withSerializedBytes(value) {
            (span: borrowing Swift.Span<Byte>) throws(Self.Error) in
            try append(span, to: path, options: options)
        }
    }

}

extension File.System.Write.Append.Error: CustomStringConvertible {
    public var description: Swift.String {
        switch self {
        case .open(let error):
            return "Open failed: \(error)"

        case .write(let error):
            return "Write failed: \(error)"

        case .shortWrite(let written, let expected):
            return "Short write: wrote \(written) of \(expected) bytes, write() returned 0"
        }
    }
}
