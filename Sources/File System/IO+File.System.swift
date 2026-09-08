public import IO_Kernel
public import Kernel
import Memory
public import Span_Byte

extension IO.Kernel where Capabilities == File.System.IO.Capabilities {

    @inlinable
    public func open(
        _ path: borrowing File.Path,
        mode: Kernel::Kernel.File.Open.Mode
    ) async throws(File.System.IO.Error) -> Kernel::Kernel.Descriptor {
        try await capabilities.open(path, mode)
    }

    @inlinable
    public func stat(
        _ path: borrowing File.Path
    ) async throws(File.System.IO.Error) -> Kernel::Kernel.File.Stats {
        try await capabilities.stat(path)
    }

    @inlinable
    public func read(
        from fd: borrowing Kernel::Kernel.Descriptor,
        into buffer: Span.Raw.Mutable
    ) async throws(File.System.IO.Error) -> Int {
        try await capabilities.read(fd, buffer)
    }

    @inlinable
    public func write(
        to fd: borrowing Kernel::Kernel.Descriptor,
        from buffer: Span.Raw
    ) async throws(File.System.IO.Error) -> Int {
        try await capabilities.write(fd, buffer)
    }

    @inlinable
    public func close(_ fd: consuming Kernel::Kernel.Descriptor) async {
        await capabilities.close(consume fd)
    }

    @inlinable
    public var unownedExecutor: UnownedSerialExecutor {
        unsafe runner.executor()
    }
}
