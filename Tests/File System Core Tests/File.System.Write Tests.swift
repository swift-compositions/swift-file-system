import Kernel
import Testing

@testable import File_System_Core

enum `File.System.Write Tests` {}

extension `File.System.Write Tests` {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
        @Suite struct Integration {}
        @Suite(.serialized) struct Performance {}
    }
}

extension `File.System.Write Tests`.Test.Unit {

    @Test
    func `Write namespace exists`() {

        _ = File.System.Write.self
        _ = File.System.Write.Append.self
        _ = File.System.Write.Atomic.self
        _ = File.System.Write.Streaming.self
    }
}
