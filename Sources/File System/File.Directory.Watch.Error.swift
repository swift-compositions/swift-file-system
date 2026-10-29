#if Watch
    #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)

        public import Kernel

        extension File.Directory.Watch {

            public enum Error: Swift.Error, Sendable, Equatable {

                /// The event source could not be created or polled.
                case source(Kernel.Event.Driver.Error)

                /// A directory could not be opened for watching.
                case open(File.Path, Kernel.File.Open.Error)

                /// The watched directory could not be listed.
                case list(File.Path, File.Directory.Contents.Error)

                /// Watching another directory would pass `Options.limit`.
                case limit(Int)

                /// The watched directory itself was deleted, renamed or revoked.
                case removed(File.Path)
            }
        }

    #endif
#endif
