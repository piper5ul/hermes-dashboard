import SwiftUI

struct KanbanTabView: View {
    let server: URL
    private let onAPIError: (Error) -> Void

    init(server: URL, onAPIError: @escaping (Error) -> Void = { _ in }) {
        self.server = server
        self.onAPIError = onAPIError
    }

    var body: some View {
        NavigationStack {
            KanbanView(server: server, onAPIError: onAPIError)
        }
    }
}