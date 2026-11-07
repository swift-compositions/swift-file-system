extension File.System {

    /// The trash: a file moved there can be put back by the person, and is removed for good only when they empty it.
    ///
    /// `move(_:)` is given per platform. On Apple platforms it moves through the system's own trash, in File System
    /// Foundation Integration. On Linux it follows the XDG trash layout, into the home trash. Windows has none.
    public enum Trash {}
}

extension File.System.Trash {

    public enum Error: Swift.Error, Sendable, Equatable {

        /// Nothing is at the path.
        case missing

        /// The file may not be moved, or the trash may not be written.
        case denied

        /// No trash takes the file: none on this volume, or the path is not absolute.
        case unavailable
    }
}
