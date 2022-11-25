import Foundation

public enum VMOption {
    case cpuCount(_ newCount: Int)
    case memorySize(_ megabytes: Int)
    case hypervisorType(_ type: HypervisorType)
    case networkType(_ type: NetworkType, interface: String = "net0")
    case smartMount(_ state: State)
    case sharedClipboard(_ state: State)
    case sharedCloud(_ state: State)
    case sharedProfile(_ state: State)
    case sharedCamera(_ state: State)
    case sharedBluetooth(_ state: State)
    case sharedSmartcard(_ state: State)
    case isolateVM(_ state: State)
    case withoutSoundDevice(handle: String = "sound0")
    case withoutCDROMDevice(handle: String = "cdrom0")
}

public enum State: String {
    case on
    case off
}

public enum HypervisorType: String {
    case parallels
    case apple
}

public enum NetworkType: String {
    case shared = "shared"
    case bridged = "bridged"
    case hostOnly = "host-only"
}
