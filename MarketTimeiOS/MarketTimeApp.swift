import SwiftUI

@main
struct MarketTimeApp: App {
    @StateObject private var marketTimer = MarketTimer()

    var body: some Scene {
        WindowGroup {
            ContentView(timer: marketTimer)
                .preferredColorScheme(.dark)
        }
    }
}
