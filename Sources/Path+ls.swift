import Foundation

public extension Path {
    /// Same as the `ls` command ∴ is ”shallow”
    func ls() throws -> [Entry] {
        let relativePaths = try FileManager.default.contentsOfDirectory(atPath: string)
        func convert(relativePath: String) -> Entry {
            let path = self/relativePath
            return Entry(kind: path.isDirectory ? .directory : .file, path: path)
        }
        return relativePaths.map(convert)
    }
    
    #if !os(Linux)
    /// Same as the `ls` command ∴ is ”shallow”
    /// - Parameter skipHiddenFiles: Same as the `ls -a` if false. Otherwise returns only the non hidden files. Default is false.
    func ls(skipHiddenFiles: Bool) throws -> [Entry] {
        let options: FileManager.DirectoryEnumerationOptions = skipHiddenFiles ? [.skipsHiddenFiles] : []
        let paths = try FileManager.default.contentsOfDirectory(at: url,
                                                                includingPropertiesForKeys: nil,
                                                                options: options)
        func convert(url: URL) -> Entry? {
            guard let path = Path(url.path) else { return nil }
            return Entry(kind: path.isDirectory ? .directory : .file, path: path)
        }
        return paths.compactMap(convert)
    }
    #endif
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
