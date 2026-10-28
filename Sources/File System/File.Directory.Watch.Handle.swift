#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)

    import Kernel

    extension File.Directory.Watch {

        /// The kqueue event source of one watch. Releasing the handle closes the queue and the
        /// descriptor of every directory still registered with it.
        internal final class Handle {

            internal let source: Kernel.Event.Source

            internal init(source: consuming Kernel.Event.Source) {
                self.source = source
            }
        }
    }

#endif
