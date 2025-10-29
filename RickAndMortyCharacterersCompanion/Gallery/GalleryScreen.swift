
import SwiftUI
import AVKit
import Combine

struct GalleryScreen: View {
    @EnvironmentObject private var mediaStore: MediaStore
    @State private var selection: MediaItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(mediaStore.items) { item in
                        ThumbnailView(item: item)
                            .onTapGesture { selection = item }
                            .contextMenu {
                                Button(role: .destructive) {
                                    mediaStore.delete(item)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .padding(8)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Media")
            .sheet(item: $selection) { item in
                Viewer(item: item)
                    .presentationDetents([.medium, .large])
            }
        }
    }
}

private struct ThumbnailView: View {
    let item: MediaItem
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if let img = UIImage(contentsOfFile: item.thumbnailURL.path) {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .frame(height: 110)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 10).fill(.gray.opacity(0.3)).frame(height: 110)
            }
            if item.type == .video {
                Image(systemName: "play.fill")
                    .padding(6)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .padding(6)
            }
        }
    }
}

private struct Viewer: View {
    let item: MediaItem
    var body: some View {
        switch item.type {
        case .photo:
            if let img = UIImage(contentsOfFile: item.url.path) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .background(Theme.background)
            }
        case .video:
            VideoPlayer(player: AVPlayer(url: item.url))
                .background(.black)
        }
    }
}
