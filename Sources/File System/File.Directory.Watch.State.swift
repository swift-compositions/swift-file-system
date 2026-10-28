#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)

    import Either
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
                guard let handle else { return nil }

                let count: Int
                do throws(Kernel.Event.Driver.Error) {
                    count = try handle.source.poll(deadline: nil, into: &events)
                } catch {
                    throw .source(error)
                }
                for event in events.prefix(count) {
                    try receive(event)
                }
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

        /// Watches a directory and every admitted directory below it.
        private func watch(subtree path: File.Path) throws(File.Directory.Watch.Error) {
            guard try watch(path) else { return }

            let walk = File.Directory.Walk.Options(includeHidden: options.includeHidden)
            var failure: File.Directory.Watch.Error?
            do throws(Either<File.Directory.Walk.Error, File.Directory.Watch.Error>) {
                try File.Directory(path).walk.iterate(options: walk) {
                    entry throws(File.Directory.Watch.Error) -> File.Directory.Walk.Control in
                    guard entry.type == .directory else { return .continue }
                    guard admits(entry), let child = entry.pathIfValid else { return .skip }
                    guard ids[child] == nil else { return .skip }
                    return try watch(child) ? .continue : .skip
                }
            } catch {
                switch error {
                case .left(let error) where error.isNotFound && path != root:
                    break

                case .left(let error):
                    failure = .walk(error)

                case .right(let error):
                    failure = error
                }
            }
            if let failure { throw failure }
        }

        /// Opens and registers one directory, and queues it. False when it vanished first.
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
                if case .path(.notFound) = error, path != root { return false }
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
