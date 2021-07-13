import Foundation
import XCTest
@testable import prlctl

final class ParallelsCommandRunnerTests: XCTestCase {

    func testThatBasicCommandsWork() throws {
        let runner = DefaultParallelsCommandRunner()
        let result = try runner.runCommand(components: ["echo", "\"foo bar baz\""])
        XCTAssertEqual(result, "foo bar baz")
    }

    func testThatEmptyCommandsWork() throws {
        let runner = DefaultParallelsCommandRunner()
        let result = try runner.runCommand(components: ["echo", ""])
        XCTAssertEqual(result, "")
    }
}
