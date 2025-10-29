
import SwiftUI
import Combine

@main
struct RickAndMortyCharacterersCompanionApp: App {
    @StateObject private var mediaStore = MediaStore()
    @StateObject private var wcManager = WCManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(mediaStore)
                .onAppear {
                    wcManager.activate()
                    wcManager.onCaptureRequest = { kind in
                        Task { await CameraController.shared.handleRemoteCapture(kind: kind, mediaStore: mediaStore) }
                    }
                    wcManager.onSyncRequest = {
                        Task { await wcManager.pushThumbnails(from: mediaStore) }
                    }
                }
        }
    }
}
