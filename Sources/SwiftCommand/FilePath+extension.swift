import SystemPackage
import Foundation

extension FilePath {
    /// Convenience initializer for creating a `FilePath` from a `Substring`.
    public init(substring: Substring) {
        self.init(String(substring))
    }


    /// Creates a `Foundation.URL` from this `FilePath`.
    public var url: URL {
        .init(fileURLWithPath: self.string)
    }
}
