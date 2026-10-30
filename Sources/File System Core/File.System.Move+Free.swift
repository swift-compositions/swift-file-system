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
