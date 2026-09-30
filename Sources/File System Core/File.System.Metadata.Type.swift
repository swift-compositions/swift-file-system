import Binary

extension File.System.Metadata {

    public enum Kind: Sendable {
        case regular
        case directory
        case symbolicLink
        case blockDevice
        case characterDevice
        case fifo
        case socket
    }
}

extension File.System.Metadata.Kind: RawRepresentable {
    public var rawValue: Byte {
        switch self {
        case .regular: return Byte(bitPattern: 0)
        case .directory: return Byte(bitPattern: 1)
        case .symbolicLink: return Byte(bitPattern: 2)
        case .blockDevice: return Byte(bitPattern: 3)
        case .characterDevice: return Byte(bitPattern: 4)
        case .fifo: return Byte(bitPattern: 5)
        case .socket: return Byte(bitPattern: 6)
        }
    }

    public init?(rawValue: Byte) {
        switch rawValue.bitPattern {
        case 0: self = .regular
        case 1: self = .directory
        case 2: self = .symbolicLink
        case 3: self = .blockDevice
        case 4: self = .characterDevice
        case 5: self = .fifo
        case 6: self = .socket
        default: return nil
        }
    }
}

extension File.System.Metadata.Kind: Binary.Serializable {
    @inlinable
    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        buffer.append(value.rawValue)
    }
}
