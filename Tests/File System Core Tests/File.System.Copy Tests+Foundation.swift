#if canImport(Darwin) && canImport(Foundation)
import Foundation

enum CopyFixture {

    static func createDirectory(_ path: Swift.String) throws {
        try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: false)
    }

    static func exists(_ path: Swift.String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }

    static func link(_ path: Swift.String, to target: Swift.String) throws {
        try FileManager.default.createSymbolicLink(atPath: path, withDestinationPath: target)
    }

    static func contents(_ path: Swift.String) throws -> [UInt8] {
        [UInt8](try Data(contentsOf: URL(fileURLWithPath: path)))
    }

    static func isSymbolicLink(_ path: Swift.String) throws -> Bool {
        try FileManager.default.attributesOfItem(atPath: path)[.type] as? FileAttributeType == .typeSymbolicLink
    }

    static func destination(_ path: Swift.String) throws -> Swift.String {
        try FileManager.default.destinationOfSymbolicLink(atPath: path)
    }

    static func setPermissions(_ permissions: Int, _ path: Swift.String) throws {
        try FileManager.default.setAttributes([.posixPermissions: permissions], ofItemAtPath: path)
    }

    static func setModification(_ secondsSince1970: Double, _ path: Swift.String) throws {
        try FileManager.default.setAttributes(
            [.modificationDate: Date(timeIntervalSince1970: secondsSince1970)],
            ofItemAtPath: path
        )
    }

    static func permissions(_ path: Swift.String) throws -> Int? {
        try FileManager.default.attributesOfItem(atPath: path)[.posixPermissions] as? Int
    }

    static func modification(_ path: Swift.String) throws -> Double? {
        (try FileManager.default.attributesOfItem(atPath: path)[.modificationDate] as? Date)?.timeIntervalSince1970
    }

    static func now() -> Double {
        Date().timeIntervalSince1970
    }
}
#endif
