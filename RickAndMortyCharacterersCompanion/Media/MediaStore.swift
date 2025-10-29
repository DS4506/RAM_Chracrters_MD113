
import Foundation
import UIKit
import AVFoundation
import Combine

@MainActor
final class MediaStore: ObservableObject {
    @Published private(set) var items: [MediaItem] = []

    private let fm = FileManager.default
    private let mediaDir: URL
    private let maxItems = 120

    init() {
        mediaDir = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Media", isDirectory: true)
        try? fm.createDirectory(at: mediaDir, withIntermediateDirectories: true)
    }

    func load() {
        let jsonURL = mediaDir.appendingPathComponent("index.json")
        if let data = try? Data(contentsOf: jsonURL),
           let decoded = try? JSONDecoder().decode([MediaItem].self, from: data) {
            self.items = decoded.sorted { $0.createdAt > $1.createdAt }
        } else {
            self.items = []
        }
    }

    private func persist() {
        let jsonURL = mediaDir.appendingPathComponent("index.json")
        if let data = try? JSONEncoder().encode(items) {
            try? data.write(to: jsonURL, options: .atomic)
        }
    }

    func savePhotoData(_ data: Data) async {
        let id = UUID()
        let photoURL = mediaDir.appendingPathComponent("\(id).jpg")
        let thumbURL = mediaDir.appendingPathComponent("\(id)_thumb.jpg")
        guard let img = UIImage(data: data),
              let jpeg = img.jpegData(compressionQuality: 0.76) else { return }
        do {
            try jpeg.write(to: photoURL, options: .atomic)
            if let thumb = img.resized(maxSide: 320)?.jpegData(compressionQuality: 0.7) {
                try thumb.write(to: thumbURL, options: .atomic)
            }
            let item = MediaItem(id: id, type: .photo, url: photoURL, thumbnailFilename: "\(id)_thumb.jpg", createdAt: Date())
            items.insert(item, at: 0)
            capIfNeeded()
            persist()
        } catch { }
    }

    func saveVideoAtURL(_ tempURL: URL) async {
        let id = UUID()
        let outURL = mediaDir.appendingPathComponent("\(id).mov")
        do {
            try fm.moveItem(at: tempURL, to: outURL)
        } catch {
            await exportVideo(input: tempURL, output: outURL)
        }
        let thumbURL = mediaDir.appendingPathComponent("\(id)_thumb.jpg")
        if let thumb = VideoThumbnailer.thumbnail(for: outURL),
           let data = thumb.jpegData(compressionQuality: 0.7) {
            try? data.write(to: thumbURL, options: .atomic)
        }
        let item = MediaItem(id: id, type: .video, url: outURL, thumbnailFilename: "\(id)_thumb.jpg", createdAt: Date())
        items.insert(item, at: 0)
        capIfNeeded()
        persist()
    }

    func delete(_ item: MediaItem) {
        try? fm.removeItem(at: item.url)
        try? fm.removeItem(at: item.thumbnailURL)
        if let idx = items.firstIndex(of: item) {
            items.remove(at: idx)
            persist()
        }
    }

    private func capIfNeeded() {
        if items.count > maxItems {
            for extra in items.suffix(from: maxItems) {
                delete(extra)
            }
            items = Array(items.prefix(maxItems))
        }
    }

    private func exportVideo(input: URL, output: URL) async {
        let asset = AVURLAsset(url: input)
        guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) else { return }
        exporter.outputURL = output
        exporter.outputFileType = .mov
        await withCheckedContinuation { cont in
            exporter.exportAsynchronously { cont.resume() }
        }
        try? FileManager.default.removeItem(at: input)
    }
}
