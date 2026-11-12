import SwiftUI

@main
struct TrailLogApp: App {
    @StateObject private var store = TrackStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
