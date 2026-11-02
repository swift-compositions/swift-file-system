public import Kernel

extension File.System.Read {

    public enum Range {}
}

extension File.System.Read.Range {

    /// Up to `count` bytes of the file at `path`, from `offset`; fewer when the file ends first.
    public static func bytes(
        at path: borrowing File.Path,
        from offset: Kernel.File.Offset,
        count: Kernel.File.Size
    ) throws(Self.Error) -> [Byte] {
        let count = Int(count.underlying)
        guard count > 0 else { return [] }

        var descriptor: Kernel.Descriptor = .invalid
        do throws(Kernel.File.Open.Error) {
            descriptor = try Kernel.File.Open.open(
                path: path.view,
                mode: .read,
                options: [],
                permissions: Kernel.File.Permissions(rawValue: 0)
            )
        } catch {
            throw .open(error)
        }

        let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: count, alignment: 1)
        defer { unsafe buffer.deallocate() }

        var total = 0
        while total < count {
            guard let base = buffer.baseAddress else {
                preconditionFailure("an allocated buffer has a base address")
            }
            let slice = unsafe UnsafeMutableRawBufferPointer(start: base.advanced(by: total), count: count - total)
            do throws(Kernel.IO.Read.Error) {
                let read = try unsafe Kernel.IO.Read.pread(
                    descriptor,
                    into: slice,
                    at: Kernel.File.Offset(offset.underlying + Int64(total))
                )
                guard read > 0 else { break }
                total += read
            } catch {

                #if !os(Windows)
                    if case .platform(let kernelError) = error,
                        kernelError.code == Error::Error.Code.EINTR
                    {
                        continue
                    }
                #endif
                throw .read(error)
            }
        }

        let typed = unsafe buffer.bindMemory(to: Byte.self)
        return unsafe Array(UnsafeBufferPointer<Byte>(start: typed.baseAddress, count: total))
    }
}
