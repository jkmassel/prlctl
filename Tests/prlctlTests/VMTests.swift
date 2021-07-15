import Foundation
import XCTest
@testable import prlctl

final class VMTests: XCTestCase {

    func testThatRunningVMWithIPAddressCanBeParsed() throws {
        let json = getJSONDataForResource(named: "running-vm-with-ip")
        let codableVM = try XCTUnwrap(JSONDecoder().decode(CodableVM.self, from: json))
        let vm = try XCTUnwrap(VM(vm: codableVM).asRunningVM())
        XCTAssertTrue(vm.hasIpAddress)
        XCTAssertTrue(vm.hasIpV4Address)
        XCTAssertFalse(vm.hasIpV6Address)
    }

    func testThatRunningVMWithIPv6AddressCanBeParsed() throws {
        let json = getJSONDataForResource(named: "running-vm-with-ipv6")
        let codableVM = try XCTUnwrap(JSONDecoder().decode(CodableVM.self, from: json))
        let vm = try XCTUnwrap(VM(vm: codableVM).asRunningVM())
        XCTAssertTrue(vm.hasIpAddress)
        XCTAssertFalse(vm.hasIpV4Address)
        XCTAssertTrue(vm.hasIpV6Address)
    }

    func testThatRunningVMWithoutIPAddressCanBeParsed() throws {
        let json = getJSONDataForResource(named: "running-vm-without-ip")
        let codableVM = try XCTUnwrap(JSONDecoder().decode(CodableVM.self, from: json))
        let vm = try XCTUnwrap(VM(vm: codableVM).asRunningVM())
        XCTAssertFalse(vm.hasIpAddress)
        XCTAssertFalse(vm.hasIpV4Address)
        XCTAssertFalse(vm.hasIpV6Address)
    }

    func testThatStoppedVMCanBeParsed() throws {
        let json = getJSONDataForResource(named: "stopped-vm")
        let codableVM = try XCTUnwrap(JSONDecoder().decode(CodableVM.self, from: json))
        XCTAssertNotNil(try XCTUnwrap(VM(vm: codableVM).asStoppedVM()))
    }

    func testThatStoppedVMCanBeStarted() throws {
        let runner = TestCommandRunner()
        try StoppedVM(uuid: "machine-uuid", name: "machine-name", runner: runner).start()
        XCTAssertEqual(runner.command, "prlctl start machine-uuid --wait")
    }

    func testThatStoppedVMCanBeCloned() throws {
        let runner = TestCommandRunner()
        try StoppedVM(uuid: "machine-uuid", name: "machine-name", runner: runner).clone(as: "new-machine")
        XCTAssertEqual(runner.command, "prlctl clone machine-uuid --name new-machine --linked")
    }

    func testThatStoppedVMCanBeDeepCloned() throws {
        let runner = TestCommandRunner()
        try StoppedVM(uuid: "machine-uuid", name: "machine-name", runner: runner).clone(as: "new-machine", fast: false)
        XCTAssertEqual(runner.command, "prlctl clone machine-uuid --name new-machine")
    }

    func testThatStoppedVMCanBeDeleted() throws {
        let runner = TestCommandRunner()
        try StoppedVM(uuid: "machine-uuid", name: "machine-name", runner: runner).delete()
        XCTAssertEqual(runner.command, "prlctl delete machine-uuid")
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

    func testThatVMDetailsCanBeParsed() throws {
        let json = getJSONDataForResource(named: "packaged-vm-details")
        let vm = try XCTUnwrap(JSONDecoder().decode(VMDetails.self, from: json))

        XCTAssertEqual(vm.uuid, "bd70007c-83b8-4642-b1d0-fa8ddfa0a4cf")
    }

    func testThatPackagedVMCanBeParsed() throws {
        let codableVM = try XCTUnwrap(JSONDecoder().decode(CodableVM.self, from: getJSONDataForResource(named: "stopped-vm")))
        let vmDetails = try XCTUnwrap(JSONDecoder().decode(VMDetails.self, from: getJSONDataForResource(named: "packaged-vm-details")))
        let vm = try XCTUnwrap(VM(vm: codableVM, details: vmDetails))
        XCTAssertEqual(VMStatus.packaged, vm.status)
    }

    func testThatStartedVMWithDetailsCanBeParsed() throws {
        let codableVM = try XCTUnwrap(JSONDecoder().decode(CodableVM.self, from: getJSONDataForResource(named: "running-vm-with-ip")))
        let vmDetails = try XCTUnwrap(JSONDecoder().decode(VMDetails.self, from: getJSONDataForResource(named: "running-vm-details")))
        let vm = try XCTUnwrap(VM(vm: codableVM, details: vmDetails))
        XCTAssertEqual(VMStatus.running, vm.status)
    }

    func testThatSnapshotListCanBeParsed() throws {
        let vmList = try XCTUnwrap((JSONDecoder().decode(CodableVMSnapshotList.self, from: getJSONDataForResource(named: "vm-snapshot-list"))))
        XCTAssertEqual(vmList.count, 1)
    }

    func testThatSnapshotListWorks() throws {
        let runner = TestCommandRunner(response: getJSONResource(named: "vm-snapshot-list"))
        let vmList = try StoppedVM(uuid: "machine-uuid", name: "machine-name", runner: runner).getSnapshots()
        XCTAssertEqual(vmList.count, 1)
        XCTAssertEqual(vmList.first?.uuid, "{64d481bb-ce04-45b1-8328-49e4e4c43ddf}")
        XCTAssertEqual(vmList.first?.name, "Snapshot for linked clone")
    }

    func testThatDeleteSnapshotWorks() throws {
        let runner = TestCommandRunner()
        let snapshot = VMSnapshot(uuid: "snapshot-id", name: "snapshot-name")
        try StoppedVM(uuid: "machine-uuid", name: "machine-name", runner: runner).deleteSnapshot(snapshot)
        XCTAssertEqual(runner.command, "prlctl snapshot-delete machine-uuid -i snapshot-id")
    }

    func testThatCleanWorks() throws {
        let runner = TestCommandRunner(response: getJSONResource(named: "vm-snapshot-list"))
        try StoppedVM(uuid: "machine-uuid", name: "machine-name", runner: runner).clean()
        XCTAssertEqual(runner.command, "prlctl snapshot-delete machine-uuid -i {64d481bb-ce04-45b1-8328-49e4e4c43ddf}")
    }
}
