public import Kernel

extension File.Handle.Open {
    public enum Error<ClosureError: Swift.Error>: Swift.Error, Sendable {

        case open(Kernel.File.Open.Error)

        case operation(ClosureError)

        case close(Kernel.Close.Error)
    }
}
