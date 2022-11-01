import XCTest
@testable import prlctl

final class VMSettingsTests: XCTestCase {

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

    func testThatSetSmartMountToOnWorks() throws {
        let runner = TestCommandRunner()
        let vm = StoppedVM(uuid: "machine-uuid", name: "machine-name")
        try vm.set(.smartMount(.on), runner: runner)
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --smart-mount on")
    }

    func testThatSetSmartMountToOffWorks() throws {
        let runner = TestCommandRunner()
        let vm = StoppedVM(uuid: "machine-uuid", name: "machine-name")
        try vm.set(.smartMount(.off), runner: runner)
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --smart-mount off")
    }

    func testThatSetSharedClipboardToOnWorks() throws {
        let runner = TestCommandRunner()
        let vm = StoppedVM(uuid: "machine-uuid", name: "machine-name")
        try vm.set(.sharedClipboard(.on), runner: runner)
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --shared-clipboard on")
    }

    func testThatSetSharedClipboardToOffWorks() throws {
        let runner = TestCommandRunner()
        let vm = StoppedVM(uuid: "machine-uuid", name: "machine-name")
        try vm.set(.sharedClipboard(.off), runner: runner)
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --shared-clipboard off")
    }

    func testThatSetSharedCloudToOnWorks() throws {
        let runner = TestCommandRunner()
        let vm = StoppedVM(uuid: "machine-uuid", name: "machine-name")
        try vm.set(.sharedCloud(.on), runner: runner)
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --shared-cloud on")
    }

    func testThatSetSharedCloudToOffWorks() throws {
        let runner = TestCommandRunner()
        let vm = StoppedVM(uuid: "machine-uuid", name: "machine-name")
        try vm.set(.sharedCloud(.off), runner: runner)
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --shared-cloud off")
    }

    func testThatSetSharedProfileToOnWorks() throws {
        let runner = TestCommandRunner()
        let vm = StoppedVM(uuid: "machine-uuid", name: "machine-name")
        try vm.set(.sharedProfile(.on), runner: runner)
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --shared-profile on")
    }

    func testThatSetSharedProfileToOffWorks() throws {
        let runner = TestCommandRunner()
        let vm = StoppedVM(uuid: "machine-uuid", name: "machine-name")
        try vm.set(.sharedProfile(.off), runner: runner)
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --shared-profile off")
    }

    func testThatSetSharedCameraToOnWorks() throws {
        let runner = TestCommandRunner()
        let vm = StoppedVM(uuid: "machine-uuid", name: "machine-name")
        try vm.set(.sharedCamera(.on), runner: runner)
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --auto-share-camera on")
    }

    func testThatSetSharedCameraToOffWorks() throws {
        let runner = TestCommandRunner()
        let vm = StoppedVM(uuid: "machine-uuid", name: "machine-name")
        try vm.set(.sharedCamera(.off), runner: runner)
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --auto-share-camera off")
    }

    func testThatSetSharedBluetoothToOnWorks() throws {
        let runner = TestCommandRunner()
        let vm = StoppedVM(uuid: "machine-uuid", name: "machine-name")
        try vm.set(.sharedBluetooth(.on), runner: runner)
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --auto-share-bluetooth on")
    }

    func testThatSetSharedBluetoothToOffWorks() throws {
        let runner = TestCommandRunner()
        let vm = StoppedVM(uuid: "machine-uuid", name: "machine-name")
        try vm.set(.sharedBluetooth(.off), runner: runner)
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --auto-share-bluetooth off")
    }

    func testThatSetSharedSmartcardToOnWorks() throws {
        let runner = TestCommandRunner()
        let vm = StoppedVM(uuid: "machine-uuid", name: "machine-name")
        try vm.set(.sharedSmartcard(.on), runner: runner)
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --auto-share-smart-card on")
    }

    func testThatSetSharedSmartcardToOffWorks() throws {
        let runner = TestCommandRunner()
        let vm = StoppedVM(uuid: "machine-uuid", name: "machine-name")
        try vm.set(.sharedSmartcard(.off), runner: runner)
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --auto-share-smart-card off")
    }

    func testThatSetVMisolationToOnWorks() throws {
        let runner = TestCommandRunner()
        let vm = StoppedVM(uuid: "machine-uuid", name: "machine-name")
        try vm.set(.isolateVM(.on), runner: runner)
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --isolate-vm on")
    }

    func testThatSetVMisolationToOffWorks() throws {
        let runner = TestCommandRunner()
        let vm = StoppedVM(uuid: "machine-uuid", name: "machine-name")
        try vm.set(.isolateVM(.off), runner: runner)
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --isolate-vm off")
    }

    func testThatWithoutSoundDeviceRemovesDefaultSoundDevice() throws {
        let runner = TestCommandRunner()
        let vm = StoppedVM(uuid: "machine-uuid", name: "machine-name")
        try vm.set(.withoutSoundDevice(), runner: runner)
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --device-del sound0")
    }

    func testThatWithoutSoundDeviceSpecifyingCustomDeviceHandleRemovesCorrectSoundDevice() throws {
        let runner = TestCommandRunner()
        let vm = StoppedVM(uuid: "machine-uuid", name: "machine-name")
        try vm.set(.withoutSoundDevice(handle: "sound1"), runner: runner)
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --device-del sound1")
    }

    func testThatWithoutCDROMDeviceRemovesDefaultCDROMDevice() throws {
        let runner = TestCommandRunner()
        let vm = StoppedVM(uuid: "machine-uuid", name: "machine-name")
        try vm.set(.withoutCDROMDevice(), runner: runner)
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --device-del cdrom0")
    }

    func testThatWithoutCDROMDeviceSpecifyingCustomDeviceHandleRemovesCorrectSoundDevice() throws {
        let runner = TestCommandRunner()
        let vm = StoppedVM(uuid: "machine-uuid", name: "machine-name")
        try vm.set(.withoutCDROMDevice(handle: "cdrom1"), runner: runner)
        XCTAssertEqual(runner.command, "prlctl set machine-uuid --device-del cdrom1")
    }
}
