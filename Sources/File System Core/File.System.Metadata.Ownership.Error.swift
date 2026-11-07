import Binary
public import Kernel


extension File.System.Metadata.Ownership {
    public enum Error: Swift.Error, Sendable {

        case stat(Kernel.File.Stats.Error)

        case chown(Kernel.File.Chown.Error)
    }
}
