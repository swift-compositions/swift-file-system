extension File.System.Write.Atomic {

    /// Writes `bytes` to `path`, or, when that name is taken, to the first free name beside it, numbered as
    /// ``File/Path/Component/numbered(_:)`` gives: `Report 2.pdf`, then `Report 3.pdf`. Each try writes with
    /// ``Strategy/noClobber``, whatever `options` asks, so nothing already there is replaced.
    ///
    /// - Returns: Where the bytes were written.
    @discardableResult
    public static func free(
        _ bytes: borrowing Swift.Span<Byte>,
        to path: File.Path,
        options: Options = Options(),
        createIntermediates: Bool = false
    ) throws(Error) -> File.Path {
        var options = options
        options.strategy = .noClobber
        guard let folder = path.parent, let name = path.components.last else {
            try write(bytes, to: path, options: options, createIntermediates: createIntermediates)
            return path
        }
        var number = 1
        while true {
            let candidate = folder / name.numbered(number)
            do throws(Error) {
                try write(bytes, to: candidate, options: options, createIntermediates: createIntermediates)
                return candidate
            } catch  where error.isDestinationExists {
                number += 1
            }
        }
    }
}
