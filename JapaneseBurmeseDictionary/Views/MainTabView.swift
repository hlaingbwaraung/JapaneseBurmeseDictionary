import SwiftUI

@MainActor
struct MainTabView: View {
    @ObservedObject var viewModel: DictionaryViewModel

    var body: some View {
        TabView {
            SearchHomeView(viewModel: viewModel)
                .tabItem {
                    Label("ရှာဖွေရန်", systemImage: "magnifyingglass")
                }

            BrowseCategoriesView(viewModel: viewModel)
                .tabItem {
                    Label("အမျိုးအစား", systemImage: "square.grid.2x2.fill")
                }

            BookmarksView(viewModel: viewModel)
                .tabItem {
                    Label("မှတ်သားချက်", systemImage: "bookmark.fill")
                }

            FlashcardStudyView(viewModel: viewModel)
                .tabItem {
                    Label("လေ့ကျင့်ရန်", systemImage: "rectangle.on.rectangle.angled")
                }
        }
    }
}
