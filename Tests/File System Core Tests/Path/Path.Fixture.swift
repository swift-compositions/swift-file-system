import File_System_Core

extension Path {

    enum Fixture {

        #if os(Windows)
            static let separator: Swift.String = "\\"
        #else
            static let separator: Swift.String = "/"
        #endif

        #if os(Windows)
            static let root: Swift.String = "C:\\"
        #else
            static let root: Swift.String = "/"
        #endif

        static func native(_ path: Swift.String) -> Swift.String {
            path.split(separator: "/", omittingEmptySubsequences: false).joined(separator: separator)
        }
    }
}
