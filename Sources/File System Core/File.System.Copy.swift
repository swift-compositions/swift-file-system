public import Kernel

extension File.System {

    public enum Copy {}
}

extension File.System.Copy {

    public typealias Options = Kernel.File.Copy.Options

    public typealias Error = Kernel.File.Copy.Error
}

extension File.System.Copy {

    public static func copy(
        from source: borrowing File.Path,
        to destination: borrowing File.Path,
        options: Options = .init()
    ) throws(Error) {
        try Kernel.File.Copy.copy(
            from: source.view,
            to: destination.view,
            options: options
        )
    }
}
