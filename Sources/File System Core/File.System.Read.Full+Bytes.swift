import Either

extension File.System.Read.Full {

    /// The whole file at `path`, as bytes.
    public static func bytes(at path: borrowing File.Path) throws(Error) -> [Byte] {
        do throws(Either<Error, Never>) {
            return try read(from: path) { span in span.withUnsafeBufferPointer { unsafe [Byte]($0) } }
        } catch {
            switch error {
            case .left(let error): throw error
            case .right(let never): switch never {}
            }
        }
    }
}
