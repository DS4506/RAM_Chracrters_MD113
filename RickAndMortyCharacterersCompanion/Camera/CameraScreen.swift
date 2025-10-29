
import SwiftUI
import AVFoundation

struct CameraScreen: View {
    @EnvironmentObject private var mediaStore: MediaStore
    @State private var isRecording = false
    @State private var blockedByStorage = false
    @State private var toastText: String?

    var body: some View {
        ZStack {
            CameraPreviewView()
                .ignoresSafeArea()

            VStack {
                Spacer()
                Card {
                    VStack(spacing: 12) {
                        if blockedByStorage {
                            Text("Storage is low. Please free space before capturing.")
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }

                        HStack(spacing: 12) {
                            Button {
                                Task { await takePhoto() }
                            } label: {
                                Label("Photo", systemImage: "camera.circle.fill")
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(blockedByStorage)

                            Button {
                                Task { await toggleVideo() }
                            } label: {
                                Label(isRecording ? "Stop" : "Video",
                                      systemImage: isRecording ? "stop.circle.fill" : "record.circle.fill")
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(blockedByStorage)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .onAppear {
            Task {
                let ok = await CameraController.shared.checkPermissions()
                if ok {
                    do { try CameraController.shared.configureIfNeeded() } catch {}
                    CameraController.shared.startRunning()
                }
            }
            updateStorageFlag()
        }
        .onDisappear {
            CameraController.shared.stopRunning()
        }
        .toast($toastText)
    }

    private func updateStorageFlag() {
        blockedByStorage = Disk.spaceRemaining() < 200 * 1024 * 1024     // 200 MB guard
    }

    private func takePhoto() async {
        guard !blockedByStorage else { return }
        await CameraController.shared.capturePhoto(mediaStore: mediaStore)
        toastText = "Image saved"
        updateStorageFlag()
        await WCManager.shared.pushThumbnails(from: mediaStore)
    }

    private func toggleVideo() async {
        guard !blockedByStorage else { return }
        isRecording.toggle()
        await CameraController.shared.toggleVideoRecording(mediaStore: mediaStore)
        if !isRecording {
            toastText = "Video recorded"
            updateStorageFlag()
            await WCManager.shared.pushThumbnails(from: mediaStore)
        }
    }
}
