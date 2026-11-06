import Kernel
import Testing

@testable import File_System_Core

enum `File.System.Metadata Tests` {}

extension `File.System.Metadata Tests` {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
        @Suite struct Integration {}
        @Suite(.serialized) struct Performance {}
    }
}

extension `File.System.Metadata Tests`.Test.Unit {

    @Test
    func `Metadata namespace exists`() {

        _ = File.System.Metadata.Kind.self
        _ = File.System.Metadata.Permissions.self
        _ = File.System.Metadata.Ownership.self
        _ = File.System.Metadata.Info.self
    }
}
