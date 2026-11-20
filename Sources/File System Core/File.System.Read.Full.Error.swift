public import Kernel

extension File.System.Read.Full {

    public enum Error: Swift.Error, Sendable {

        case open(Kernel.File.Open.Error)

        case stat(Kernel.File.Stats.Error)

        case read(Kernel.IO.Read.Error)

        case isDirectory(File.Path)
    }
}

extension File.System.Read.Full.Error {

    public var isNotFound: Bool {
        switch self {
        case .open(let e):
            if case .path(.notFound) = e { return true }
            return false

        default:
            return false
        }
    }

    public var isPermissionDenied: Bool {
        switch self {
        case .open(let e):
            if case .platform(let p) = e, p.code.isPermissionDenied { return true }
            return false

        default:
            return false
        }
    }

    public var isDirectory: Bool {
        switch self {
        case .isDirectory:
            return true

        case .open(let e):
            if case .path(.isDirectory) = e { return true }
            return false

        default:
            return false
        }
    }

    public var isTooManyOpenFiles: Bool {
        switch self {
        case .open(let e):
            if case .handle(.limit) = e { return true }
            return false

        default:
            return false
        }
    }
}
