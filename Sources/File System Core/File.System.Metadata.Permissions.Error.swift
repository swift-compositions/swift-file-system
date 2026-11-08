import Binary
public import Kernel


extension File.System.Metadata.Permissions {
    public enum Error: Swift.Error, Sendable {

        case stat(Kernel.File.Stats.Error)

        case chmod(Kernel.File.Attributes.Error)
    }
}
