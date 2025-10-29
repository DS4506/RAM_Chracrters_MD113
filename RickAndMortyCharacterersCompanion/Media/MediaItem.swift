
import Foundation
import UIKit
import AVFoundation

enum MediaType: String, Codable {
    case photo
    case video
}

struct MediaItem: Identifiable, Codable, Equatable {
    let id: UUID
    let type: MediaType
    let url: URL
    let thumbnailFilename: String
    let createdAt: Date

    var thumbnailURL: URL {
        url.deletingLastPathComponent().appendingPathComponent(thumbnailFilename)
    }
}

enum MediaIOError: Error {
    case writeFailed
    case exportFailed
}
