import XCTest
@testable import prlctl

final class VMSettingsTests: XCTestCase {

    func testThatSetCPUCountWorks() async throws {
        let runner = TestCommandRunner()
        try await Parallels(runner: runner)
            .setVMOption(.cpuCount(24), onVirtualMachineWithHandle: "machine-uuid")
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --cpus 24")
    }

    func testThatSetMemorySizeWorks() async throws {
        let runner = TestCommandRunner()
        try await Parallels(runner: runner)
            .setVMOption(.memorySize(8192), onVirtualMachineWithHandle: "machine-uuid")
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --memsize 8192")
    }

    func testThatSetHypervisorTypeToParallelsWorks() async throws {
        let runner = TestCommandRunner()
        try await Parallels(runner: runner)
            .setVMOption(.hypervisorType(.parallels), onVirtualMachineWithHandle: "machine-uuid")
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --hypervisor-type parallels")
    }

    func testThatSetHypervisorTypeToAppleWorks() async throws {
        let runner = TestCommandRunner()
        try await Parallels(runner: runner)
            .setVMOption(.hypervisorType(.apple), onVirtualMachineWithHandle: "machine-uuid")
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --hypervisor-type apple")
    }

    func testThatSetNetworkInterfaceTypeToSharedWorks() async throws {
        let runner = TestCommandRunner()
        try await Parallels(runner: runner)
            .setVMOption(.networkType(.shared), onVirtualMachineWithHandle: "machine-uuid")
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --device-set net0 --type shared")
    }

    func testThatSetNetworkInterfaceTypeToBridgedWorks() async throws {
        let runner = TestCommandRunner()
        try await Parallels(runner: runner)
            .setVMOption(.networkType(.bridged), onVirtualMachineWithHandle: "machine-uuid")
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --device-set net0 --type bridged")
    }

    func testThatSetNetworkInterfaceTypeToHostOnlyWorks() async throws {
        let runner = TestCommandRunner()
        try await Parallels(runner: runner)
            .setVMOption(.networkType(.hostOnly), onVirtualMachineWithHandle: "machine-uuid")
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --device-set net0 --type host-only")
    }

    func testThatSetSmartMountToOnWorks() async throws {
        let runner = TestCommandRunner()
        try await Parallels(runner: runner)
            .setVMOption(.smartMount(.on), onVirtualMachineWithHandle: "machine-uuid")
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --smart-mount on")
    }

    func testThatSetSmartMountToOffWorks() async throws {
        let runner = TestCommandRunner()
        try await Parallels(runner: runner)
            .setVMOption(.smartMount(.off), onVirtualMachineWithHandle: "machine-uuid")
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --smart-mount off")
    }

    func testThatSetSharedClipboardToOnWorks() async throws {
        let runner = TestCommandRunner()
        try await Parallels(runner: runner)
            .setVMOption(.sharedClipboard(.on), onVirtualMachineWithHandle: "machine-uuid")
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --shared-clipboard on")
    }

    func testThatSetSharedClipboardToOffWorks() async throws {
        let runner = TestCommandRunner()
        try await Parallels(runner: runner)
            .setVMOption(.sharedClipboard(.off), onVirtualMachineWithHandle: "machine-uuid")
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --shared-clipboard off")
    }

    func testThatSetSharedCloudToOnWorks() async throws {
        let runner = TestCommandRunner()
        try await Parallels(runner: runner)
            .setVMOption(.sharedCloud(.on), onVirtualMachineWithHandle: "machine-uuid")
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --shared-cloud on")
    }

    func testThatSetSharedCloudToOffWorks() async throws {
        let runner = TestCommandRunner()
        try await Parallels(runner: runner)
            .setVMOption(.sharedCloud(.off), onVirtualMachineWithHandle: "machine-uuid")
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --shared-cloud off")
    }

    func testThatSetSharedProfileToOnWorks() async throws {
        let runner = TestCommandRunner()
        try await Parallels(runner: runner)
            .setVMOption(.sharedProfile(.on), onVirtualMachineWithHandle: "machine-uuid")
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --shared-profile on")
    }

