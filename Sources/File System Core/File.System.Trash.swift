extension File.System {

    /// The trash: a file moved there can be put back by the person, and is removed for good only when they empty it.
    ///
    /// `move(_:)` is given per platform. On Apple platforms it moves through the system's own trash, in File System
    /// Foundation Integration. On Linux it follows the XDG trash layout, into the home trash. Windows has none.
    public enum Trash {}
}

#if os(Linux)
    internal import Environment
    internal import ISO_9945_Kernel_Time
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
            let text =
                "[Trash Info]\nPath=" + percentEncode(path.string.utf8)
                + "\nDeletionDate=" + date(instant, in: .local) + "\n"
            return text.utf8.map(Byte.init(bitPattern:))
        }

        private static func percentEncode(_ bytes: Swift.String.UTF8View) -> Swift.String {
            let digits: [UInt8] = [
                0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37,
                0x38, 0x39, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46,
            ]
            var encoded: [UInt8] = []
            encoded.reserveCapacity(bytes.count)
            for byte in bytes {
                let unreserved =
                    (byte >= 0x41 && byte <= 0x5A)
                    || (byte >= 0x61 && byte <= 0x7A)
                    || (byte >= 0x30 && byte <= 0x39)
                    || byte == 0x2D || byte == 0x2E || byte == 0x5F || byte == 0x7E
                    || byte == 0x2F
                if unreserved {
                    encoded.append(byte)
                } else {
                    encoded.append(0x25)
                    encoded.append(digits[Swift.Int(byte >> 4)])
                    encoded.append(digits[Swift.Int(byte & 0x0F)])
                }
            }
            return Swift.String(decoding: encoded, as: UTF8.self)
        }

        /// `instant` as `YYYY-MM-DDThh:mm:ss` in the zone `rule` gives for it.
        static func date(_ instant: Time.Instant, in rule: Time.Zone.Rule) -> Swift.String {
            let offset = rule.offset(at: instant).offset.underlying
            let magnitude = Swift.Int64(offset.magnitude.value.rawValue)
            let seconds = offset.polarity == .negative ? -magnitude : magnitude
            let localSeconds = instant.secondsSinceUnixEpoch + seconds
            let daySeconds: Swift.Int64 = 86_400
            var days = localSeconds / daySeconds
            var remainder = localSeconds % daySeconds
            if remainder < 0 {
                remainder += daySeconds
                days -= 1
            }
            let z = days + 719_468
            let era = (z >= 0 ? z : z - 146_096) / 146_097
            let doe = z - era * 146_097
            let yoe = (doe - doe / 1_460 + doe / 36_524 - doe / 146_096) / 365
            let y = yoe + era * 400
            let doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
            let mp = (5 * doy + 2) / 153
            let day = Swift.Int(doy - (153 * mp + 2) / 5 + 1)
            let month = Swift.Int(mp < 10 ? mp + 3 : mp - 9)
            let year = Swift.Int(y + (month <= 2 ? 1 : 0))
            let hour = Swift.Int(remainder / 3_600)
            let minute = Swift.Int((remainder % 3_600) / 60)
            let second = Swift.Int(remainder % 60)
            func padded(_ value: Swift.Int, _ width: Swift.Int) -> Swift.String {
                let digits = Swift.String(value)
                return Swift.String(repeating: "0", count: Swift.max(0, width - digits.count)) + digits
            }
            return "\(padded(year, 4))-\(padded(month, 2))-\(padded(day, 2))T"
                + "\(padded(hour, 2)):\(padded(minute, 2)):\(padded(second, 2))"
        }
    }
#endif
