import SwiftUI

class IPAddressStore: ObservableObject {
    @Published var ipAddress: String = "127.0.0.1"
}
