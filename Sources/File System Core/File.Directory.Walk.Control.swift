extension File.Directory.Walk {

    /// What the walk does after visiting an entry.
    public enum Control: Sendable {

        /// Go on, descending into the entry when it is a directory.
        case `continue`

        /// Go on without descending into the entry: its subtree is left out.
        /// For an entry that is not a directory this is the same as `continue`.
        case skip

        /// Stop the walk.
        case `break`
    }
}
