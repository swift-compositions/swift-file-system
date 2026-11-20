public import Kernel

extension File.Directory.Iterator {

    public enum Error: Swift.Error, Sendable {

        case directory(Kernel.Directory.Error)
    }
}

extension File.Directory.Iterator.Error {

    public var isNotFound: Bool {
        if case .directory(let e) = self {
            return e == .notFound
        }
        return false
    }

    public var isPermissionDenied: Bool {
        if case .directory(let e) = self {
            return e == .permission
        }
        return false
    }

    public var isNotADirectory: Bool {
        if case .directory(let e) = self {
            return e == .notDirectory
        }
        return false
    }

    public var isTooManyOpenFiles: Bool {
        if case .directory(let e) = self {
            return e == .tooManyOpenFiles
        }
        return false
    }
}
