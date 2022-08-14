import XCTest
@testable import SwiftCommand

final class SwiftCommandTests: XCTestCase {
    static let lines = ["Foo", "Bar", "Baz", "Test1", "Test2"]

    func testEcho() async throws {
        guard let command = Command.findInPath(withName: "echo") else {
            fatalError()
        }

        let process = try command.addArgument(Self.lines.joined(separator: "\n"))
                                 .setStdout(.pipe)
                                 .spawn()

        var linesIterator = Self.lines.makeIterator()
        
        for try await line in process.stdout.lines {
            XCTAssertEqual(line, linesIterator.next())
        }
        
        try process.wait()
    }

    func testComposition() async throws {
        let echoProcess = try Command.findInPath(withName: "echo")!
                                     .addArgument(Self.lines.joined(separator: "\n"))
                                     .setStdout(.pipe)
                                     .spawn()
        
        let grepProcess = try Command.findInPath(withName: "grep")!
                                     .addArgument("Test")
                                     .setStdin(.pipe(from: echoProcess.stdout))
                                     .setStdout(.pipe)
                                     .spawn()

        var linesIterator = Self.lines.filter({ $0.contains("Test") }).makeIterator()

        for try await line in grepProcess.stdout.lines {
            XCTAssertEqual(line, linesIterator.next())
        }
        
        try echoProcess.wait()
        try grepProcess.wait()
    }
    
    func testStdin() async throws {
        let process = try Command.findInPath(withName: "cat")!
                                 .setStdin(.pipe)
                                 .setStdout(.pipe)
                                 .spawn()
        
        var stdin = process.stdin
        
        print("Foo", to: &stdin)
        print("Bar", to: &stdin)
        
        let output = try await process.output
        
        XCTAssertEqual(output.stdout, "Foo\nBar\n")
    }
    
    func testStderr() async throws {
        let output = try await Command.findInPath(withName: "cat")!
                                      .addArgument("non_existing.txt")
                                      .setStderr(.pipe)
                                      .output
        
        XCTAssertNotEqual(output.status, .success)
        XCTAssertEqual(output.stderr, "cat: non_existing.txt: No such file or directory\n")
    }
}
