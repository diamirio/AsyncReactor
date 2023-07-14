import SwiftUI
import AsyncReactor

struct ContentView: View {
    var body: some View {
        RepositorySearchReactorView(RepositorySearchReactor()) {
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
