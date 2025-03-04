import SwiftUI
import AsyncReactor

struct ContentView: View {
    var body: some View {
        RepositorySearchReactorView {
            RepositorySearchView()
        }
        .environment(\.gitHubApi, GitHubAPI())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ContentView()
                .environment(\.gitHubApi, GitHubAPI())
        }
    }
}
