
import Foundation
import WatchConnectivity
import UIKit
import Combine

final class WCManager: NSObject, ObservableObject {
    static let shared = WCManager()

    private let session = WCSession.isSupported() ? WCSession.default : nil

    // Incoming closures set by the app
    var onCaptureRequest: ((CaptureKind) -> Void)?
    var onSyncRequest: (() -> Void)?

    func activate() {
        session?.delegate = self
        session?.activate()
    }

    func sendCaptureRequest(_ kind: CaptureKind) {
        let msg = ["action": "capture", "kind": kind.rawValue]
        session?.sendMessage(msg, replyHandler: nil, errorHandler: nil)
    }

    func requestSync() {
        let msg = ["action": "sync"]
        session?.sendMessage(msg, replyHandler: nil, errorHandler: nil)
    }

    // Push thumbnails and index to watch
    @MainActor
    func pushThumbnails(from store: MediaStore) async {
        guard let session else { return }
        let items = store.items.map {
            ["id": $0.id.uuidString,
             "type": $0.type.rawValue,
             "thumb": $0.thumbnailFilename,
             "file": $0.url.lastPathComponent,
             "createdAt": $0.createdAt.timeIntervalSince1970] as [String : Any]
        }
        session.sendMessage(["action": "index", "items": items], replyHandler: nil, errorHandler: nil)

        for it in store.items.prefix(30) {
            if FileManager.default.fileExists(atPath: it.thumbnailURL.path) {
                session.transferFile(it.thumbnailURL, metadata: ["thumb": it.thumbnailFilename])
            }
        }
    }
}

extension WCManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    #endif

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let action = message["action"] as? String {
            switch action {
            case "capture":
                if let raw = message["kind"] as? String, let kind = CaptureKind(rawValue: raw) {
                    DispatchQueue.main.async { self.onCaptureRequest?(kind) }
                }
            case "sync":
                DispatchQueue.main.async { self.onSyncRequest?() }
            case "requestFile":
                if let name = message["name"] as? String {
                    let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Media")
                    let url = docs.appendingPathComponent(name)
                    if FileManager.default.fileExists(atPath: url.path) {
                        session.transferFile(url, metadata: ["name": name])
                    }
                }
            default: break
            }
        }
    }
}
