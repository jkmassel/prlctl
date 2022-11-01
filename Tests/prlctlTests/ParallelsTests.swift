import Foundation
import XCTest
@testable import prlctl

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}

final class ParallelsTests: XCTestCase {

    func testThatLookupAllVMsIsEmptyForNoVMs() throws {
        let parallels = Parallels(runner: TestCommandRunner(responses: [
            "prlctl list --json --full --all": "[]",
            "prlctl list --json --full --all --info": "[]"
        ]))

        XCTAssertTrue(try parallels.lookupAllVMs().isEmpty)
    }

    func testThatLookupAllVMsThrowsForInvalidJSON() throws {
        let parallels = Parallels(runner: TestCommandRunner(responses: [
            "prlctl list --json --full --all": "foo",
            "prlctl list --json --full --all --info": "[]"
        ]))

        XCTAssertThrowsError(try parallels.lookupAllVMs())
    }

    func testThatInvalidVMsCanBeLookedUp() throws {
        let parallels = try getParallelsWithTestData()
        XCTAssertEqual(1, try parallels.lookupInvalidVMs().count)
    }

    func testThatPackagedVMsCanBeLookedUp() throws {
        let parallels = try getParallelsWithTestData()
        XCTAssertEqual(1, try parallels.lookupPackagedVMs().count)
    }

    func testThatResumingVMsCanBeLookedUp() throws {
        let parallels = try getParallelsWithTestData()
        XCTAssertEqual(1, try parallels.lookupResumingVMs().count)
    }

    func testThatRunningVMsCanBeLookedUp() throws {
        let parallels = try getParallelsWithTestData()
        XCTAssertEqual(3, try parallels.lookupRunningVMs().count)
    }

    func testThatStoppedVMsCanBeLookedUp() throws {
        let parallels = try getParallelsWithTestData()
        XCTAssertEqual(1, try parallels.lookupStoppedVMs().count)
    }

    func testThatSuspendedVMsCanBeLookedUp() throws {
        let parallels = try getParallelsWithTestData()
        XCTAssertEqual(1, try parallels.lookupSuspendedVMs().count)
    }

    func testThatLookupVMReturnsNilForInvalidHandle() throws {
        let parallels = try getParallelsWithTestData()
        let vm = try parallels.lookupVM(named: "invalid-vm-handle")
        XCTAssertNil(vm)
    }

    func testThatLookupVMReturnsPackagedVM() throws {
        let parallels = try getParallelsWithTestData()
        let vm = try parallels.lookupVM(named: "packaged-vm")
        XCTAssertNotNil(vm?.asPackagedVM())
    }

    func testThatLookupVMReturnsResumingVM() throws {
        let parallels = try getParallelsWithTestData()
        let vm = try parallels.lookupVM(named: "resuming-vm")
        XCTAssertNotNil(vm?.asResumingVM())
    }

    func testThatLookupVMReturnsRunningVM() throws {
        let parallels = try getParallelsWithTestData()
        let vm = try parallels.lookupVM(named: "running-vm-with-ip")
        XCTAssertNotNil(vm?.asRunningVM())
    }

    func testThatLookupVMReturnsRunningIPV6VM() throws {
        let parallels = try getParallelsWithTestData()
        let vm = try parallels.lookupVM(named: "running-vm-with-ipv6")
        XCTAssertNotNil(vm?.asRunningVM())
    }

    func testThatLookupVMReturnsStoppedVM() throws {
        let parallels = try getParallelsWithTestData()
        let vm = try parallels.lookupVM(named: "stopped-vm")
        XCTAssertNotNil(vm?.asStoppedVM())
    }

    func testThatLookupVMReturnsSuspendedVM() throws {
        let parallels = try getParallelsWithTestData()
        let vm = try parallels.lookupVM(named: "suspended-vm")
        XCTAssertNotNil(vm?.asSuspendedVM())
    }

    func testThatLicenseActivationWorks() throws {
        let runner = TestCommandRunner()
        try Parallels(runner: runner).serviceControl.installLicense(key: "key", company: "company")
        XCTAssertEqual(
            runner.command,
            "prlsrvctl install-license -k key --company company --activate-online-immediately"
        )
    }

    func testThatRegisterVMWorks() throws {
        let runner = TestCommandRunner()
        try Parallels(runner: runner).registerVM(at: URL(fileURLWithPath: "/dev/null"))
        XCTAssertEqual(runner.command, "prlctl register /dev/null --preserve-uuid=no")
    }

    func testThatUnregisterVMWorks() throws {
        let runner = TestCommandRunner()
        try Parallels(runner: runner).unregisterVM(handle: "foo")
        XCTAssertEqual(runner.command, "prlctl unregister foo")
    }

    private func getParallelsWithTestData() throws -> Parallels {
        return Parallels(runner: TestCommandRunner(responses: [
            "prlctl list --json --full --all": try getVMList(),
            "prlctl list --json --full --all --info": try getVMDetails()
        ]))
    }

    private let testVMNames = [
        "invalid-vm",
        "packaged-vm",
        "running-vm-with-ip",
        "running-vm-with-ipv6",
        "running-vm-without-ip",
        "stopped-vm",
        "suspended-vm",
        "resuming-vm"
    ]

    private func getVMList() throws -> String {
        let vms = try testVMNames
            .compactMap { getJSONResource(named: $0).data(using: .utf8) }
            .map { try JSONDecoder().decode(CodableVM.self, from: $0) }

        let data = try JSONEncoder().encode(vms)
        return String(data: data, encoding: .utf8)!
    }

    private func getVMDetails() throws -> String {
        let vms = try testVMNames
            .map { $0.appending("-details") }
            .compactMap { getJSONResource(named: $0).data(using: .utf8) }
            .map { try JSONDecoder().decode(VMDetails.self, from: $0) }

        let data = try JSONEncoder().encode(vms)
        return String(data: data, encoding: .utf8)!
    }
}

extension XCTestCase {

    struct VMTestData {
        let info: Data
        let details: Data

        func parse() throws -> VM? {
            let info = try JSONDecoder().decode(CodableVM.self, from: self.info)
            let details = try JSONDecoder().decode(VMDetails.self, from: self.details)

            return VM(vm: info, details: details)
        }
    }

    func codableVMResource(named name: String) throws -> CodableVM? {
        try JSONDecoder().decode(CodableVM.self, from: getJSONDataForResource(named: name))
    }

    func codableVMListResource(named name: String) throws -> CodableVMSnapshotList? {
        try JSONDecoder().decode(CodableVMSnapshotList.self, from: getJSONDataForResource(named: name))
    }

    func vmDetailsResource(named name: String) throws -> VMDetails? {
        try JSONDecoder().decode(VMDetails.self, from: getJSONDataForResource(named: name))
    }

    func getVmDataFrom(infoKey: String, detailsKey: String) -> VMTestData {
        let infoData = getJSONDataForResource(named: infoKey)
        let detailsData = getJSONDataForResource(named: detailsKey)

        return VMTestData(info: infoData, details: detailsData)
    }

    func getJSONDataForResource(named key: String) -> Data {
        let path = Bundle.module.path(forResource: key, ofType: "json")!
        return FileManager.default.contents(atPath: path)!
    }

    func getJSONResource(named key: String) -> String {
        let data = getJSONDataForResource(named: key)
        return String(data: data, encoding: .utf8)!
    }
}

extension RunningVM {
    static var testCase: RunningVM {
        RunningVM(uuid: "machine-uuid", name: "machine-name", ipAddress: "127.0.0.1")
    }
}
