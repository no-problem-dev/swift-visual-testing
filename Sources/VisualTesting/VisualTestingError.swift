import Foundation

/// A failure while reading the manifests or writing the catalog and gallery.
///
/// The gallery is the artifact the package exists to produce, so none of these are swallowed. A run
/// that cannot read a manifest would otherwise hand back a catalog that is quietly missing images,
/// and one that cannot write would hand back a value that never reached disk.
public enum VisualTestingError: Error, CustomStringConvertible {
    /// The catalog root could not be enumerated — usually a path that does not exist.
    case directoryUnreadable(path: String)
    /// A `manifest.json` was found but could not be read or decoded.
    case manifestUnreadable(path: String, underlying: any Error)
    /// A file could not be encoded or written.
    case writeFailed(path: String, underlying: any Error)

    public var description: String {
        switch self {
        case .directoryUnreadable(let path):
            "Snapshot catalog root could not be read: \(path)"
        case .manifestUnreadable(let path, let underlying):
            "Snapshot manifest could not be read: \(path) — \(underlying)"
        case .writeFailed(let path, let underlying):
            "Could not write \(path) — \(underlying)"
        }
    }
}
