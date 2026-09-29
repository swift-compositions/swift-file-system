#if os(Linux)

    public import Executors
    public import IO_Kernel
    public import Kernel
    public import Memory
    public import Span
    public import Thread_Actor

    extension IO.Kernel where Capabilities == File.System.IO.Capabilities {

        public static func completions(
            on completion: Completion.Actor,
            blockingOn executor: Kernel::Kernel.Thread.Executor
        ) -> IO.Kernel<File.System.IO.Capabilities> {
            let thread = Kernel::Kernel.Thread.Actor(executor: executor)
            let capabilities = File.System.IO.Capabilities(
                open: { path, mode throws(File.System.IO.Error) in
                    try await thread.open(path, mode: mode)
                },
                close: { fd in
                    await thread.close(consume fd)
                },
                read: { fd, buf throws(File.System.IO.Error) -> Int in
                    let raw = unsafe buf.base.nonNull
                    let descriptor: Kernel::Kernel.Descriptor?
                    do throws(Kernel::Kernel.Descriptor.Duplicate.Error) {
                        descriptor = try Kernel::Kernel.Descriptor.Duplicate.duplicate(fd)
                    } catch {
                        throw .platform(error.code)
                    }
                    let address = unsafe Memory.Address(raw.baseAddress!)
                    let length: Memory.Address.Count = buf.count.retag(Memory.self)
                    do throws(Completion.Failure) {
                        return try await completion.submit(
                            .read(address: address, length: length, offset: nil),
                            descriptor: consume descriptor
                        ) { event throws(Completion.Failure) in
                            if let error = event.result.failure {
                                throw error.completionFailure
                            }
                            return Int(event.result.value!)
                        }
                    } catch {
                        throw error.fileSystemError
                    }
                },
                write: { fd, buf throws(File.System.IO.Error) -> Int in
                    let raw = unsafe buf.base.nonNull
                    let descriptor: Kernel::Kernel.Descriptor?
                    do throws(Kernel::Kernel.Descriptor.Duplicate.Error) {
                        descriptor = try Kernel::Kernel.Descriptor.Duplicate.duplicate(fd)
                    } catch {
                        throw .platform(error.code)
                    }
                    let address = unsafe Memory.Address(raw.baseAddress!)
                    let length: Memory.Address.Count = buf.count.retag(Memory.self)
                    do throws(Completion.Failure) {
                        return try await completion.submit(
                            .write(address: address, length: length, offset: nil),
                            descriptor: consume descriptor
                        ) { event throws(Completion.Failure) in
                            if let error = event.result.failure {
                                throw error.completionFailure
                            }
                            return Int(event.result.value!)
                        }
                    } catch {
                        throw error.fileSystemError
                    }
                },
                stat: { path throws(File.System.IO.Error) in
                    try await thread.stat(path)
                }
            )
            let runner = unsafe Self.Runner(
                executor: { completion.unownedExecutor },
                shutdown: {}
            )
            return IO.Kernel(capabilities: capabilities, runner: runner)
        }
    }

#endif
