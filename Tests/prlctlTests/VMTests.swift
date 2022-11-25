import Foundation
import XCTest
@testable import prlctl

final class VMTests: XCTestCase {

    func testThatInvalidVMCanBeParsed() throws {
        let data = getVmDataFrom(infoKey: "invalid-vm", detailsKey: "running-vm-with-ip-details")
        XCTAssertNotNil(try data.parse()?.asInvalidVM())
    }

    func testThatInvalidVMReturnsNilForValidVM() throws {
        let data = getVmDataFrom(infoKey: "packaged-vm", detailsKey: "packaged-vm-details")
        XCTAssertNil(try data.parse()?.asInvalidVM())
    }

    func testThatParsingVMsReturnsNilForInvalidVM() throws {
        let data = getVmDataFrom(infoKey: "invalid-vm", detailsKey: "running-vm-with-ip-details")
        XCTAssertNil(try data.parse()?.asPackagedVM())
        XCTAssertNil(try data.parse()?.asResumingVM())
        XCTAssertNil(try data.parse()?.asRunningVM())
        XCTAssertNil(try data.parse()?.asStoppedVM())
        XCTAssertNil(try data.parse()?.asSuspendedVM())
    }

    func testThatPackagedVMCanBeParsed() throws {
        let data = getVmDataFrom(infoKey: "packaged-vm", detailsKey: "packaged-vm-details")
        XCTAssertNotNil(try data.parse()?.asPackagedVM())
    }

    func testThatResumingVMCanBeParsed() throws {
        let data = getVmDataFrom(infoKey: "resuming-vm", detailsKey: "resuming-vm-details")
        XCTAssertNotNil(try data.parse()?.asResumingVM())
    }

    func testThatRunningVMWithIPAddressCanBeParsed() throws {
        let data = getVmDataFrom(infoKey: "running-vm-with-ip", detailsKey: "running-vm-with-ip-details")
        let vm = try XCTUnwrap(try data.parse()?.asRunningVM())
        XCTAssertTrue(vm.hasIpAddress)
        XCTAssertTrue(vm.hasIpV4Address)
        XCTAssertFalse(vm.hasIpV6Address)
    }

    func testThatRunningVMWithIPv6AddressCanBeParsed() throws {
        let data = getVmDataFrom(infoKey: "running-vm-with-ipv6", detailsKey: "running-vm-with-ipv6-details")
        let vm = try XCTUnwrap(try data.parse()?.asRunningVM())
        XCTAssertTrue(vm.hasIpAddress)
        XCTAssertFalse(vm.hasIpV4Address)
        XCTAssertTrue(vm.hasIpV6Address)
    }

    func testThatRunningVMWithoutIPAddressCanBeParsed() throws {
        let data = getVmDataFrom(infoKey: "running-vm-without-ip", detailsKey: "running-vm-without-ip-details")
        let vm = try XCTUnwrap(try data.parse()?.asRunningVM())
        XCTAssertFalse(vm.hasIpAddress)
        XCTAssertFalse(vm.hasIpV4Address)
        XCTAssertFalse(vm.hasIpV6Address)
    }

    // Not a particularly useful test, but locks in the API
    func testThatRunningVMCanBeInstantiated() throws {
        let vm = RunningVM(uuid: "vm-uuid", name: "vm-name", ipAddress: "127.0.0.1")
        XCTAssertEqual(vm.uuid, "vm-uuid")
        XCTAssertEqual(vm.name, "vm-name")
        XCTAssertEqual(vm.ipAddress, "127.0.0.1")
    }

    func testThatStoppedVMCanBeParsed() throws {
        let data = getVmDataFrom(infoKey: "stopped-vm", detailsKey: "stopped-vm-details")
        XCTAssertNotNil(try XCTUnwrap(try data.parse()?.asStoppedVM()))
    }

    func testThatSuspendedVMCanBeParsed() throws {
        let data = getVmDataFrom(infoKey: "suspended-vm", detailsKey: "suspended-vm-details")
        let vm = try XCTUnwrap(try data.parse())
        XCTAssertNotNil(vm.asSuspendedVM())
    }

    func testThatStoppedVMCanBeStartedWithWait() async throws {
        let runner = TestCommandRunner()
        try await Parallels(runner: runner).startVM(withHandle: "machine-uuid", wait: true)
        XCTAssertEqual(runner.command, "prlctl start machine-uuid --wait")
    }

    func testThatStoppedVMCanBeStartedWithoutWait() async throws {
        let runner = TestCommandRunner()
        try await Parallels(runner: runner).startVM(withHandle: "machine-uuid", wait: false)
        XCTAssertEqual(runner.command, "prlctl start machine-uuid")
    }

    func testThatStoppedVMCanBeCloned() async throws {
        let runner = TestCommandRunner()
        try await Parallels(runner: runner).cloneVM(withHandle: "machine-uuid", as: "new-machine", fast: true)
        XCTAssertEqual(runner.command, "prlctl clone machine-uuid --name new-machine --linked")
    }

    func testThatStoppedVMCanBeDeepCloned() async throws {
        let runner = TestCommandRunner()
        try await Parallels(runner: runner).cloneVM(withHandle: "machine-uuid", as: "new-machine", fast: false)
        XCTAssertEqual(runner.command, "prlctl clone machine-uuid --name new-machine")
    }

    func testThatRunningVMCanBeStopped() async throws {
        let runner = TestCommandRunner()
        try await Parallels(runner: runner).shutdownVM(withHandle: "machine-uuid", immediately: false)
        XCTAssertEqual(runner.command, "prlctl stop machine-uuid")
    }

    func testThatRunningVMCanBeStoppedImmediately() async throws {
        let runner = TestCommandRunner()
        try await Parallels(runner: runner).shutdownVM(withHandle: "machine-uuid", immediately: true)
        XCTAssertEqual(runner.command, "prlctl stop machine-uuid --fast")
    }

