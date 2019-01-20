import Foundation

/**
 Represents a platform filesystem absolute path.

 The recommended conversions from string are:

     let p1 = Path.root/pathString
     let p2 = Path.root/url.path
     let p3 = Path.cwd/relativePathString
     let p4 = Path(userInput) ?? Path.cwd/userInput

 - Note: There may not be an actual filename at the path.
 */
public struct Path: Equatable, Hashable, Comparable {
    /// The underlying filesystem path
    public let string: String

    /**
     Returns the filename extension of this path.
     - Remark: Implemented via `NSString.pathExtension`.
     */
    @inlinable
    public var `extension`: String {
        return (string as NSString).pathExtension
    }

    /**
     Returns the parent directory for this path.

     Path is not aware of the nature of the underlying file, but this is
     irrlevant since the operation is the same irrespective of this fact.

     - Note: always returns a valid path, `Path.root.parent` *is* `Path.root`.
     */
    public var parent: Path {
        return Path(string: (string as NSString).deletingLastPathComponent)
    }

    /// Returns a `URL` representing this file path.
    @inlinable
    public var url: URL {
        return URL(fileURLWithPath: string)
    }

    /**
     The basename for the provided file, optionally dropping the file extension.

         Path.root.join("foo.swift").basename()  // => "foo.swift"
         Path.root.join("foo.swift").basename(dropExtension: true)  // => "foo"

     - Returns: A string that is the filename’s basename.
     - Parameter dropExtension: If `true` returns the basename without its file extension.
     */
    public func basename(dropExtension: Bool = false) -> String {
        let str = string as NSString
        if !dropExtension {
            return str.lastPathComponent
        } else {
            let ext = str.pathExtension
            if !ext.isEmpty {
                return String(str.lastPathComponent.dropLast(ext.count + 1))
            } else {
                return str.lastPathComponent
            }
        }
    }

    /**
     Returns a string representing the relative path to `base`.

     - Note: If `base` is not a logical prefix for `self` your result will be prefixed some number of `../` components.
     - Parameter base: The base to which we calculate the relative path.
     - ToDo: Another variant that returns `nil` if result would start with `..`
     */
    public func relative(to base: Path) -> String {
        // Split the two paths into their components.
        // FIXME: The is needs to be optimized to avoid unncessary copying.
        let pathComps = (string as NSString).pathComponents
        let baseComps = (base.string as NSString).pathComponents

        // It's common for the base to be an ancestor, so try that first.
        if pathComps.starts(with: baseComps) {
            // Special case, which is a plain path without `..` components.  It
            // might be an empty path (when self and the base are equal).
            let relComps = pathComps.dropFirst(baseComps.count)
            return relComps.joined(separator: "/")
        } else {
            // General case, in which we might well need `..` components to go
            // "up" before we can go "down" the directory tree.
            var newPathComps = ArraySlice(pathComps)
            var newBaseComps = ArraySlice(baseComps)
            while newPathComps.prefix(1) == newBaseComps.prefix(1) {
                // First component matches, so drop it.
                newPathComps = newPathComps.dropFirst()
                newBaseComps = newBaseComps.dropFirst()
            }
            // Now construct a path consisting of as many `..`s as are in the
            // `newBaseComps` followed by what remains in `newPathComps`.
            var relComps = Array(repeating: "..", count: newBaseComps.count)
            relComps.append(contentsOf: newPathComps)
            return relComps.joined(separator: "/")
        }
    }

    /**
     Joins a path and a string to produce a new path.

         Path.root.join("a")             // => /a
         Path.root.join("a/b")           // => /a/b
         Path.root.join("a").join("b")   // => /a/b
         Path.root.join("a").join("/b")  // => /a/b

     - Parameter pathComponent: The string to join with this path.
     - Returns: A new joined path.
     - SeeAlso: /(:Path,:String)
     */
    public func join<S>(_ pathComponent: S) -> Path where S: StringProtocol {
        //TODO standardizingPath does more than we want really (eg tilde expansion)
        let str = (string as NSString).appendingPathComponent(String(pathComponent))
        return Path(string: (str as NSString).standardizingPath)
    }

    /// Returns the locale-aware sort order for the two paths.
    @inlinable
    public static func <(lhs: Path, rhs: Path) -> Bool {
        return lhs.string.compare(rhs.string, locale: .current) == .orderedAscending
    }

    /// A file entry from a directory listing.
    public struct Entry {
        /// The kind of this directory entry.
        public enum Kind {
            /// The path is a file.
            case file
            /// The path is a directory.
            case directory
        }
        /// The kind of this entry.
        public let kind: Kind
        /// The path of this entry.
        public let path: Path
    }
}

/**
 Joins a path and a string to produce a new path.

     Path.root/"a"       // => /a
     Path.root/"a/b"     // => /a/b
     Path.root/"a"/"b"   // => /a/b
     Path.root/"a"/"/b"  // => /a/b

 - Parameter lhs: The base path to join with `rhs`.
 - Parameter rhs: The string to join with this `lhs`.
 - Returns: A new joined path.
 - SeeAlso: Path.join(_:)
 */
@inlinable
public func /<S>(lhs: Path, rhs: S) -> Path where S: StringProtocol {
    return lhs.join(rhs)
}
