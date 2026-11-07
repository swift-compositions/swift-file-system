#if os(Linux)
    internal import Environment
    internal import ISO_8601
    internal import ISO_9945_Kernel_Time
    internal import RFC_3986
    internal import Time

    extension File.System.Trash {

        /// Moves the file or folder at `path` into the home trash, as the XDG trash specification lays it out:
        /// `$XDG_DATA_HOME/Trash` (or `~/.local/share/Trash`), its `files` holding the item and its `info` a
        /// `.trashinfo` saying where it was and when it was trashed, in local time. A name already in the trash is
        /// numbered, as ``File/Path/Component/numbered(_:)`` gives. A file on another volume is copied in and then
        /// removed, rather than going to that volume's own trash.
        ///
        /// - Parameter path: An absolute path.
        /// - Returns: Where the item now is, in the trash's `files`.
        @discardableResult
        public static func move(_ path: File.Path) throws(Error) -> File.Path {
            guard path.isAbsolute, let name = path.components.last else { throw .unavailable }
            guard File.System.Stat.exists(at: path) else { throw .missing }
            let trash = try home()
            let files = trash / "files"
            let info = trash / "info"
            do throws(File.System.Create.Directory.Error) {
                let options = File.System.Create.Directory.Options(permissions: .init(rawValue: 0o700))
                try File.System.Create.Directory.create(at: files, options: options, createIntermediates: true)
                try File.System.Create.Directory.create(at: info, options: options, createIntermediates: true)
            } catch {
                throw .denied
            }
            let entry = record(path)
            var number = 1
            while true {
                let numbered = name.numbered(number)
                let recorded = info / (try component(numbered.string + ".trashinfo"))
                do throws(File.System.Write.Atomic.Error) {
                    try File.System.Write.Atomic.write(entry.span, to: recorded, options: .init(strategy: .noClobber))
                } catch  where error.isDestinationExists {
                    number += 1
                    continue
                } catch {
                    throw .denied
                }
                let destination = files / numbered
                do throws(File.System.Move.Error) {
                    try File.System.Move.move(from: path, to: destination)
                    return destination
                } catch {
                    do throws(File.System.Delete.Error) {
                        try File.System.Delete.delete(at: recorded)
                    } catch {}
                    if error.isDestinationExists {
                        number += 1
                        continue
                    }
                    if error.isSourceNotFound { throw .missing }
                    throw error.isPermissionDenied ? .denied : .unavailable
                }
            }
        }

        /// `$XDG_DATA_HOME/Trash`, or `$HOME/.local/share/Trash`.
        private static func home() throws(Error) -> File.Path {
            let data = Environment.read("XDG_DATA_HOME").flatMap { $0.isEmpty ? nil : $0 }
            guard let base = data ?? Environment.read("HOME").flatMap({ $0.isEmpty ? nil : $0 + "/.local/share" }) else {
                throw .unavailable
            }
            do throws(File.Path.Error) {
                return try File.Path(base) / "Trash"
            } catch {
                throw .unavailable
            }
        }

        private static func component(_ name: Swift.String) throws(Error) -> File.Path.Component {
            do throws(File.Path.Component.Error) {
                return try File.Path.Component(name)
            } catch {
                throw .unavailable
            }
        }

        /// The `.trashinfo` for `path`, trashed now: its path percent-encoded with the slashes kept, and the date in
        /// local time as `YYYY-MM-DDThh:mm:ss`.
        static func record(_ path: File.Path, at instant: Time.Instant = ISO_9945.Kernel.Time.realtime()) -> [Byte] {
            let encoded = RFC_3986.percentEncode(
                Swift.Array(path.string.utf8),
                allowing: RFC_3986.ByteSet.unreserved.union(RFC_3986.ByteSet(ascii: "/"))
            )
            let text =
                "[Trash Info]\nPath=" + Swift.String(decoding: encoded, as: UTF8.self)
                + "\nDeletionDate=" + date(instant, in: .local) + "\n"
            return text.utf8.map(Byte.init(bitPattern:))
        }

        /// `instant` as `YYYY-MM-DDThh:mm:ss` in the zone `rule` gives for it.
        static func date(_ instant: Time.Instant, in rule: Time.Zone.Rule) -> Swift.String {
            let offset = rule.offset(at: instant).offset.underlying
            let magnitude = Swift.Int64(offset.magnitude.value.rawValue)
            let seconds = offset.polarity == .negative ? -magnitude : magnitude
            func padded(_ value: Swift.Int, _ width: Swift.Int) -> Swift.String {
                let digits = Swift.String(value)
                return Swift.String(repeating: "0", count: Swift.max(0, width - digits.count)) + digits
            }
            do throws(ISO_8601.DateTime.Error) {
                let local = try ISO_8601.DateTime(
                    Time.Instant(secondsSinceUnixEpoch: instant.secondsSinceUnixEpoch + seconds)
                )
                return "\(padded(local.date.year, 4))-\(padded(local.date.month, 2))-\(padded(local.date.day, 2))T"
                    + "\(padded(local.hour, 2)):\(padded(local.minute, 2)):\(padded(local.second, 2))"
            } catch {
                return "0000-01-01T00:00:00"
            }
        }
    }
#endif
