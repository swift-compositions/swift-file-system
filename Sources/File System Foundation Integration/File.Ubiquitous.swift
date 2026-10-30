#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)

    import Foundation
    import Paths_Foundation_Integration

    extension File {

        /// Files kept in iCloud: whether one is on this device, and downloading one that is not.
        public enum Ubiquitous {}
    }

    extension File.Ubiquitous {

        /// Whether the file at `path` is on this device: true for a file outside iCloud, and for one whose
        /// values cannot be read, so that reading it reports what is wrong.
        public static func local(_ path: File.Path) -> Bool {
            local(URL(path))
        }

        /// Downloads the file at `path` from iCloud, returning once it is on this device.
        ///
        /// - Parameter limit: How long to wait for the download.
        /// - Throws: ``File/Ubiquitous/Error/unavailable`` when the download cannot start,
        ///   ``File/Ubiquitous/Error/timeout`` when it is not done within `limit`, and
        ///   ``File/Ubiquitous/Error/cancelled`` when the task is cancelled while waiting.
        public static func download(
            _ path: File.Path,
            limit: Duration = .seconds(120)
        ) async throws(File.Ubiquitous.Error) {
            var url = URL(path)
            guard !local(url) else { return }
            // swift-linter:disable:next do throws for typed catch
            // REASON: FileManager.startDownloadingUbiquitousItem throws untyped; any failure to start is unavailable.
            do {
                try FileManager.default.startDownloadingUbiquitousItem(at: url)
            } catch {
                throw .unavailable
            }
            let clock = ContinuousClock()
            let deadline = clock.now.advanced(by: limit)
            while !local(url) {
                guard clock.now < deadline else { throw .timeout }
                // swift-linter:disable:next try optional
                // REASON: Task.sleep throws untyped CancellationError, its only failure; a cancelled wait is cancelled.
                guard (try? await Task.sleep(for: .milliseconds(250))) != nil else { throw .cancelled }
                url.removeAllCachedResourceValues()
            }
        }

        /// The folder of the iCloud container `identifier`, or of the app's first container when it is nil; nil
        /// while iCloud Drive is off or signed out. It may block while iCloud sets the container up, so ask for it
        /// away from the main thread.
        public static func container(_ identifier: Swift.String? = nil) -> File.Path? {
            guard let url = FileManager.default.url(forUbiquityContainerIdentifier: identifier) else { return nil }
            do throws(File.Path.Error) {
                return try File.Path(url)
            } catch {
                return nil
            }
        }

        private static func local(_ url: URL) -> Bool {
            // swift-linter:disable:next try optional
            // REASON: URL.resourceValues throws untyped; a file whose values cannot be read is treated as local, so reading it reports what is wrong.
            guard let values = try? url.resourceValues(forKeys: [.isUbiquitousItemKey, .ubiquitousItemDownloadingStatusKey]),
                values.isUbiquitousItem == true
            else { return true }
            return values.ubiquitousItemDownloadingStatus != .notDownloaded
        }
    }

#endif
