#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)

    import Foundation

    extension File.Ubiquitous {

        /// Where iCloud stands for the container `identifier`, or the app's first container when it is nil: first now,
        /// then each time it changes. The files are followed on a queue of their own, never the main thread, at most
        /// once a second, since every change walks all of them.
        public static func status(_ identifier: Swift.String? = nil) -> AsyncStream<File.Ubiquitous.Status> {
            AsyncStream { continuation in
                let observer = Observer(identifier) { continuation.yield($0) }
                observer.start()
                continuation.onTermination = { _ in observer.stop() }
            }
        }
    }

    extension File.Ubiquitous {

        /// Follows a container's Documents through a metadata query on a serial queue of its own.
        final class Observer: @unchecked Sendable {
            // `query`, `observations` and `last` are touched only on `queue`, which runs one operation at a time.
            let queue: OperationQueue
            let identifier: Swift.String?
            let yield: @Sendable (File.Ubiquitous.Status) -> Void
            private var query: NSMetadataQuery?
            private var observations: [any NSObjectProtocol] = []
            private var last: File.Ubiquitous.Status?

            init(_ identifier: Swift.String?, yield: @escaping @Sendable (File.Ubiquitous.Status) -> Void) {
                self.identifier = identifier
                self.yield = yield
                queue = Self.queue()
            }
        }
    }

    extension File.Ubiquitous.Observer {

        static func queue() -> OperationQueue {
            let queue = OperationQueue()
            queue.name = "File.Ubiquitous.status"
            queue.maxConcurrentOperationCount = 1
            queue.qualityOfService = .utility
            return queue
        }

        /// Every file in the container's Documents, delivered on `queue` at most once a second.
        static func query(on queue: OperationQueue = queue()) -> NSMetadataQuery {
            let query = NSMetadataQuery()
            query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
            query.predicate = NSPredicate(format: "%K LIKE '*'", NSMetadataItemFSNameKey)
            query.operationQueue = queue
            query.notificationBatchingInterval = 1
            return query
        }

        func start() {
            queue.addOperation { [self] in
                let center = NotificationCenter.default
                observations.append(
                    center.addObserver(forName: .NSUbiquityIdentityDidChange, object: nil, queue: queue) { [weak self] _ in
                        self?.refresh()
                    }
                )
                let query = Self.query(on: queue)
                for name in [Notification.Name.NSMetadataQueryDidFinishGathering, .NSMetadataQueryDidUpdate] {
                    observations.append(
                        center.addObserver(forName: name, object: query, queue: queue) { [weak self] _ in
                            self?.refresh()
                        }
                    )
                }
                self.query = query
                query.start()
                refresh()
            }
        }

        func stop() {
            queue.addOperation { [self] in
                query?.stop()
                observations.forEach(NotificationCenter.default.removeObserver)
                observations = []
            }
        }

        private func refresh() {
            let isSignedIn = FileManager.default.ubiquityIdentityToken != nil
            let isAvailable = isSignedIn && FileManager.default.url(forUbiquityContainerIdentifier: identifier) != nil
            var uploads: [File.Ubiquitous.Upload] = []
            if let query {
                query.disableUpdates()
                for case let item as NSMetadataItem in query.results {
                    uploads.append(
                        File.Ubiquitous.Upload(
                            isUploaded: (item.value(forAttribute: NSMetadataUbiquitousItemIsUploadedKey) as? Bool) ?? true,
                            failure: File.Ubiquitous.Upload.Failure(item.value(forAttribute: NSMetadataUbiquitousItemUploadingErrorKey) as? NSError)
                        )
                    )
                }
                query.enableUpdates()
            }
            let status = File.Ubiquitous.Status(isSignedIn: isSignedIn, isAvailable: isAvailable, uploads: uploads)
            guard status != last else { return }
            last = status
            yield(status)
        }
    }

#endif
