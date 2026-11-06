@_exported public import Binary
@_exported public import Kernel_Core
@_exported public import Path

// A path literal is text held to `init(validating:)`. Windows rewrites separators in text, so its conformance sits with
// that rule in Windows 32 Kernel File, which Kernel File carries there; elsewhere Path holds it.
#if os(Windows)
    @_exported public import Kernel_File
#endif
