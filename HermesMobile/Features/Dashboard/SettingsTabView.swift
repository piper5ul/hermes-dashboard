import SwiftUI

struct SettingsTabView: View {
    @Bindable var authManager: AuthManager
    let server: URL

    var body: some View {
        NavigationStack {
            SettingsView(authManager: authManager, server: server)
        }
    }
}