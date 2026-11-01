public import Kernel
public import Path

extension Path.Component {

    /// What follows the last dot, or `nil` when there is no dot, the only dot leads (`.profile`), or
    /// nothing follows it.
    @inlinable
    public var `extension`: Extension? {
        let text = string
        guard let dot = text.lastIndex(of: "."), dot != text.startIndex else {
            return nil
        }
        let afterDot = text.index(after: dot)
        guard afterDot != text.endIndex else {
            return nil
        }
        return Extension(unchecked: Swift.String(text[afterDot...]))
    }

    /// The name without its ``extension``.
    @inlinable
    public var stem: Stem {
        let text = string
        guard let dot = text.lastIndex(of: "."), dot != text.startIndex,
            text.index(after: dot) != text.endIndex
        else {
            return Stem(unchecked: text)
        }
        return Stem(unchecked: Swift.String(text[..<dot]))
    }
}

#if !os(Windows)

    extension Path.Component {

        /// The names Windows reserves for devices, in upper case.
        ///
        /// Windows refuses a file whose name, before its first dot, is one of these, compared
        /// case-insensitively: `con`, `CON.txt` and `Nul.tar.gz` all name a device. ``init(cleaning:)``
        /// applies the rule on every platform, so a name made on macOS or Linux still opens on
        /// Windows; there, swift-windows-32 declares the set on its own filename.
        public static let reserved: Set<Swift.String> = [
            "CON", "PRN", "AUX", "NUL",
            "COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8", "COM9",
            "LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9",
        ]
    }

#endif

extension Path.`Protocol` {

    /// The last component's extension. Setting it renames the last component; setting `nil` removes
    /// the extension.
    @inlinable
    public var `extension`: Path.Component.Extension? {
        get { lastComponent?.extension }
        set {
            guard let last = lastComponent else { return }
            let name = newValue.map { last.stem.string + "." + $0.string } ?? last.stem.string
            let component: Path.Component
            do throws(Path.Component.Error) {
                component = try Path.Component(name)
            } catch {
                return
            }
            self = parent.map { $0.appending(component) } ?? Self(copying: component.view)
        }
    }

    /// The last component's stem.
    @inlinable
    public var stem: Path.Component.Stem? {
        lastComponent?.stem
    }
}
