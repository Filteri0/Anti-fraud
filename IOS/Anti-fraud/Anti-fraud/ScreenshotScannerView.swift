import SwiftUI

struct ScreenshotScannerView: View {
    @State private var recognizedText = ""
    @State private var showScanner = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var reloadView = false
    @Binding var logs: [LogEntry] // 綁定到父視圖中的 logs
    @ObservedObject var ipStore: IPAddressStore
    var body: some View {
        NavigationView {
            
        VStack {
            
            ScreenshotScannerViewController(recognizedText: $recognizedText,serverResponse: $alertMessage)
                .frame(height: 680)
                .padding(.top,53)
            HStack {
                Button(action: {
                    showScanner.toggle()
                }) {
                    Text("擷取的文字")
                        .buttonStyle(.borderless)
                        .controlSize(.regular)
                        .buttonBorderShape(.automatic)
                        .tint(.mint)
                }
                
                Spacer()
                
                Button(action: {
                    sendTextToServer(recognizedText)
                }) {
                    Spacer()
                    Text("發送")
                        .padding()
                        .buttonStyle(.borderless)
                        .controlSize(.regular)
                        .buttonBorderShape(.automatic)
                        .tint(.purple)
                }
            }
            
            .padding([.leading, .trailing])
            
            .sheet(isPresented: $showScanner) {
                VStack{
                    HStack {
                        Text("擷取的文字顯示:")
                            .foregroundColor(.gray)
                            .padding(.trailing)
                        Spacer()
                        Button(action: {
                            showScanner.toggle()
                        }) {
                            Text("返回")
                                .buttonStyle(.borderless)
                                .controlSize(.regular)
                                .buttonBorderShape(.automatic)
                                .tint(.pink)
                        }
                    }
                    .padding([.leading, .trailing])
                    
                    TextEditor(text: $recognizedText)
                        .padding([.leading, .trailing])
                        .frame(height: 500)
                    
                    
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text(alertMessage), dismissButton: .default(Text("確定")){
                    reloadView.toggle()
                })
            }
            
        }
        .background(.ultraThinMaterial)
        .padding(.bottom,110)
        .onChange(of: alertMessage) { newValue in
            if !newValue.isEmpty {
                showAlert = true
            }
        }
        
    }
        
        .id(reloadView) // 使用 id 属性强制视图重新加载
}
    
    // 發送文字到伺服器的函數
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
                print("Error: \(error)")
                return
            }

            if let data = data, let responseText = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    alertMessage = responseText
                    logs.append(LogEntry(scannedText: text, serverResponse: responseText,timestamp: Date())) // 記錄到 logs 中
                    showAlert = true
                }
            }
        }.resume()
    }
}


