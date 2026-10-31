#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)

    import Foundation
    import Testing

    @testable import File_System_Foundation_Integration

    extension File.Ubiquitous.Status {
        @Suite struct Test {
            @Suite struct Unit {}
            @Suite struct Integration {}
        }
    }

    extension File.Ubiquitous.Status.Test.Unit {
        @Test func `an upload error names a full account, unreachable servers, or something else`() {
            let quota = NSError(domain: NSCocoaErrorDomain, code: NSUbiquitousFileNotUploadedDueToQuotaError)
            let server = NSError(domain: NSCocoaErrorDomain, code: NSUbiquitousFileUbiquityServerNotAvailable)
            let cocoa = NSError(domain: NSCocoaErrorDomain, code: NSFileReadUnknownError)
            let posix = NSError(domain: NSPOSIXErrorDomain, code: Int(ENOENT))
            #expect(File.Ubiquitous.Upload.Failure(quota) == .quota)
            #expect(File.Ubiquitous.Upload.Failure(server) == .unavailable)
            #expect(File.Ubiquitous.Upload.Failure(cocoa) == .other)
            #expect(File.Ubiquitous.Upload.Failure(posix) == .other)
            #expect(File.Ubiquitous.Upload.Failure(nil) == nil)
        }

        /// With thousands of files arriving, a query delivering on the main queue kept an app's window from drawing:
        /// every change walks all results.
        @Test func `the files are followed off the main thread, at most once a second`() {
            let query = File.Ubiquitous.Observer.query()
            #expect(query.operationQueue != nil && query.operationQueue !== OperationQueue.main)
            #expect(query.operationQueue?.maxConcurrentOperationCount == 1)
            #expect(query.notificationBatchingInterval >= 1)
        }
    }

    extension File.Ubiquitous.Status.Test.Integration {
        @Test func `the status comes at once, and a container is available only to a signed-in account`() async throws {
            var statuses = File.Ubiquitous.status().makeAsyncIterator()
            let status = try #require(await statuses.next())
            #expect(!status.isAvailable || status.isSignedIn)
        }
    }

#endif
