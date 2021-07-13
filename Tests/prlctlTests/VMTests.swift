import Foundation
import XCTest
@testable import prlctl

final class VMTests: XCTestCase {

    func testThatRunningVMWithIPAddressCanBeParsed() throws {
        let json = getJSONDataForResource(named: "running-vm-with-ip")
        let vm = try XCTUnwrap(JSONDecoder().decode(VM.self, from: json).asRunningVM)
        XCTAssertEqual(vm.hasIpAddress, true)
    }

    func testThatRunningVMWithIPv6AddressCanBeParsed() throws {
        let json = getJSONDataForResource(named: "running-vm-with-ipv6")
        let vm = try XCTUnwrap(JSONDecoder().decode(VM.self, from: json).asRunningVM)
        XCTAssertEqual(vm.hasIpAddress, true)
    }

    func testThatRunningVMWithoutIPAddressCanBeParsed() throws {
        let json = getJSONDataForResource(named: "running-vm-without-ip")
        let vm = try XCTUnwrap(JSONDecoder().decode(VM.self, from: json).asRunningVM)
        XCTAssertEqual(vm.hasIpAddress, false)
    }

    func testThatStoppedVMCanBeParsed() throws {
        let json = getJSONDataForResource(named: "stopped-vm")
        try XCTAssertNotNil(JSONDecoder().decode(VM.self, from: json).asStoppedVM)
    }

    func testThatStoppedVMCanBeStarted() throws {
        let runner = TestCommandRunner()
        try StoppedVM(uuid: "machine-uuid", name: "machine-name", runner: runner).start()
        XCTAssertEqual(runner.command, "prlctl start machine-uuid --wait")
    }

    func testThatStoppedVMCanBeCloned() throws {
        let runner = TestCommandRunner()
        try StoppedVM(uuid: "machine-uuid", name: "machine-name", runner: runner).clone(as: "new-machine")
        XCTAssertEqual(runner.command, "prlctl clone machine-uuid --name new-machine")
    }

    func testThatRunningVMCanBeStopped() throws {
        let runner = TestCommandRunner()
        try RunningVM(uuid: "machine-uuid", name: "machine-name", ipAddress: "127.0.0.1", runner: runner).shutdown()
        XCTAssertEqual(runner.command, "prlctl stop machine-uuid")
    }

    func testThatRunningVMCanBeStoppedImmediately() throws {
        let runner = TestCommandRunner()
        try RunningVM(uuid: "machine-uuid", name: "machine-name", ipAddress: "127.0.0.1", runner: runner).shutdown(immediately: true)
        XCTAssertEqual(runner.command, "prlctl stop machine-uuid --fast")
    }

    func testThatRunningVMCanPerformCommandsAsRoot() throws {
        let runner = TestCommandRunner()
        try RunningVM(uuid: "machine-uuid", name: "machine-name", ipAddress: "127.0.0.1", runner: runner).runCommand("ls")
        XCTAssertEqual(runner.command, "prlctl exec machine-uuid ls")
    }

    func testThatRunningVMCanPerformCommandsAsAnyUser() throws {
        let runner = TestCommandRunner()
        try RunningVM(uuid: "machine-uuid", name: "machine-name", ipAddress: "127.0.0.1", runner: runner).runCommand("ls", as: User(named: "user"))
        XCTAssertEqual(runner.command, "prlctl exec machine-uuid su - user -c 'ls'")
    }
}
