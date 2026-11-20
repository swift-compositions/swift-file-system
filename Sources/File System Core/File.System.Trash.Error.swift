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
