#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)

    import Foundation
    import Paths_Foundation_Integration

    extension File.System.Trash {

        /// Moves the file or folder at `path` to the trash of its volume, as Finder does, so the person can put it
        /// back from there.
        ///
        /// - Returns: Where the item now is, in the trash.
        @discardableResult
        public static func move(_ path: File.Path) throws(File.System.Trash.Error) -> File.Path {
            guard File.System.Stat.exists(at: path) else { throw .missing }
            var trashed: NSURL?
            // swift-linter:disable:next do throws for typed catch
            // REASON: FileManager.trashItem throws untyped; its Cocoa code says which of the three failures it was.
            do {
                try unsafe FileManager.default.trashItem(at: URL(path), resultingItemURL: &trashed)
            } catch {
                switch (error as NSError).code {
                case CocoaError.fileNoSuchFile.rawValue: throw .missing
                case CocoaError.fileWriteNoPermission.rawValue, CocoaError.fileReadNoPermission.rawValue: throw .denied
                default: throw .unavailable
                }
            }
            guard let url = trashed as URL? else { throw .unavailable }
            do throws(File.Path.Error) {
                return try File.Path(url)
            } catch {
                throw .unavailable
            }
        }
    }

#endif
