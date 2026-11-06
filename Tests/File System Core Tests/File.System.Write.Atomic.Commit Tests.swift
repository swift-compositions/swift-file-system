import Kernel
import Testing

@testable import File_System_Core

enum `File.System.Write.Atomic.Commit Tests` {}

extension `File.System.Write.Atomic.Commit Tests` {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
        @Suite struct Integration {}
        @Suite(.serialized) struct Performance {}
    }
}

extension `File.System.Write.Atomic.Commit Tests`.Test.Unit {

    @Test
    func `Commit namespace exists`() {
        _ = File.System.Write.Atomic.Commit.self
        _ = File.System.Write.Atomic.Commit.Phase.self
    }
}
