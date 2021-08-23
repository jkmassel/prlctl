import Foundation
import XCTest
@testable import prlctl

final class VMTests: XCTestCase {

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
        let vmDetails = try XCTUnwrap(JSONDecoder().decode(VMDetails.self, from: getJSONDataForResource(named: "running-vm-with-ip-details")))
        let vm = try XCTUnwrap(VM(vm: codableVM, details: vmDetails))
        XCTAssertEqual(VMStatus.running, vm.status)
    }

    func testThatInvalidVMCanBeParsed() throws {
        let data = getVmDataFrom(infoKey: "invalid-vm", detailsKey: "running-vm-with-ip-details")
        let vm = try XCTUnwrap(try data.parse())
        XCTAssertEqual(VMStatus.invalid, vm.status)
    }

    func testThatSnapshotListCanBeParsed() throws {
        let vmList = try XCTUnwrap((JSONDecoder().decode(CodableVMSnapshotList.self, from: getJSONDataForResource(named: "vm-snapshot-list"))))
        XCTAssertEqual(vmList.count, 1)
    }

    func testThatSnapshotListWorks() throws {
        let runner = TestCommandRunner(response: getJSONResource(named: "vm-snapshot-list"))
        let vmList = try StoppedVM(uuid: "machine-uuid", name: "machine-name").getSnapshots(runner: runner)
        XCTAssertEqual(vmList.count, 1)
        XCTAssertEqual(vmList.first?.uuid, "{64d481bb-ce04-45b1-8328-49e4e4c43ddf}")
        XCTAssertEqual(vmList.first?.name, "Snapshot for linked clone")
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
}
