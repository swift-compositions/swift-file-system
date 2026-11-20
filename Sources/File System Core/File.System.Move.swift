public import Kernel

extension File.System {

    public enum Move {}
}

extension File.System.Move {

    public static func move(
        from source: borrowing File.Path,
        to destination: borrowing File.Path,
        options: borrowing Options = .init()
    ) throws(Self.Error) {

        let overwrite = options.overwrite
        do throws(Kernel.File.Move.Error) {
            if overwrite {
                try Kernel.File.Move.move(from: source.view, to: destination.view)
            } else {
                try Kernel.File.Move.exclusive(from: source.view, to: destination.view)
            }
        } catch {

            if case .exists = error {
                throw .destinationExists(copy destination)
            }
            if case .crossDevice = error {
                try copyAndDelete(from: source, to: destination, options: options)
                return
            }
            throw .rename(error)
        }
    }

    private static func copyAndDelete(
        from source: File.Path,
        to destination: File.Path,
        options: Options
    ) throws(Self.Error) {

        let copyOptions = File.System.Copy.Options(
            overwrite: options.overwrite,
            copyAttributes: true,
            followSymlinks: true
        )

        do throws(File.System.Copy.Error) {
            try File.System.Copy.copy(from: source, to: destination, options: copyOptions)
        } catch {
            throw .copy(error)
        }

        do throws(Kernel.File.Delete.Error) {
            try Kernel.File.Delete.delete(source.view)
        } catch {
            throw .cleanup(error)
        }
    }

}

extension File.System.Move.Error: CustomStringConvertible {
    public var description: Swift.String {
        switch self {
        case .destinationExists(let path):
            return "Destination already exists: \(path)"

        case .rename(let error):
            return "Rename failed: \(error)"

        case .copy(let error):
            return "Copy failed (cross-device): \(error)"

        case .cleanup(let error):
            return "Source cleanup failed after copy: \(error)"
        }
    }
}

extension File.System.Move {

    /// Moves `source` to `destination`, or, when that name is taken, to the first free name beside it, numbered as
    /// ``File/Path/Component/numbered(_:)`` gives: `Report 2.pdf`, then `Report 3.pdf`. Each try is an exclusive
    /// rename, so a file another process puts at one of those names in between is never replaced.
    ///
    /// - Returns: Where the file is now. A source that already has one of those names stays where it is.
    @discardableResult
    public static func free(from source: File.Path, to destination: File.Path) throws(Error) -> File.Path {
        guard let folder = destination.parent, let name = destination.components.last else {
            try move(from: source, to: destination)
            return destination
        }
        var number = 1
        while true {
            let candidate = folder / name.numbered(number)
            guard candidate != source else { return candidate }
            do throws(Error) {
                try move(from: source, to: candidate)
                return candidate
            } catch  where error.isDestinationExists {
                number += 1
            }
        }
    }
}
