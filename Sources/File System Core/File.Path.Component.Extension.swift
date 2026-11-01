public import Kernel
public import Path

extension Path.Component {

    public struct Extension: Copyable, Sendable, Hashable {

        @usableFromInline
        internal let _value: Swift.String

        @inlinable
        public init(_ string: Swift.String) throws(Error) {
            guard !string.isEmpty else {
                throw .empty
            }

            for scalar in string.unicodeScalars {
                let value = scalar.value

                if scalar == "." {
                    throw .containsDot
                }

                #if os(Windows)
                    if scalar == "/" || scalar == "\\" {
                        throw .containsPathSeparator
                    }
                #else
                    if scalar == "/" {
                        throw .containsPathSeparator
                    }
                #endif

                if value < 0x20 || value == 0x7F {
                    throw .containsControlCharacters
                }
            }

            self._value = string
        }

        @usableFromInline
        internal init(unchecked value: Swift.String) {
            self._value = value
        }
    }
}

extension Path.Component.Extension {

    @inlinable
    public var string: Swift.String {
        _value
    }
}

extension Swift.String {

    @inlinable
    public init(_ ext: Path.Component.Extension) {
        self = ext.string
    }
}

extension Path.Component.Extension: CustomStringConvertible {
    public var description: Swift.String {
        string
    }
}

extension Path.Component.Extension: CustomDebugStringConvertible {
    public var debugDescription: Swift.String {
        "Path.Component.Extension(\"\(string)\")"
    }
}

extension Path.Component.Extension: ExpressibleByStringLiteral {

    @inlinable
    public init(stringLiteral value: Swift.String) {
        do {
            try self.init(value)
        } catch {
            fatalError("Invalid extension literal: \(value) (\(error))")
        }
    }
}
