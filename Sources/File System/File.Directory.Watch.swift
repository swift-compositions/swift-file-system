#if Watch
    #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)

        extension File.Directory {

            /// A directory tree watched for changes: an asynchronous sequence of the directories whose
            /// entries changed, so a caller rescans only those.
            ///
            /// Iteration first yields every directory the watch covers, the root included, so one loop
            /// both processes the tree in full and then keeps up with it. After that it yields a
            /// directory each time an entry in it is added, removed or renamed, which includes a file
            /// saved by writing a new copy and renaming it over the old one. A file edited in place is
            /// not reported: that would take a descriptor per file.
            ///
            /// Subdirectories are watched as they appear and dropped as they go; a new subdirectory is
            /// yielded once it is watched, since files may already be in it. One the process may not
            /// open or list is left out with its subtree, and the watch goes on. Hidden entries and
            /// symbolic links are never followed out of the tree; `Options.descend` leaves out any
            /// other subdirectory, such as `node_modules`, `.build` or a package.
            ///
            /// Each watched directory holds one descriptor, opened with `O_EVTONLY` so it neither
            /// keeps a volume busy nor needs more than the sandbox's read access to the folder. The
            /// descriptors count against the process's `RLIMIT_NOFILE`, which on macOS is 256 for an
            /// app unless it raises it, so `Options.limit` caps the watch and the sequence throws
            /// `Error.limit` past it rather than starve the process of descriptors. An app watching a
            /// large tree raises its own limit first, up to its hard limit:
            ///
            /// ```swift
            /// var limit = try Kernel.Resource.Limit.get(.descriptors)
            /// limit.current = limit.maximum
            /// try Kernel.Resource.Limit.set(limit, for: .descriptors)
            /// ```
            ///
            /// Cancelling the consuming task, or leaving the loop, ends the watch and closes every
            /// descriptor it opened. The watch runs on a thread of its own, which blocks in kqueue.
            ///
            /// Darwin only: on Linux this needs inotify, which is not yet wrapped.
            public struct Watch: Sendable {

                public let path: File.Path

                public let options: Options

                public init(_ directory: File.Directory, options: Options = Options()) {
                    self.path = directory.path
                    self.options = options
                }
            }
        }

        extension File.Directory {

            public func watch(options: File.Directory.Watch.Options = .init()) -> File.Directory.Watch {
                File.Directory.Watch(self, options: options)
            }
        }

        extension File.Directory.Watch: AsyncSequence {

            public typealias Element = File.Directory

            public typealias Failure = File.Directory.Watch.Error

            public func makeAsyncIterator() -> Iterator {
                Iterator(path: path, options: options)
            }
        }

    #endif
#endif
