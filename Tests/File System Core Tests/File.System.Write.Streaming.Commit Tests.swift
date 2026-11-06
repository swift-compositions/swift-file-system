import Kernel
import Testing

@testable import File_System_Core

enum `File.System.Write.Streaming.Commit Tests` {}

extension `File.System.Write.Streaming.Commit Tests` {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
        @Suite struct Integration {}
        @Suite(.serialized) struct Performance {}
    }
}

extension `File.System.Write.Streaming.Commit Tests`.Test.Unit {

    @Test
    func `Commit namespace exists`() {
        _ = File.System.Write.Streaming.Commit.self
        _ = File.System.Write.Streaming.Commit.Policy.self
    }
}
