internal import Environment
internal import Path

extension File.Path {

    public enum Temporary: Swift.Sendable {}
}

extension File.Path.Temporary {

    public static func sibling(
        of path: File.Path,
        prefix: Swift.String,
        suffix: Swift.String = ""
    ) throws(Error) -> File.Path {
        guard let parent = path.parent else {
            throw .parent
        }

        let token: Swift.String
        do throws(File.System.Write.Error) {
            token = try File.System.Write.randomToken(length: 16)
        } catch {
            throw .random
        }

        let component: File.Path.Component
        do throws(File.Path.Component.Error) {
            component = try File.Path.Component(prefix + token + suffix)
        } catch {
            throw .component(error)
        }
        return parent / component
    }

    /// The directory the system keeps temporary files in: `TMPDIR`, else `/tmp`
    /// (`TEMP`, else `TMP`, else `C:\\Temp` on Windows).
    public static var directory: File.Path {
        get throws(File.Path.Error) {
            #if os(Windows)
                let temporaryDirectoryString: Swift.String =
                    Environment.read("TEMP") ?? Environment.read("TMP") ?? "C:\\Temp"
            #else
                let temporaryDirectoryString: Swift.String = Environment.read("TMPDIR") ?? "/tmp"
            #endif
            return try File.Path(temporaryDirectoryString)
        }
    }

    /// A path in ``directory`` that no other call names: the prefix, a random token and the suffix.
    /// Nothing is created there.
    public static func unique(
        prefix: Swift.String,
        suffix: Swift.String = ""
    ) throws(Error) -> File.Path {
        let temporaryDirectory: File.Path
        do throws(File.Path.Error) {
            temporaryDirectory = try directory
        } catch {
            throw .directory(error)
        }
        let token: Swift.String
        do throws(File.System.Write.Error) {
            token = try File.System.Write.randomToken(length: 16)
        } catch {
            throw .random
        }
        let component: File.Path.Component
        do throws(File.Path.Component.Error) {
            component = try File.Path.Component(prefix + token + suffix)
        } catch {
            throw .component(error)
        }
        return temporaryDirectory / component
    }

    public static func deterministic(
        prefix: Swift.String,
        key: Swift.String,
        suffix: Swift.String
    ) throws(File.Path.Error) -> File.Path {
        let sanitizedKey = Path.sanitized(from: key)
        let trailing = try File.Path(prefix + sanitizedKey + suffix)
        return try directory.appending(trailing)
    }
}
