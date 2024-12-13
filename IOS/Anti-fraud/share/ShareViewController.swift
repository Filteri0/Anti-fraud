import UIKit
import Social
import Vision
import VisionKit
import UserNotifications
import Combine

class ShareViewController: SLComposeServiceViewController {
    
    
    override func isContentValid() -> Bool {
        return true
    }

    override func didSelectPost() {
        if let content = extensionContext?.inputItems.first as? NSExtensionItem {
            if let attachments = content.attachments {
                for attachment in attachments {
                    if attachment.hasItemConformingToTypeIdentifier("public.image") {
                        attachment.loadItem(forTypeIdentifier: "public.image", options: nil) { (data, error) in
                            if let url = data as? URL, let imageData = try? Data(contentsOf: url), let image = UIImage(data: imageData)?.cgImage {
                                self.recognizeText(from: image)
                            } else if let image = data as? UIImage, let cgImage = image.cgImage {
                                self.recognizeText(from: cgImage)
                            }
                        }
                    }
                }
            }
        }
    }

    override func configurationItems() -> [Any]! {
        return []
    }

    func recognizeText(from image: CGImage) {
        let requestHandler = VNImageRequestHandler(cgImage: image, options: [:])
        let request = VNRecognizeTextRequest { (request, error) in
            if let observations = request.results as? [VNRecognizedTextObservation] {
                let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
                let text = recognizedStrings.joined(separator: " ")
                self.sendPostRequest(with: text)
            }
        }
        request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"]
        request.recognitionLevel = .accurate
        try? requestHandler.perform([request])
    }

    func sendPostRequest(with text: String) {
        guard let url = URL(string: "http://127.0.0.1:8888/str_request") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/plain; charset=utf-8", forHTTPHeaderField: "Content-Type")
        // 將文字轉換為 UTF-8 格式的 Data
        if let postData = text.data(using: .utf8) {
            request.httpBody = postData
        } else {
            print("無法將文字轉換為 UTF-8")
            return
        }
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }

            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                self.showNotification(with: responseString)
            }

            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }.resume()
    }

    func showNotification(with message: String) {
        let content = UNMutableNotificationContent()
        content.title = message
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing notification: \(error)")
            }
        }
    }
}
