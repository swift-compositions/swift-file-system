public import Executors
public import IO_Kernel
public import Kernel

extension IO.Kernel where Capabilities == File.System.IO.Capabilities {

    public static func `default`(
        on executor: Kernel::Kernel.Thread.Executor
    ) -> IO.Kernel<File.System.IO.Capabilities> {
        #if os(Linux)
            if Kernel::Kernel.IO.Uring.isSupported {
                let proactor: Completion.Actor?
                do throws(Kernel::Kernel.Completion.Error) {
                    proactor = try Completion.Actor.shared()
                } catch {
                    proactor = nil
                }
                if let proactor {
                    return .completions(on: proactor, blockingOn: executor)
                }
            }
        #endif
        return .blocking(on: executor)
    }
}
