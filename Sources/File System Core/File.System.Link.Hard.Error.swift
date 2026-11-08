public import Kernel

extension File.System.Link.Hard {
    public enum Error: Swift.Error, Sendable {

        case link(Kernel.Link.Error)
    }
}
