
import Foundation

enum Disk {
    static func spaceRemaining() -> UInt64 {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last ?? NSTemporaryDirectory()
        do {
            let attrs = try FileManager.default.attributesOfFileSystem(forPath: path)
            return attrs[.systemFreeSize] as? UInt64 ?? 0
        } catch { return 0 }
    }

    static func spaceRemainingFormatted() -> String {
        let bytes = Double(spaceRemaining())
        let mb = bytes / (1024 * 1024)
        if mb > 1024 {
            return String(format: "%.1f GB", mb / 1024)
        }
        return String(format: "%.0f MB", mb)
    }
}
