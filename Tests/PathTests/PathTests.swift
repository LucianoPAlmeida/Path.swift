import XCTest
import Path

class PathTests: XCTestCase {
    func testConcatenation() {
        XCTAssertEqual((Path.root/"bar").string, "/bar")
        XCTAssertEqual(Path.cwd.string, FileManager.default.currentDirectoryPath)
        XCTAssertEqual((Path.root/"/bar").string, "/bar")
        XCTAssertEqual((Path.root/"///bar").string, "/bar")
        XCTAssertEqual((Path.root/"foo///bar////").string, "/foo/bar")
        XCTAssertEqual((Path.root/"foo"/"/bar").string, "/foo/bar")
    }

    func testEnumeration() throws {
        let tmpdir_ = try TemporaryDirectory()
        let tmpdir = tmpdir_.path
        try tmpdir.join("a").mkdir().join("c").touch()
        try tmpdir.join("b").touch()
        try tmpdir.join("c").touch()

        var paths = Set<String>()
        var dirs = 0
        for entry in try tmpdir.ls() {
            if entry.kind == .directory {
                dirs += 1
            }
            paths.insert(entry.path.basename())
        }
        XCTAssertEqual(dirs, 1)
        XCTAssertEqual(paths, ["a", "b", "c"])
        
    }
    
    #if !os(Linux)
    func testEnumerationSkippingHiddenFilesTrue() throws {
        let tmpdir_ = try TemporaryDirectory()
        let tmpdir = tmpdir_.path
        try tmpdir.join("a").mkdir().join("c").touch()
        try tmpdir.join("b").touch()
        try tmpdir.join("c").touch()
        try tmpdir.join(".d").mkdir().join("e").touch()
        
        var paths = Set<String>()
        var dirs = 0
        for entry in try tmpdir.ls(skipHiddenFiles: true) {
            if entry.kind == .directory {
                dirs += 1
            }
            paths.insert(entry.path.basename())
        }
        XCTAssertEqual(dirs, 1)
        XCTAssertEqual(paths, ["a", "b", "c", ])
    }
    
    func testEnumerationSkippingHiddenFilesFalse() throws {
        let tmpdir_ = try TemporaryDirectory()
        let tmpdir = tmpdir_.path
        try tmpdir.join("a").mkdir().join("c").touch()
        try tmpdir.join("b").touch()
        try tmpdir.join("c").touch()
        try tmpdir.join(".d").mkdir().join("e").touch()
        
        var paths = Set<String>()
        var dirs = 0
        for entry in try tmpdir.ls(skipHiddenFiles: false) {
            if entry.kind == .directory {
                dirs += 1
            }
            paths.insert(entry.path.basename())
        }
        XCTAssertEqual(dirs, 2)
        XCTAssertEqual(paths, ["a", "b", "c", ".d"])
    }
    #endif

    func testRelativeTo() {
        XCTAssertEqual((Path.root/"tmp/foo").relative(to: .root/"tmp"), "foo")
        XCTAssertEqual((Path.root/"tmp/foo/bar").relative(to: .root/"tmp/baz"), "../foo/bar")
    }

    func testExists() {
        XCTAssert(Path.root.exists)
        XCTAssert((Path.root/"bin").exists)
    }

    func testIsDirectory() {
        XCTAssert(Path.root.isDirectory)
        XCTAssert((Path.root/"bin").isDirectory)
    }

    func testMktemp() throws {
        var path: Path!
        try Path.mktemp {
            path = $0
            XCTAssert(path.isDirectory)
        }
        XCTAssert(!path.exists)
        XCTAssert(!path.isDirectory)
    }

    func testMkpathIfExists() throws {
        try Path.mktemp {
            for _ in 0...1 {
                try $0.join("a").mkdir()
                try $0.join("b/c").mkpath()
            }
        }
    }

    func testBasename() {
        XCTAssertEqual(Path.root.join("foo.bar").basename(dropExtension: true), "foo")
        XCTAssertEqual(Path.root.join("foo").basename(dropExtension: true), "foo")
        XCTAssertEqual(Path.root.join("foo.").basename(dropExtension: true), "foo.")
        XCTAssertEqual(Path.root.join("foo.bar.baz").basename(dropExtension: true), "foo.bar")
    }

    func testCodable() throws {
        let input = [Path.root/"bar"]
        XCTAssertEqual(try JSONDecoder().decode([Path].self, from: try JSONEncoder().encode(input)), input)
    }

    func testRelativePathCodable() throws {
        let root = Path.root/"bar"
        let input = [
            root/"foo"
        ]

        let encoder = JSONEncoder()
        encoder.userInfo[.relativePath] = root
        let data = try encoder.encode(input)

        XCTAssertEqual(try JSONSerialization.jsonObject(with: data) as? [String], ["foo"])

        let decoder = JSONDecoder()
        XCTAssertThrowsError(try decoder.decode([Path].self, from: data))
        decoder.userInfo[.relativePath] = root
        XCTAssertEqual(try decoder.decode([Path].self, from: data), input)
    }

    func testJoin() {
        let prefix = Path.root/"Users/mxcl"

        XCTAssertEqual(prefix/"b", Path("/Users/mxcl/b"))
        XCTAssertEqual(prefix/"b"/"c", Path("/Users/mxcl/b/c"))
        XCTAssertEqual(prefix/"b/c", Path("/Users/mxcl/b/c"))
        XCTAssertEqual(prefix/"/b", Path("/Users/mxcl/b"))
        let b = "b"
        let c = "c"
        XCTAssertEqual(prefix/b/c, Path("/Users/mxcl/b/c"))
        XCTAssertEqual(Path.root/"~b", Path("/~b"))
        XCTAssertEqual(Path.root/"~/b", Path("/~/b"))
        XCTAssertEqual(Path("~/foo"), Path.home/"foo")
        XCTAssertNil(Path("~foo"))
    }
}
