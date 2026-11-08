public import Kernel
import Strings


extension File.System.Link.Read.Target {
    public enum Error: Swift.Error, Sendable {

        case stat(Kernel.File.Stats.Error)

        case readlink(Kernel.Link.Symbolic.Error)

        case notASymlink(File.Path)
    }
}
