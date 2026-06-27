import SwiftUI

@main
struct LOTECH_Audio_Metadata_EditorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1100, minHeight: 700)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1400, height: 900)
        .windowResizability(.contentMinSize)
    }
}
