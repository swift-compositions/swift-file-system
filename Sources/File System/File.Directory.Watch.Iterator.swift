#if Watch
    #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)

        extension File.Directory.Watch {

            public struct Iterator: AsyncIteratorProtocol, Sendable {

                private let path: File.Path

                private let options: Options

                private var state: State?

                internal init(path: File.Path, options: Options) {
                    self.path = path
                    self.options = options
                }

                public mutating func next(
                    isolation actor: isolated (any Actor)? = #isolation
                ) async throws(File.Directory.Watch.Error) -> File.Directory? {
                    if state == nil {
                        state = try State(path: path, options: options)
                    }
                    guard let state else { return nil }
                    let result = await withTaskCancellationHandler {
                        await state.next()
                    } onCancel: {
                        state.wakeup.wake()
                    }
                    return try result.get()
                }
            }
        }

    #endif
#endif
