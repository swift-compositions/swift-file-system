extension File.Link {

    public struct Target: Sendable {
        let link: File.Link
    }
}

extension File.Link.Target {

    public var path: File.Path {
        get throws(File.System.Link.Read.Target.Error) {
            try File.System.Link.Read.Target.target(of: link.path)
        }
    }

    public var file: File {
        get throws(File.System.Link.Read.Target.Error) {
            File(try File.System.Link.Read.Target.target(of: link.path))
        }
    }
}
