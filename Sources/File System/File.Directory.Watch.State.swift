#if Watch
    #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)

        import Executors
        import Kernel

        extension File.Directory.Watch {

            /// The running watch: the event source, the directories it watches, and the directories
            /// waiting to be yielded. It runs on a thread of its own, which blocks in `poll`.
            internal actor State {

                private static let interest: Kernel.Event.Interest = [.change, .rename, .delete, .revoke]

                private static let gone: Kernel.Event.Interest = [.rename, .delete, .revoke]

                nonisolated internal let executor: Kernel.Thread.Executor

                nonisolated internal let wakeup: Kernel.Wakeup.Channel

                private let root: File.Path

                private let options: Options

                private var handle: Handle?

                private var paths: [Kernel.Event.ID: File.Path] = [:]

                private var ids: [File.Path: Kernel.Event.ID] = [:]

                private var pending: [File.Path] = []

                private var started = false

                private var events: [Kernel.Event] = Array(repeating: Kernel.Event.empty, count: 64)

                nonisolated internal var unownedExecutor: UnownedSerialExecutor {
                    unsafe executor.asUnownedSerialExecutor()
                }

                internal init(path: File.Path, options: Options) throws(File.Directory.Watch.Error) {
                    let source: Kernel.Event.Source
                    do throws(Kernel.Event.Driver.Error) {
                        source = try Kernel.Event.Source.kqueue()
                    } catch {
                        throw .source(error)
                    }
                    self.wakeup = source.wakeup
                    self.handle = Handle(source: source)
                    self.executor = Kernel.Thread.Executor()
                    self.root = path
                    self.options = options
                }

                deinit {
                    executor.shutdown()
                }
            }
        }

        extension File.Directory.Watch.State {

            /// The next directory to rescan, or nil once the task is cancelled.
            internal func next() -> Result<File.Directory?, File.Directory.Watch.Error> {
                do throws(File.Directory.Watch.Error) {
                    return .success(try advance())
                } catch {
                    finish()
                    return .failure(error)
                }
            }

            private func advance() throws(File.Directory.Watch.Error) -> File.Directory? {
                if !started {
                    started = true
                    try watch(subtree: root)
                }
                while true {
                    if Task.isCancelled {
                        finish()
                        return nil
                    }
                    if !pending.isEmpty {
                        return File.Directory(pending.removeFirst())
                    }
                    guard handle != nil else { return nil }

                    try collect(until: nil)
                    guard !pending.isEmpty, options.latency > .zero else { continue }

                    let window = Clock.Continuous.Deadline.after(options.latency, from: Clock.Continuous.now)
                    while !window.hasExpired(at: Clock.Continuous.now), !Task.isCancelled, handle != nil {
                        try collect(until: window)
                    }
                }
            }

            /// Waits for events, at most until the deadline, and takes them in.
            private func collect(until deadline: Clock.Continuous.Deadline?) throws(File.Directory.Watch.Error) {
                guard let handle else { return }

                let count: Int
                do throws(Kernel.Event.Driver.Error) {
                    count = try handle.source.poll(deadline: deadline, into: &events)
                } catch {
                    throw .source(error)
                }
                for event in events.prefix(count) {
                    try receive(event)
                }
            }

            private func receive(_ event: Kernel.Event) throws(File.Directory.Watch.Error) {
                guard let path = paths[event.id] else { return }

                if !event.interest.isDisjoint(with: Self.gone) {
                    guard path != root else { throw .removed(root) }
                    drop(path)
                    return
                }
                guard event.interest.contains(.change), let handle else { return }

                do throws(Kernel.Event.Driver.Error) {
                    try handle.source.arm(id: event.id, interest: Self.interest)
                } catch {
                    throw .source(error)
                }
                try rescan(path)
            }
        }

        extension File.Directory.Watch.State {

            /// Watches the subdirectories that appeared in a changed directory, drops the ones that
            /// went, and queues the directory itself.
            private func rescan(_ path: File.Path) throws(File.Directory.Watch.Error) {
                let entries: [File.Directory.Entry]
                do throws(File.Directory.Contents.Error) {
                    entries = try File.Directory.Contents.list(at: File.Directory(path))
                } catch {
                    guard path != root else { throw .list(path, error) }
                    drop(path)
                    return
                }

                var present: Set<File.Path> = []
                for entry in entries where entry.type == .directory && admits(entry) {
                    guard let child = entry.pathIfValid else { continue }
                    present.insert(child)
                    if ids[child] == nil {
                        try watch(subtree: child)
                    }
                }
                for child in ids.keys where child.parent == path && !present.contains(child) {
                    drop(child)
                }
                queue(path)
            }

            /// Watches a directory and every admitted directory below it. A subdirectory that cannot
            /// be opened or listed is left out, with its subtree; only the root's failures throw.
            private func watch(subtree path: File.Path) throws(File.Directory.Watch.Error) {
                guard try watch(path) else { return }

                let entries: [File.Directory.Entry]
                do throws(File.Directory.Contents.Error) {
                    entries = try File.Directory.Contents.list(at: File.Directory(path))
                } catch {
                    guard path == root else { return }
                    throw .list(path, error)
                }
                for entry in entries where entry.type == .directory && admits(entry) {
                    guard let child = entry.pathIfValid, ids[child] == nil else { continue }
                    try watch(subtree: child)
                }
            }

            /// Opens and registers one directory, and queues it. False when a subdirectory cannot be
            /// opened: it vanished, or the process may not read it.
            private func watch(_ path: File.Path) throws(File.Directory.Watch.Error) -> Bool {
                guard let handle else { return false }
                guard ids.count < options.limit else { throw .limit(options.limit) }

                var descriptor: Kernel.Descriptor = .invalid
                do throws(Kernel.File.Open.Error) {
                    try path.withKernelPath { kernelPath throws(Kernel.File.Open.Error) in
                        descriptor = try Kernel.File.Open.open(
                            path: kernelPath,
                            mode: .read,
                            options: [.eventOnly, .execClose, .noFollow],
                            permissions: Kernel.File.Permissions(rawValue: 0)
                        )
                    }
                } catch {
                    // Running out of descriptors is the watch's own failure, wherever it happens.
                    if case .handle(.limit) = error { throw .open(path, error) }
                    guard path == root else { return false }
                    throw .open(path, error)
                }

                let id: Kernel.Event.ID
                do throws(Kernel.Event.Driver.Error) {
                    id = try handle.source.register(descriptor: descriptor, interest: Self.interest)
                    try handle.source.arm(id: id, interest: Self.interest)
                } catch {
                    throw .source(error)
                }
                paths[id] = path
                ids[path] = id
                queue(path)
                return true
            }

            private func admits(_ entry: File.Directory.Entry) -> Bool {
                (options.includeHidden || !entry.name.isHiddenByDotPrefix) && options.descend(entry)
            }

            private func queue(_ path: File.Path) {
                if !pending.contains(path) { pending.append(path) }
            }
        }

        extension File.Directory.Watch.State {

            /// Stops watching a directory and everything below it, closing their descriptors.
            private func drop(_ path: File.Path) {
                for (watched, id) in ids where watched.hasPrefix(path) {
                    deregister(id)
                    ids[watched] = nil
                    paths[id] = nil
                }
                pending.removeAll { $0.hasPrefix(path) }
            }

            /// Ends the watch: every descriptor and the queue itself are closed.
            private func finish() {
                for id in paths.keys { deregister(id) }
                paths.removeAll()
                ids.removeAll()
                pending.removeAll()
                handle = nil
            }

            private func deregister(_ id: Kernel.Event.ID) {
                do throws(Kernel.Event.Driver.Error) {
                    try handle?.source.deregister(id: id)
                } catch {
                    // The descriptor is closed with its registration either way.
                }
            }
        }

    #endif
#endif
