
import SwiftUI
import Combine

struct SettingsScreen: View {
    @EnvironmentObject private var mediaStore: MediaStore
    @State private var caption: String = ""

    var body: some View {
        Form {
            Section("Info") {
                Text("Items stored: \(mediaStore.items.count)")
                Text("Free space: \(Disk.spaceRemainingFormatted())")
            }
            Section("Share last item") {
                if let item = mediaStore.items.first {
                    ShareLink(item: item.url, preview: SharePreview("Latest Media"))
                } else {
                    Text("No items yet.")
                }
            }
            Section("Custom caption") {
                TextField("Optional caption to include when sharing", text: $caption)
                    .textInputAutocapitalization(.sentences)
                if let item = mediaStore.items.first {
                    ShareLink("Share with caption", item: item.url, message: Text(caption))
                }
            }
        }
        .navigationTitle("Settings")
    }
}
