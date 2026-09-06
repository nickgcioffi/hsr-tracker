import SwiftUI

struct NavigationViewWrapper<Content: View>: View {
    let content: () -> Content

    var body: some View {
#if os(macOS)
        NavigationSplitView {
            content()
        } detail: {
            Text("Select an item")
        }
#elseif os(iOS)
        NavigationStack {
            content()
        }
#endif
    }
}
