public import Paths

extension File.Path.Component {

    /// This name with `number` after its stem, as Finder numbers a copy: `Report 2.pdf` for `Report.pdf`, `Report 2`
    /// for `Report`. Number 1, and any number below it, is the name itself.
    public func numbered(_ number: Int) -> File.Path.Component {
        guard number > 1 else { return self }
        let suffix = self.extension.map { "." + $0.string } ?? ""
        do throws(Paths.Path.Component.Error) {
            return try File.Path.Component("\(stem.string) \(number)\(suffix)")
        } catch {
            // A space and digits add no separator, control character or NUL that this name did not hold.
            preconditionFailure("\(self) numbered \(number) is not a name: \(error)")
        }
    }
}
