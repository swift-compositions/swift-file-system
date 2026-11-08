public import Kernel


extension File.System.Link.Symbolic {
    public enum Error: Swift.Error, Sendable {

        case symlink(Kernel.Link.Symbolic.Error)
    }
}
