import SwiftUI
import SDWebImageSwiftUI
import AVFoundation
extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
struct TextSearchView: View {
    @State private var searchText = ""
    @State private var resultText = ""
    @State private var isUrlMode = false  // 用來控制開關的狀態
    @State private var audioPlayer: AVAudioPlayer? // 音頻播放器
    @State private var keyboardHeight: CGFloat = 0
    @State private var showAlert = false
    @Binding var logs: [LogEntry] // 綁定到父視圖中的 logs
    @ObservedObject var ipStore: IPAddressStore
    var body: some View {
        VStack {
            Spacer()
            ScrollView {
                HStack{
                    TextField(isUrlMode ? "請輸入網址" : "請輸入LINE ID", text: $searchText)
                        .padding()  // 给TextField内部添加一些填充
                        .background(Color.white)  // 背景颜色
                        .cornerRadius(8)  // 圆角
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)  // 添加边框
                        )
                    Button(action: {
                        sendPostRequest(with: searchText)
                    }) {
                        Text("發送")
                            .buttonStyle(.borderless)
                            .controlSize(.regular)
                            .buttonBorderShape(.automatic)
                            .tint(isUrlMode ? Color.purple : Color.green)
                    }
                }
                .padding([.leading, .trailing])
                
                WebImage(url: Bundle.main.url(forResource: isUrlMode ? "connected" : "line", withExtension: "png"))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                
                Toggle(isOn: $isUrlMode) {
                    Text(isUrlMode ? "URL 模式" : "Line ID 模式")
                        .foregroundColor(isUrlMode ? Color.blue : Color.mint)
                }
                .tint(Color(.systemGroupedBackground))
                .padding(.horizontal,100)
                Spacer()
                Text(resultText)
                    .foregroundColor(resultText.contains("可能為詐騙") ? .red : .gray) // 根據內容設置顏色
                    .multilineTextAlignment(.center)
                    .font(.largeTitle)
                    .padding(.horizontal)
                Spacer()
                
                if resultText.contains("不是") {
                    
                    WebImage(url: Bundle.main.url(forResource: "good", withExtension: "gif"))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 300, height: 200)
                    Spacer()
                }
                if resultText.contains("可能為詐騙") {
                    WebImage(url: Bundle.main.url(forResource: "bad", withExtension: "gif"))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 300, height: 200)
                    Spacer()
                }
                
            }
            .contentShape(Rectangle())
                    .onTapGesture {
                        UIApplication.shared.endEditing() // 点击空白处关闭键盘
                    }
            .onAppear {
                        // 监听键盘显示和隐藏通知
                        NotificationCenter.default.addObserver(
                            forName: UIResponder.keyboardWillChangeFrameNotification,
                            object: nil,
                            queue: .main
                        ) { notification in
                            let userInfo = notification.userInfo
                            let endFrame = userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? CGRect.zero
                            self.keyboardHeight = endFrame.height
                        }
                    }
                    .onDisappear {
                        // 当视图消失时，移除键盘通知的监听
                        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
                    }
            .alert(isPresented: $showAlert) {
                Alert(title: Text(resultText), dismissButton: .default(Text("確定")))
            }
            .onChange(of: resultText) { newValue in
                if newValue.contains("不是") {
                    playAlertSound()
                }
                if newValue.contains("可能為詐騙") {
                    playAlertSound()
                }
                showAlert = true
            }
        }
    }
    func sendPostRequest(with text: String) {
        // 根據開關狀態選擇不同的 URL
        let urlString = isUrlMode ? "http://\(ipStore.ipAddress):8888/url_request" : "http://\(ipStore.ipAddress):8888/lineid_request"

        guard let url = URL(string: urlString) else {
            resultText = "無效的 URL"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/plain; charset=utf-8", forHTTPHeaderField: "Content-Type")

        // 將文字轉換為 UTF-8 格式的 Data
        if let postData = text.data(using: .utf8) {
            request.httpBody = postData
        } else {
            resultText = "無法將文字轉換為 UTF-8"
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    resultText = "發送失敗: \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    resultText = "無效的伺服器回應"
                }
                return
            }

            if let responseText = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    resultText = responseText
                    logs.append(LogEntry(scannedText: text, serverResponse: responseText, timestamp: Date())) // 記錄到 logs 中
                }
            } else {
                DispatchQueue.main.async {
                    resultText = "無法解析伺服器回應"
                }
            }
        }.resume()
    }
    func playAlertSound() {
            guard let url = Bundle.main.url(forResource: "local", withExtension: "mp3") else {
                print("音頻文件未找到")
                return
            }

            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.play()
            } catch {
                print("音頻播放錯誤: \(error.localizedDescription)")
            }
    }
}


