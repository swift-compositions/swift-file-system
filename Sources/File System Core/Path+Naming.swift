public import Kernel
public import Path

extension Path.`Protocol` {

    /// The last component's extension. Setting it renames the last component; setting `nil` removes
    /// the extension.
    @inlinable
    public var `extension`: Path.Extension? {
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
    public var stem: Path.Stem? {
        lastComponent?.stem
    }
}
