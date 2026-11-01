public import Kernel
public import Path

extension Path.Component.Stem {

    public enum Error: Swift.Error, Sendable, Equatable {

        case empty

        case containsPathSeparator

        case containsControlCharacters
    }
}

extension Path.Component.Stem.Error: CustomStringConvertible {
    public var description: Swift.String {
        switch self {
        case .empty:
            return "Stem is empty"

        case .containsPathSeparator:
            return "Stem contains path separator"

        case .containsControlCharacters:
            return "Stem contains control characters"
        }
    }
}
