public import Kernel

extension File.System.Read.Range {

    public enum Error: Swift.Error, Sendable {

        case open(Kernel.File.Open.Error)

        case read(Kernel.IO.Read.Error)
    }
}

extension File.System.Read.Range.Error {

    public var isNotFound: Bool {
        switch self {
        case .open(let e):
            if case .path(.notFound) = e { return true }
            return false

        case .read:
            return false
        }
    }
}

extension File.System.Read.Range.Error: CustomStringConvertible {
    public var description: Swift.String {
        switch self {
        case .open(let error):
            return "Open failed: \(error)"

        case .read(let error):
            return "Read failed: \(error)"
        }
    }
}
