
import AVFoundation
import UIKit

enum CaptureKind: String, Codable {
    case photo
    case video
}

@MainActor
final class CameraController: NSObject {
    static let shared = CameraController()

    private let session = AVCaptureSession()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private let photoOutput = AVCapturePhotoOutput()
    private let movieOutput = AVCaptureMovieFileOutput()

    private var isConfigured = false
    private var isAuthorized = false

    func checkPermissions() async -> Bool {
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch cameraStatus {
        case .authorized:
            isAuthorized = true
        case .notDetermined:
            isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        default:
            isAuthorized = false
        }
        return isAuthorized
    }

    func configureIfNeeded() throws {
        guard !isConfigured else { return }
        session.beginConfiguration()
        session.sessionPreset = .high

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoInput) else {
            session.commitConfiguration()
            throw NSError(domain: "Camera", code: -1, userInfo: [NSLocalizedDescriptionKey: "Cannot add camera input"])
        }
        session.addInput(videoInput)
        self.videoDeviceInput = videoInput

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
        }
        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
        }

        session.commitConfiguration()
        isConfigured = true
    }

    func attachPreview(to layer: AVCaptureVideoPreviewLayer) {
        layer.session = session
        layer.videoGravity = .resizeAspectFill
    }

    func startRunning() {
        guard isAuthorized else { return }
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
            }
        }
    }

    func stopRunning() {
        if session.isRunning {
            session.stopRunning()
        }
    }

    func capturePhoto(mediaStore: MediaStore) async {
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true

        let delegate = PhotoCaptureDelegate { data in
            guard let data = data else { return }
            Task {
                await mediaStore.savePhotoData(data)
            }
        }
        photoOutput.capturePhoto(with: settings, delegate: delegate)
    }

    func toggleVideoRecording(mediaStore: MediaStore) async {
        if movieOutput.isRecording {
            movieOutput.stopRecording()
        } else {
            let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mov")
            movieOutput.startRecording(to: tmpURL, recordingDelegate: self)
            self.pendingMediaStore = mediaStore
        }
    }

    // Remote capture from Watch
    func handleRemoteCapture(kind: CaptureKind, mediaStore: MediaStore) async {
        guard await checkPermissions() else { return }
        do { try configureIfNeeded() } catch { return }
        startRunning()
        switch kind {
        case .photo:
            await capturePhoto(mediaStore: mediaStore)
        case .video:
            await toggleVideoRecording(mediaStore: mediaStore)
        }
    }

    // MARK: private
    private var pendingMediaStore: MediaStore?
}

private final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (Data?) -> Void
    init(completion: @escaping (Data?) -> Void) { self.completion = completion }

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        if let data = photo.fileDataRepresentation() {
            completion(data)
        } else {
            completion(nil)
        }
    }
}

extension CameraController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        guard let store = pendingMediaStore else { return }
        Task { await store.saveVideoAtURL(outputFileURL) }
        pendingMediaStore = nil
    }
}
