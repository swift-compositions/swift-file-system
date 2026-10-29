#if IO
    #if !os(Windows)

        public import IO_Kernel

        extension Completion.Failure {

            @usableFromInline
            package var fileSystemError: File.System.IO.Error {
                switch self {
                case .cancelled:
                    return .cancelled

                case .invalidDescriptor:
                    return .platform(.EBADF)

                case .tooManyOpen:
                    return .platform(.EMFILE)

                case .platform(let code):
                    return .platform(code)

                case .kernel:
                    return .platform(.EIO)
                }
            }
        }

    #endif
#endif
