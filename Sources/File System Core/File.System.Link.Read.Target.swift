public import Kernel
import Strings

extension File.System.Link.Read {

    public enum Target {}
}

extension File.System.Link.Read.Target {
}

extension File.System.Link.Read.Target.Error {

    public var isNotFound: Bool {
        switch self {
        case .stat(let e):
            if case .platform(let p) = e, p.code.isNotFound { return true }
            return false

        case .readlink(let e):
            return e == .notFound

        default:
            return false
        }
    }

    public var isPermissionDenied: Bool {
        switch self {
        case .stat(let e):
            if case .platform(let p) = e, p.code.isPermissionDenied { return true }
            return false

        case .readlink(let e):
            return e == .permission

        default:
            return false
        }
    }

    public var isNotASymlink: Bool {
        switch self {
        case .notASymlink:
            return true

        case .readlink(let e):
            return e == .notSymbolicLink

        default:
            return false
        }
    }
}

extension File.System.Link.Read.Target {

    public static func target(
        of path: borrowing File.Path
    ) throws(Self.Error) -> File.Path {

        let stats: Kernel.File.Stats
        do throws(Kernel.File.Stats.Error) {
            stats = try Kernel.File.Stats.lget(path: path.view)
        } catch {
            throw .stat(error)
        }

        guard case .link = stats.type else {
            throw .notASymlink(copy path)
        }

        do throws(Kernel.Link.Symbolic.Error) {
            let target = try Kernel.Link.Symbolic.readTarget(at: path.view)
            return File.Path(copying: target.view)
        } catch {
            throw .readlink(error)
        }
    }
}

extension File.System.Link.Read.Target.Error: CustomStringConvertible {
    public var description: Swift.String {
        switch self {
        case .stat(let error):
            return "Stat failed: \(error)"

        case .readlink(let error):
            return "Readlink failed: \(error)"

        case .notASymlink(let path):
            return "Not a symbolic link: \(path)"
        }
    }
}
