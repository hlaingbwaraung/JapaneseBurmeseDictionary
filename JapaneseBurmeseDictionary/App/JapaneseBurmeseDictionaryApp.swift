import SwiftUI

@main
@MainActor
struct JapaneseBurmeseDictionaryApp: App {
    @StateObject private var viewModel = DictionaryViewModel()

    var body: some Scene {
        WindowGroup {
            MainTabView(viewModel: viewModel)
        }
    }
}
