import SwiftUI

@main
struct Anti_fraudApp:App {
    // 创建 AppDelegate 的实例
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
