import SwiftUI
import Vision
import PhotosUI


struct ImageView: View {
    @State private var recognizedText = ""
    @State private var showImagePicker = false
    @State private var image: UIImage? = nil
    @State private var serverResponse = ""
    @State private var keyboardHeight: CGFloat = 0
    @State private var showAlert = false
    
    @Binding var logs: [LogEntry] // 綁定到父視圖中的 logs
    @ObservedObject var ipStore: IPAddressStore
    var body: some View {
        NavigationView {
            VStack {
                // Image display
                HStack {
                    Text("伺服器 IP:")
                    TextField("輸入 IP 地址", text: $ipStore.ipAddress)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad) // 使用數字鍵盤
                        .frame(width: 200)
                }
                .padding()
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: 550)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 300, height: 300)
                        .cornerRadius(20)
                        .overlay(Text("請選擇圖片").foregroundColor(.gray))
                    
                }
                
                if !recognizedText.isEmpty {
                    TextEditor(text: $recognizedText)
                        .frame(height: 120)
                        .padding()
                        .border(Color.gray, width: 1)
                        .cornerRadius(20)
                }
                
                HStack {
                    Button(action: {
                        showImagePicker = true
                    }) {
                        Text("選擇圖片")
                            .padding()
                            .buttonStyle(.borderless)
                            .controlSize(.regular)
                            .buttonBorderShape(.automatic)
                            .tint(.yellow)
                    }
                    Spacer()
                    
                    Button(action: {
                        sendTextToServer(recognizedText)
                    }) {
                        Text("發送")
                            .padding()
                            .buttonStyle(.borderless)
                            .controlSize(.regular)
                            .buttonBorderShape(.automatic)
                            .tint(.pink)
                    }
                }
                .padding()
                
            }
            .padding()
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $image, onImagePicked: scanImage)
            }
            .contentShape(Rectangle())
                    .onTapGesture {
                        UIApplication.shared.endEditing() // 点击空白处关闭键盘
                    }
            .alert(isPresented: $showAlert) {
                Alert(title: Text(serverResponse), dismissButton: .default(Text("確定")))
            }
        }
    }

    // Function to recognize text from the selected image
    func scanImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { (request, error) in
            if let observations = request.results as? [VNRecognizedTextObservation] {
                let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
                DispatchQueue.main.async {
                    recognizedText = recognizedStrings.joined(separator: "\n")
                }
            }
        }
        request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"]
        try? requestHandler.perform([request])
    }
    
    // Function to send recognized text to the server
    func sendTextToServer(_ text: String) {
        guard let url = URL(string: "http://\(ipStore.ipAddress):8888/str_request") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/plain; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        if let postData = text.data(using: .utf8) {
            request.httpBody = postData
        } else {
            print("無法將文字轉換為 UTF-8")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    serverResponse = "發送失敗: \(error.localizedDescription)"
                    showAlert = true
                }
                return
            }
            
            guard let data = data, let responseText = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async {
                    serverResponse = "無效的伺服器回應"
                    showAlert = true
                }
                return
            }
            
            DispatchQueue.main.async {
                serverResponse = responseText
                logs.append(LogEntry(scannedText: text, serverResponse: responseText, timestamp: Date())) // 記錄到 logs 中
                showAlert = true
            }
        }.resume()
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onImagePicked: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    if let image = image as? UIImage {
                        DispatchQueue.main.async {
                            self.parent.image = image
                            self.parent.onImagePicked(image)
                        }
                    }
                }
            }
        }
    }
}

