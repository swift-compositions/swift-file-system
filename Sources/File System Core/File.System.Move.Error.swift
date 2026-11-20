public import Kernel

extension File.System.Move {

    public enum Error: Swift.Error, Sendable {

        case destinationExists(File.Path)

        case rename(Kernel.File.Move.Error)

        case copy(File.System.Copy.Error)

        case cleanup(Kernel.File.Delete.Error)
    }
}

extension File.System.Move.Error {

    public var isSourceNotFound: Bool {
        switch self {
        case .destinationExists:
            return false

        case .rename(let e):
            return e == .notFound

        case .copy(let e):
            if case .sourceNotFound = e { return true }
            return false

        case .cleanup:
            return false
        }
    }

    public var isDestinationExists: Bool {
        switch self {
        case .destinationExists:
            return true

        case .rename:
            return false

        case .copy(let e):
            if case .destinationExists = e { return true }
            return false

        case .cleanup:
            return false
        }
    }

    public var isPermissionDenied: Bool {
        switch self {
        case .destinationExists:
            return false

        case .rename(let e):
            return e == .permission

        case .copy(let e):
            if case .permissionDenied = e { return true }
            return false

        case .cleanup(let e):
            if case .permission = e { return true }
            return false
        }
    }

    public var isCrossDevice: Bool {
        switch self {
        case .rename(let e):
            return e == .crossDevice

        default:
            return false
        }
    }

    public var isDirectory: Bool {
        switch self {
        case .rename(let e):
            return e == .isDirectory

        case .copy(let e):
            if case .isDirectory = e { return true }
            return false

        default:
            return false
        }
    }
}