    func testThatRunningVMCanPerformCommandsAsRoot() async throws {
        let runner = TestCommandRunner()
        try await Parallels(runner: runner).runCommand("ls", onVirtualMachineWithHandle: "machine-uuid")
        XCTAssertEqual(runner.command, "prlctl exec machine-uuid ls")
    }

    func testThatRunningVMCanPerformCommandsAsAnyUser() async throws {
        let runner = TestCommandRunner()
        let user = User(named: "user")
        try await Parallels(runner: runner).runCommand("ls", onVirtualMachineWithHandle: "machine-uuid", as: user)
        XCTAssertEqual(runner.command, "prlctl exec machine-uuid su - 'user' -c 'ls'")
    }

    func testThatRunningVMCanPerformCommandsWithEscapedUsername() async throws {
        let runner = TestCommandRunner()
        let user = User(named: "my user")
        try await Parallels(runner: runner).runCommand("ls", onVirtualMachineWithHandle: "machine-uuid", as: user)
        XCTAssertEqual(runner.command, "prlctl exec machine-uuid su - 'my user' -c 'ls'")
    }

    func testThatVMDetailsCanBeParsed() throws {
        let json = getJSONDataForResource(named: "packaged-vm-details")
        let vm = try XCTUnwrap(JSONDecoder().decode(VMDetails.self, from: json))
        XCTAssertEqual(vm.uuid, "bd70007c-83b8-4642-b1d0-fa8ddfa0a4cf")
    }

    func testThatStartedVMWithDetailsCanBeParsed() throws {
        let codableVM = try XCTUnwrap(codableVMResource(named: "running-vm-with-ip"))
        let vmDetails = try XCTUnwrap(vmDetailsResource(named: "running-vm-with-ip-details"))
        let vm = try XCTUnwrap(VM(vm: codableVM, details: vmDetails))
        XCTAssertEqual(VMStatus.running, vm.status)
    }

    func testThatSnapshotListCanBeParsed() throws {
        let vmList = try XCTUnwrap((codableVMListResource(named: "vm-snapshot-list")))
        XCTAssertEqual(vmList.count, 1)
    }

    func testThatSnapshotListCommandIsCorrect() async throws {
        let runner = TestCommandRunner(response: "{}")
        _ = try await Parallels(runner: runner).getSnapshotsForVM(withHandle: "machine-uuid")
        XCTAssertEqual(runner.command, "prlctl snapshot-list machine-uuid --json")
    }

    func testThatSnapshotListWorks() async throws {
        let runner = TestCommandRunner(responses: [
            "prlctl snapshot-list stopped-vm --json": getJSONResource(named: "vm-snapshot-list"),
            "prlctl list --json --full --all": "[" + getJSONResource(named: "stopped-vm") + "]",
            "prlctl list --json --full --all --info": "[" + getJSONResource(named: "stopped-vm-details") + "]"
        ])

        let vmList = try await Parallels(runner: runner).getSnapshotsForVM(withHandle: "stopped-vm")
        XCTAssertEqual(vmList.count, 1)
        XCTAssertEqual(vmList.first?.uuid, "{64d481bb-ce04-45b1-8328-49e4e4c43ddf}")
        XCTAssertEqual(vmList.first?.name, "Snapshot for linked clone")
    }

    func testThatEmptySnapshotListReturnsEmptyArray() async throws {
        let runner = TestCommandRunner(response: "{}")
        let vmList = try await Parallels(runner: runner).getSnapshotsForVM(withHandle: "machine-uuid")
        XCTAssertTrue(vmList.isEmpty)
    }

    func testThatDeleteSnapshotWorks() async throws {
        let runner = TestCommandRunner()
        let snapshot = VMSnapshot(uuid: "snapshot-id", name: "snapshot-name", virtualMachineHandle: "machine-uuid")
        try await Parallels(runner: runner).deleteSnapshot(snapshot)
        XCTAssertEqual(runner.command, "prlctl snapshot-delete machine-uuid -i snapshot-id")
    }

    func testThatCleanWorks() async throws {
        let runner = TestCommandRunner(responses: [
            "prlctl snapshot-list stopped-vm --json": getJSONResource(named: "vm-snapshot-list"),
            "prlctl list --json --full --all": "[" + getJSONResource(named: "stopped-vm") + "]",
            "prlctl list --json --full --all --info": "[" + getJSONResource(named: "stopped-vm-details") + "]",
            "prlctl snapshot-delete 83193991-61FE-4FF7-93A9-6B51D9531F67 -i {64d481bb-ce04-45b1-8328-49e4e4c43ddf}": ""
        ])

        try await Parallels(runner: runner).cleanVM(withHandle: "stopped-vm")
        XCTAssertEqual(
            runner.commands.last,
            "prlctl snapshot-delete 83193991-61FE-4FF7-93A9-6B51D9531F67 -i {64d481bb-ce04-45b1-8328-49e4e4c43ddf}"
        )
    }

    func testThatVMRenameWorks() async throws {
        let runner = TestCommandRunner()
        try await Parallels(runner: runner).renameVM(withHandle: "machine-uuid", to: "new-vm-name")
        XCTAssertEqual(
            runner.commands.last,
            "prlctl set machine-uuid --name new-vm-name"
        )
    }

    func testThatVMEqualityIsBasedOnUUID() throws {
        let vm1 = VM(uuid: "uuid", name: "name 1", status: .stopped, ipAddress: "127.0.0.1")
        let vm2 = VM(uuid: "uuid", name: "name 2", status: .stopped, ipAddress: "127.0.0.1")
        XCTAssertEqual(vm1, vm2)
    }
}
