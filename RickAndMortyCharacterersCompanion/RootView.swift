
import SwiftUI

struct RootView: View {
    @EnvironmentObject private var mediaStore: MediaStore
    var body: some View {
        TabView {
            CameraScreen()
                .tabItem { Label("Camera", systemImage: "camera") }
            GalleryScreen()
                .tabItem { Label("Gallery", systemImage: "photo.on.rectangle") }
            SettingsScreen()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(Theme.accent)
        .onAppear {
            mediaStore.load()
        }
    }
}
