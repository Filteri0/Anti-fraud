import SwiftUI

struct ContentView: View {
    
    @StateObject private var ipStore = IPAddressStore()
    @State private var logs: [LogEntry] = [] // 記錄掃描和伺服器回應的資料
    var body: some View {
        TabView {
            ScreenshotScannerView(logs: $logs, ipStore: ipStore)
                .tabItem {
                    Image(systemName: "camera.viewfinder")
                    Text("拍照掃描")
                }
            
            TextSearchView(logs: $logs, ipStore: ipStore)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("ID URL搜尋")
                }
            
            ImageView(logs: $logs, ipStore: ipStore)
                .tabItem {
                    Image(systemName: "photo.artframe")
                    Text("上傳圖片")
                }
            LogView(logs: $logs)
                .tabItem {
                    Image(systemName: "doc.text.magnifyingglass")
                    Text("歷史紀錄")
                }
        }
        
        .tint(.orange)
    }
}



