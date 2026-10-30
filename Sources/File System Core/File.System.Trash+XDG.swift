#if os(Linux)
    internal import Environment
    internal import ISO_8601
    internal import ISO_9945_Kernel_Time
    internal import RFC_3986
    internal import Time

    extension File.System.Trash {

        /// Moves the file or folder at `path` into the home trash, as the XDG trash specification lays it out:
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
            let text = "[Trash Info]\nPath=" + Swift.String(decoding: encoded, as: UTF8.self)
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
