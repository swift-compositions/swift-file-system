import Environment
import Kernel
public import Path
import Strings

extension File {

    public typealias Path = Path::Path
}

extension File.Path {

    @usableFromInline
    package init(__unchecked: Void, _ path: Path::Path) {
        self = path
    }

    @usableFromInline
    package init(__unchecked: Void, _ string: Swift.String) {
        self = Path::Path(stringLiteral: string)
    }

    @usableFromInline
    var parentOrSelf: Path::Path {
        parent ?? self
    }
}

#if !os(Windows)

    extension File.Path {

        @usableFromInline
        internal init(cString: UnsafePointer<CChar>) {
            let string = unsafe Swift.String(cString: cString)
            self = Path::Path(stringLiteral: string)
        }
    }

#endif
