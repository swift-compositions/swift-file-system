import Kernel

extension File.System.Create {

    public enum Directory {}
}

extension File.System.Create.Directory {

    public static func create(
        at path: borrowing File.Path,
        options: Options = .init(),
        createIntermediates: Bool = false
    ) throws(Self.Error) {
        let permissions = Kernel.File.Permissions(
            rawValue: options.permissions?.rawValue
                ?? File.System.Metadata.Permissions.defaultDirectory.rawValue
        )

        if createIntermediates {
            try Self.createIntermediates(at: path, permissions: permissions)
        } else {
            try mkdir(at: path, permissions: permissions)
        }
    }

    private static func mkdir(
        at path: File.Path,
        permissions: Kernel.File.Permissions
    ) throws(Self.Error) {
        do throws(Kernel.Directory.Create.Error) {
            try Kernel.Directory.Create.create(path.view, permissions: permissions)
        } catch {
            throw .mkdir(error)
        }
    }

    private static func createIntermediates(
        at path: File.Path,
        permissions: Kernel.File.Permissions
    ) throws(Self.Error) {

        let existsAsDirectory: Bool
        do throws(Kernel.File.Stats.Error) {
            let stats = try Kernel.File.Stats.get(path: path.view)
            existsAsDirectory = stats.type == .directory
        } catch {

            existsAsDirectory = false
        }

        if existsAsDirectory {
            return
        }

        if let parentPath = path.parent {
            try createIntermediates(at: parentPath, permissions: permissions)
        }

        do throws(Kernel.Directory.Create.Error) {
            try Kernel.Directory.Create.create(path.view, permissions: permissions)
        } catch {

            if case .exists = error {
                let isDir: Bool
                do throws(Kernel.File.Stats.Error) {
                    let stats = try Kernel.File.Stats.get(path: path.view)
                    isDir = stats.type == .directory
                } catch {
                    isDir = false
                }
                if isDir {
                    return
                }
            }
            throw .mkdir(error)
        }
    }
}
