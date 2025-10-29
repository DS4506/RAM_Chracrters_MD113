
import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    func makeUIView(context: Context) -> Preview {
        let v = Preview()
        CameraController.shared.attachPreview(to: v.layer as! AVCaptureVideoPreviewLayer)
        return v
    }
    func updateUIView(_ uiView: Preview, context: Context) {}

    final class Preview: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    }
}
