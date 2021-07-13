import Foundation
import XCTest
@testable import prlctl

final class UserTests: XCTestCase {

    func testThatRootUserHasUsernameRoot() {
        XCTAssertEqual(User.root.name, "root")
    }

    func testThatCustomUserCanBeCreated() {
        XCTAssertEqual(User(named: "bob").name, "bob")
    }

    func testThatUsersWithTheSameUsernameAreEqual() {
        XCTAssertEqual(User(named: "bob"), User(named: "bob"))
    }
}
