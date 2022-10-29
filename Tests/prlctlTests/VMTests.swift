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

    func testThatStoppedVMCanBeStarted() throws {
        let runner = TestCommandRunner()
        try StoppedVM(uuid: "machine-uuid", name: "machine-name").start(runner: runner)
        XCTAssertEqual(runner.command, "prlctl start machine-uuid --wait")
    }

    func testThatStoppedVMCanBeCloned() throws {
        let runner = TestCommandRunner()
        try StoppedVM(uuid: "machine-uuid", name: "machine-name").clone(as: "new-machine", runner: runner)
        XCTAssertEqual(runner.command, "prlctl clone machine-uuid --name new-machine --linked")
    }

    func testThatStoppedVMCanBeDeepCloned() throws {
        let runner = TestCommandRunner()
        try StoppedVM(uuid: "machine-uuid", name: "machine-name").clone(as: "new-machine", fast: false, runner: runner)
        XCTAssertEqual(runner.command, "prlctl clone machine-uuid --name new-machine")
    }

    func testThatStoppedVMCanBeDeleted() throws {
        let runner = TestCommandRunner()
        try StoppedVM(uuid: "machine-uuid", name: "machine-name").delete(runner: runner)
        XCTAssertEqual(runner.commands.last, "prlctl delete machine-uuid")
    }

    func testThatStoppedVMCanBeUnregistered() throws {
        let runner = TestCommandRunner()
        try StoppedVM(uuid: "machine-uuid", name: "machine-name").unregister(runner: runner)
        XCTAssertEqual(runner.commands.last, "prlctl unregister machine-uuid")
    }

    func testThatRunningVMCanBeStopped() throws {
        let runner = TestCommandRunner()
        try RunningVM(uuid: "machine-uuid", name: "machine-name", ipAddress: "127.0.0.1").shutdown(runner: runner)
        XCTAssertEqual(runner.command, "prlctl stop machine-uuid")
    }

    func testThatRunningVMCanBeStoppedImmediately() throws {
        let runner = TestCommandRunner()
        try RunningVM(uuid: "machine-uuid", name: "machine-name", ipAddress: "127.0.0.1").shutdown(immediately: true, runner: runner)
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
        XCTAssertEqual(runner.command, "prlctl exec machine-uuid su - 'user' -c 'ls'")
    }

    func testThatRunningVMCanPerformCommandsWithEscapedUsername() throws {
        let runner = TestCommandRunner()
        try RunningVM(uuid: "machine-uuid", name: "machine-name", ipAddress: "127.0.0.1", runner: runner).runCommand("ls", as: User(named: "my user"))
        XCTAssertEqual(runner.command, "prlctl exec machine-uuid su - 'my user' -c 'ls'")

    }
    
    func testThatVMDetailsCanBeParsed() throws {
        let json = getJSONDataForResource(named: "packaged-vm-details")
        let vm = try XCTUnwrap(JSONDecoder().decode(VMDetails.self, from: json))
        XCTAssertEqual(vm.uuid, "bd70007c-83b8-4642-b1d0-fa8ddfa0a4cf")
    }

    func testThatStartedVMWithDetailsCanBeParsed() throws {
        let codableVM = try XCTUnwrap(JSONDecoder().decode(CodableVM.self, from: getJSONDataForResource(named: "running-vm-with-ip")))
        let vmDetails = try XCTUnwrap(JSONDecoder().decode(VMDetails.self, from: getJSONDataForResource(named: "running-vm-with-ip-details")))
        let vm = try XCTUnwrap(VM(vm: codableVM, details: vmDetails))
        XCTAssertEqual(VMStatus.running, vm.status)
    }

    func testThatSnapshotListCanBeParsed() throws {
        let vmList = try XCTUnwrap((JSONDecoder().decode(CodableVMSnapshotList.self, from: getJSONDataForResource(named: "vm-snapshot-list"))))
        XCTAssertEqual(vmList.count, 1)
    }

    func testThatSnapshotListCommandIsCorrect() throws {
        let runner = TestCommandRunner(response: "{}")
        let vm = StoppedVM(uuid: "uuid", name: "name")
        _ = try vm.getSnapshots(runner: runner)
        XCTAssertEqual(runner.command, "prlctl snapshot-list uuid --json")
    }
    
    func testThatSnapshotListWorks() throws {
        let runner = TestCommandRunner(response: getJSONResource(named: "vm-snapshot-list"))
        let vmList = try StoppedVM(uuid: "machine-uuid", name: "machine-name").getSnapshots(runner: runner)
        XCTAssertEqual(vmList.count, 1)
        XCTAssertEqual(vmList.first?.uuid, "{64d481bb-ce04-45b1-8328-49e4e4c43ddf}")
        XCTAssertEqual(vmList.first?.name, "Snapshot for linked clone")
    }

    func testThatEmptySnapshotListReturnsEmptyArray() throws {
        let runner = TestCommandRunner(response: getJSONResource(named: "vm-snapshot-list-empty"))
        let vmList = try StoppedVM(uuid: "machine-uuid", name: "machine-name").getSnapshots(runner: runner)
        XCTAssertTrue(vmList.isEmpty)
    }

    func testThatDeleteSnapshotWorks() throws {
        let runner = TestCommandRunner()
        let snapshot = VMSnapshot(uuid: "snapshot-id", name: "snapshot-name")
        try StoppedVM(uuid: "machine-uuid", name: "machine-name").deleteSnapshot(snapshot, runner: runner)
        XCTAssertEqual(runner.command, "prlctl snapshot-delete machine-uuid -i snapshot-id")
    }

    func testThatCleanWorks() throws {
        let runner = TestCommandRunner(response: getJSONResource(named: "vm-snapshot-list"))
        try StoppedVM(uuid: "machine-uuid", name: "machine-name").clean(runner: runner)
        XCTAssertEqual(runner.commands.last, "prlctl snapshot-delete machine-uuid -i {64d481bb-ce04-45b1-8328-49e4e4c43ddf}")
    }

    func testThatSetCPUCountWorks() throws {
        let runner = TestCommandRunner()
        let vm = StoppedVM(uuid: "machine-uuid", name: "machine-name")
        try vm.set(.cpuCount(24), runner: runner)
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --cpus 24")
    }

    func testThatSetMemorySizeWorks() throws {
        let runner = TestCommandRunner()
        let vm = StoppedVM(uuid: "machine-uuid", name: "machine-name")
        try vm.set(.memorySize(8192), runner: runner)
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --memsize 8192")
    }

    func testThatSetHypervisorTypeToParallelsWorks() throws {
        let runner = TestCommandRunner()
        let vm = StoppedVM(uuid: "machine-uuid", name: "machine-name")
        try vm.set(.hypervisorType(.parallels), runner: runner)
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --hypervisor-type parallels")
    }

    func testThatSetHypervisorTypeToAppleWorks() throws {
        let runner = TestCommandRunner()
        let vm = StoppedVM(uuid: "machine-uuid", name: "machine-name")
        try vm.set(.hypervisorType(.apple), runner: runner)
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --hypervisor-type apple")
    }

    func testThatSetNetworkInterfaceTypeToSharedWorks() throws {
        let runner = TestCommandRunner()
        let vm = StoppedVM(uuid: "machine-uuid", name: "machine-name")
        try vm.set(.networkType(.shared), runner: runner)
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --device-set net0 --type shared")
    }

    func testThatSetNetworkInterfaceTypeToBridgedWorks() throws {
        let runner = TestCommandRunner()
        let vm = StoppedVM(uuid: "machine-uuid", name: "machine-name")
        try vm.set(.networkType(.bridged), runner: runner)
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --device-set net0 --type bridged")
    }

    func testThatSetNetworkInterfaceTypeToHostOnlyWorks() throws {
        let runner = TestCommandRunner()
        let vm = StoppedVM(uuid: "machine-uuid", name: "machine-name")
        try vm.set(.networkType(.hostOnly), runner: runner)
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --device-set net0 --type host-only")
    }

    func testThatVMEqualityIsBasedOnUUID() throws {
        let vm1 = VM(uuid: "uuid", name: "name 1", status: .stopped, ip_configured: "127.0.0.1")
        let vm2 = VM(uuid: "uuid", name: "name 2", status: .stopped, ip_configured: "127.0.0.1")
        XCTAssertEqual(vm1, vm2)
    }
}
