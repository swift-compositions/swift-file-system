public import Kernel

extension File.System.Delete {

    public enum Error: Swift.Error, Sendable {

        case stat(Kernel.File.Stats.Error)

        case unlink(Kernel.File.Delete.Error)

        case rmdir(Kernel.Directory.Remove.Error)

        case directory(Kernel.Directory.Error)
    }
}

extension File.System.Delete.Error {

    public var isNotFound: Bool {
        switch self {
        case .stat(let e):
            if case .platform(let p) = e, p.code.isNotFound { return true }
            return false

        case .unlink(let e):
            if case .notFound = e { return true }
            return false

        case .rmdir(let e):
            return e == .notFound

        case .directory(let e):
            return e == .notFound
        }
    }

    public var isPermissionDenied: Bool {
        switch self {
        case .stat(let e):
            if case .platform(let p) = e, p.code.isPermissionDenied { return true }
            return false

        case .unlink(let e):
            if case .permission = e { return true }
            return false

        case .rmdir(let e):
            return e == .permission

        case .directory(let e):
            return e == .permission
        }
    }

    public var isDirectory: Bool {
        switch self {
        case .unlink(let e):
            if case .isDirectory = e { return true }
            return false

        default:
            return false
        }
    }

    public var isDirectoryNotEmpty: Bool {
        switch self {
        case .rmdir(let e):
            return e == .notEmpty

        default:
            return false
        }
    }
}
