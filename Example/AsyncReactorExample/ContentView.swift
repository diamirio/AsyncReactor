import SwiftUI
import AsyncReactor

struct ContentView: View {
    var body: some View {
        ReactorView(RepositorySearchReactor()) {
            RepositorySearchView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ContentView()
        }
    }
}
