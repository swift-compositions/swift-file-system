public import Kernel
public import Path

extension Path.Component.Extension {

    public enum Error: Swift.Error, Sendable, Equatable {

        case empty

        case containsDot

        case containsPathSeparator

        case containsControlCharacters
    }
}

extension Path.Component.Extension.Error: CustomStringConvertible {
    public var description: Swift.String {
        switch self {
        case .empty:
            return "Extension is empty"

        case .containsDot:
            return "Extension contains dot"

        case .containsPathSeparator:
            return "Extension contains path separator"

        case .containsControlCharacters:
            return "Extension contains control characters"
        }
    }
}
