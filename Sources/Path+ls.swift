import Foundation

public extension Path {
    /// same as the `ls` command ∴ is ”shallow”
    func ls() throws -> [Entry] {
        let relativePaths = try FileManager.default.contentsOfDirectory(atPath: string)
        func convert(relativePath: String) -> Entry {
            let path = self/relativePath
            return Entry(kind: path.isDirectory ? .directory : .file, path: path)
        }
        return relativePaths.map(convert)
    }
}

public extension Array where Element == Path.Entry {
    /// Filters the list of entries to be a list of Paths that are directories.
    var directories: [Path] {
        return compactMap {
            $0.kind == .directory ? $0.path : nil
        }
    }

    /// Filters the list of entries to be a list of Paths that are files with the specified extension
    func files(withExtension ext: String) -> [Path] {
        return compactMap {
            $0.kind == .file && $0.path.extension == ext ? $0.path : nil
        }
    }
}
