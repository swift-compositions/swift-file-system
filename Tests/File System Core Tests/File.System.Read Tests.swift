import Kernel
import Testing

@testable import File_System_Core

enum `File.System.Read Tests` {}

extension `File.System.Read Tests` {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
        @Suite struct Integration {}
        @Suite(.serialized) struct Performance {}
    }
}

extension `File.System.Read Tests`.Test.Unit {

    @Test
    func `Read namespace exists`() {

        _ = File.System.Read.self
        _ = File.System.Read.Full.self
    }
}
