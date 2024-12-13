import SwiftUI

struct LogView: View {
    @Binding var logs: [LogEntry]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(logs) { log in
                    VStack(alignment: .leading) {
                        Text("掃描時間:")
                            .font(.headline)
                        Text("\(log.timestamp, formatter: dateFormatter)")
                            .foregroundColor(.gray)
                            .padding(.bottom, 5)
                        Text("掃描文字:")
                            .font(.headline)
                        Text(log.scannedText)
                            .foregroundColor(.gray)
                            .padding(.bottom, 5)
                        
                        Text("伺服器回應:")
                            .font(.headline)
                        Text(log.serverResponse)
                            .foregroundColor(.gray)
                    }
                    .padding()
                }
            }
            
        }
        
    }
}

struct LogEntry: Identifiable{
    let id = UUID()
    let scannedText: String
    let serverResponse: String
    let timestamp: Date
}
let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()
