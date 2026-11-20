extension File.System.Move {

    public struct Options: Sendable {

        public var overwrite: Bool

        public init(overwrite: Bool = false) {
            self.overwrite = overwrite
        }
    }
}
