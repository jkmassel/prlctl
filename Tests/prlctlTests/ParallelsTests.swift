import Foundation
import XCTest
@testable import prlctl

class TestCommandRunner: ParallelsCommandRunner {

    var command: String = ""
    private let response: String

    init(response: String = "") {
        self.response = response
    }

    func runCommand(components: [String]) throws -> String {
        return try runCommand(command: components.joined(separator: " "))
    }

    func runCommand(command: String) throws -> String {
        self.command = command
        return response
    }
}

final class ParallelsTests: XCTestCase {

    func testThatStoppedVMsCanBeLookedUp() throws {
        let data = getJSONResource(named: "vm-list")
        let parallels = Parallels(runner: TestCommandRunner(response: data))
        XCTAssertEqual(1, try parallels.lookupStoppedVMs().count)
    }

    func testThatRunningVMsCanBeLookedUp() throws {
        let data = getJSONResource(named: "vm-list")
        let parallels = Parallels(runner: TestCommandRunner(response: data))
        XCTAssertEqual(3, try parallels.lookupRunningVMs().count)
    }

    func testThatLookupVMReturnsStoppedVM() throws {
        let data = getJSONResource(named: "vm-list")
        let parallels = Parallels(runner: TestCommandRunner(response: data))
        let vm = try parallels.lookupVM(named: "stopped-vm")
        XCTAssert(vm is StoppedVM)
    }

    func testThatLookupVMReturnsStartedVM() throws {
        let data = getJSONResource(named: "vm-list")
        let parallels = Parallels(runner: TestCommandRunner(response: data))
        let vm = try parallels.lookupVM(named: "running-vm-with-ip")
        XCTAssert(vm is RunningVM)
    }

    func testThatLookupVMReturnsNilForInvalidHandle() throws {
        let data = getJSONResource(named: "vm-list")
        let parallels = Parallels(runner: TestCommandRunner(response: data))
        let vm = try parallels.lookupVM(named: "invalid-vm-handle")
        XCTAssertNil(vm)
    }

    func testThatLicenseActivationWorks() throws {
        let runner = TestCommandRunner()
        try Parallels(runner: runner).serviceControl.installLicense(key: "key", company: "company")
        XCTAssertEqual(runner.command, "prlsrvctl install-license -k key --company company --activate-online-immediately")
    }
}

extension XCTestCase {
    func getJSONDataForResource(named key: String) -> Data {
        let path = Bundle.module.path(forResource: key, ofType: "json")!
        return FileManager.default.contents(atPath: path)!
    }

    func getJSONResource(named key: String) -> String {
        let data = getJSONDataForResource(named: key)
        return String(data: data, encoding: .utf8)!
    }
}
