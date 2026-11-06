import Kernel
import Testing

@testable import File_System_Core

enum `File.System.Write.Streaming.Atomic Tests` {}

extension `File.System.Write.Streaming.Atomic Tests` {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
        @Suite struct Integration {}
        @Suite(.serialized) struct Performance {}
    }
}

extension `File.System.Write.Streaming.Atomic Tests`.Test.Unit {

    @Test
    func `Atomic namespace exists`() {
        _ = File.System.Write.Streaming.Atomic.self
        _ = File.System.Write.Streaming.Atomic.Options.self
        _ = File.System.Write.Streaming.Atomic.Strategy.self
    }
}