    func testThatSetSharedProfileToOffWorks() async throws {
        let runner = TestCommandRunner()
        try await Parallels(runner: runner)
            .setVMOption(.sharedProfile(.off), onVirtualMachineWithHandle: "machine-uuid")
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --shared-profile off")
    }

    func testThatSetSharedCameraToOnWorks() async throws {
        let runner = TestCommandRunner()
        try await Parallels(runner: runner)
            .setVMOption(.sharedCamera(.on), onVirtualMachineWithHandle: "machine-uuid")
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --auto-share-camera on")
    }

    func testThatSetSharedCameraToOffWorks() async throws {
        let runner = TestCommandRunner()
        try await Parallels(runner: runner)
            .setVMOption(.sharedCamera(.off), onVirtualMachineWithHandle: "machine-uuid")
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --auto-share-camera off")
    }

    func testThatSetSharedBluetoothToOnWorks() async throws {
        let runner = TestCommandRunner()
        try await Parallels(runner: runner)
            .setVMOption(.sharedBluetooth(.on), onVirtualMachineWithHandle: "machine-uuid")
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --auto-share-bluetooth on")
    }

    func testThatSetSharedBluetoothToOffWorks() async throws {
        let runner = TestCommandRunner()
        try await Parallels(runner: runner)
            .setVMOption(.sharedBluetooth(.off), onVirtualMachineWithHandle: "machine-uuid")
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --auto-share-bluetooth off")
    }

    func testThatSetSharedSmartcardToOnWorks() async throws {
        let runner = TestCommandRunner()
        try await Parallels(runner: runner)
            .setVMOption(.sharedSmartcard(.on), onVirtualMachineWithHandle: "machine-uuid")
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --auto-share-smart-card on")
    }

    func testThatSetSharedSmartcardToOffWorks() async throws {
        let runner = TestCommandRunner()
        try await Parallels(runner: runner)
            .setVMOption(.sharedSmartcard(.off), onVirtualMachineWithHandle: "machine-uuid")
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --auto-share-smart-card off")
    }

    func testThatSetVMisolationToOnWorks() async throws {
        let runner = TestCommandRunner()
        try await Parallels(runner: runner)
            .setVMOption(.isolateVM(.on), onVirtualMachineWithHandle: "machine-uuid")
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --isolate-vm on")
    }

    func testThatSetVMisolationToOffWorks() async throws {
        let runner = TestCommandRunner()
        try await Parallels(runner: runner)
            .setVMOption(.isolateVM(.off), onVirtualMachineWithHandle: "machine-uuid")
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --isolate-vm off")
    }

    func testThatWithoutSoundDeviceRemovesDefaultSoundDevice() async throws {
        let runner = TestCommandRunner()
        try await Parallels(runner: runner)
            .setVMOption(.withoutSoundDevice(), onVirtualMachineWithHandle: "machine-uuid")
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --device-del sound0")
    }

    func testThatWithoutSoundDeviceSpecifyingCustomDeviceHandleRemovesCorrectSoundDevice() async throws {
        let runner = TestCommandRunner()
        try await Parallels(runner: runner)
            .setVMOption(.withoutSoundDevice(handle: "sound1"), onVirtualMachineWithHandle: "machine-uuid")
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --device-del sound1")
    }

    func testThatWithoutCDROMDeviceRemovesDefaultCDROMDevice() async throws {
        let runner = TestCommandRunner()
            try await Parallels(runner: runner)
            .setVMOption(.withoutCDROMDevice(), onVirtualMachineWithHandle: "machine-uuid")
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --device-del cdrom0")
    }

    func testThatWithoutCDROMDeviceSpecifyingCustomDeviceHandleRemovesCorrectSoundDevice() async throws {
        let runner = TestCommandRunner()
        try await Parallels(runner: runner)
            .setVMOption(.withoutCDROMDevice(handle: "cdrom1"), onVirtualMachineWithHandle: "machine-uuid")
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --device-del cdrom1")
    }
}
