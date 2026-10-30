#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)

    import Foundation
    import Paths_Foundation_Integration

    extension File.Ubiquitous {

        /// A move through a file coordinator.
        public enum Move {}
    }

    extension File.Ubiquitous.Move {

        /// Why a coordinated move did not happen.
        public enum Error: Swift.Error, Sendable {

            /// The file coordinator refused the move, or gave a location that is not a path.
            case coordination

            /// The move itself failed.
            case move(File.System.Move.Error)
        }
    }

    extension File.Ubiquitous {

        /// Moves `source` to `destination`, or to the first free name beside it as ``File/System/Move/free(from:to:)``
        /// gives, through a file coordinator: iCloud, and any other process presenting the file, sees it move rather
        /// than disappear and reappear, and a file not yet downloaded moves without being downloaded.
        ///
        /// - Returns: Where the file is now.
        @discardableResult
        public static func move(
            from source: File.Path,
            to destination: File.Path
        ) throws(File.Ubiquitous.Move.Error) -> File.Path {
            let coordinator = NSFileCoordinator()
            var coordination: NSError?
            var moved: Result<File.Path, File.Ubiquitous.Move.Error> = .failure(.coordination)
            unsafe coordinator.coordinate(
                writingItemAt: URL(source),
                options: .forMoving,
                writingItemAt: URL(destination),
                options: [],
                error: &coordination
            ) { from, to in
                do throws(File.Path.Error) {
                    let from = try File.Path(from)
                    let to = try File.Path(to)
                    do throws(File.System.Move.Error) {
                        let placed = try File.System.Move.free(from: from, to: to)
                        coordinator.item(at: URL(from), didMoveTo: URL(placed))
                        moved = .success(placed)
                    } catch {
                        moved = .failure(.move(error))
                    }
                } catch {
                    moved = .failure(.coordination)
                }
            }
            guard coordination == nil else { throw .coordination }
            return try moved.get()
        }
    }

#endif
