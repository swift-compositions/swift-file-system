internal import Kernel
internal import Path

extension File.System {

    public enum Canonical {}
}

extension File.System.Canonical {

    public static func resolve(
        _ path: borrowing File.Path
    ) throws(File.System.Canonical.Error) -> File.Path {
        do throws(Path::Path.Canonical.Error) {
            return try Path::Path.Canonical.withCanonicalBytes(path.view) { bytes in
                File.Path(bytes)
            }
        } catch {
            throw .resolution(error)
        }
    }
}
