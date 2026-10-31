#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)

    public import Foundation

    extension File.Ubiquitous {

        /// One file in iCloud: whether it has reached iCloud, and why not when its upload failed.
        public struct Upload: Hashable, Sendable {

            /// Whether the file has reached iCloud.
            public var isUploaded: Bool

            /// Why the upload failed, or nil while it has not.
            public var failure: File.Ubiquitous.Upload.Failure?

            public init(isUploaded: Bool, failure: File.Ubiquitous.Upload.Failure? = nil) {
                self.isUploaded = isUploaded
                self.failure = failure
            }
        }
    }

    extension File.Ubiquitous.Upload {

        /// Why a file did not reach iCloud.
        public enum Failure: Hashable, Sendable {

            /// The account's iCloud storage is full.
            case quota

            /// iCloud's servers could not be reached.
            case unavailable

            /// Anything else.
            case other

            /// The failure an upload error names; nil for no error.
            public init?(_ error: NSError?) {
                guard let error else { return nil }
                guard error.domain == NSCocoaErrorDomain else {
                    self = .other
                    return
                }
                self =
                    switch error.code {
                    case NSUbiquitousFileNotUploadedDueToQuotaError: .quota
                    case NSUbiquitousFileUbiquityServerNotAvailable: .unavailable
                    default: .other
                    }
            }
        }
    }

#endif
