import SwiftUI
import VisionKit
import Vision

struct ScreenshotScannerViewController: UIViewControllerRepresentable {
    @Binding var recognizedText: String
    @Binding var serverResponse: String // 新增這個屬性

    func makeCoordinator() -> Coordinator {
        Coordinator(recognizedText: $recognizedText, serverResponse: $serverResponse)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scannerVC = VNDocumentCameraViewController()
        scannerVC.delegate = context.coordinator
        return scannerVC
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        @Binding var recognizedText: String
        @Binding var serverResponse: String

        init(recognizedText: Binding<String>, serverResponse: Binding<String>) {
            _recognizedText = recognizedText
            _serverResponse = serverResponse
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            if scan.pageCount > 0 {
                let image = scan.imageOfPage(at: 0).cgImage
                recognizeText(from: image!)
            }
            controller.dismiss(animated: true)
        }

        func recognizeText(from image: CGImage) {
            let requestHandler = VNImageRequestHandler(cgImage: image, options: [:])
            let request = VNRecognizeTextRequest { (request, error) in
                if let observations = request.results as? [VNRecognizedTextObservation] {
                    let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
                    DispatchQueue.main.async {
                        var text = recognizedStrings.joined(separator: "\n")
                        text = text.replacingOccurrences(of: "\n", with: " ")
                        self.recognizedText = text
                    }
                }
            }
            request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"]
            try? requestHandler.perform([request])
        }

        
    }
}
