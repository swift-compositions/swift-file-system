#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)

    extension File.Ubiquitous {

        /// Why a file in iCloud could not be downloaded.
        public enum Error: Swift.Error, Equatable, Sendable {

            /// The download could not start: the device is offline, or the file is not in iCloud's reach.
            case unavailable

            /// The download did not finish within its limit.
            case timeout

            /// The task was cancelled while waiting for the download.
            case cancelled
        }
    }

#endif
