#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)

    extension File.Ubiquitous {

        /// Where iCloud stands for a container's documents: whether the person is signed in, whether the container is
        /// there, and whether each file in it has reached iCloud.
        public struct Status: Equatable, Sendable {

            /// Whether an iCloud account is signed in on this device.
            public var isSignedIn: Bool

            /// Whether the container is there, which needs an account and iCloud Drive on.
            public var isAvailable: Bool

            /// Each file in the container's Documents, in no particular order.
            public var uploads: [File.Ubiquitous.Upload]

            public init(isSignedIn: Bool, isAvailable: Bool, uploads: [File.Ubiquitous.Upload]) {
                self.isSignedIn = isSignedIn
                self.isAvailable = isAvailable
                self.uploads = uploads
            }
        }
    }

#endif
