import Macro
import SwiftData
import AsyncReactor
import SwiftUI

let a = 17
let b = 25

let (result, code) = #stringify(a + b)

print("The value \(result) was produced by the code \"\(code)\"")

@Reactor
class TestReactor {
    enum Action {
        case search(String)
    }
    
    struct State {
        var query = ""
    }
    
    @Dependency(\.managedObjectContext)
    var context
    
    @Dependency(\.colorScheme)
    var colorScheme
    
    @MainActor
    init(state: State = State()) {
        self.state = state
    }
    
    func action(_ action: Action) async {
        switch action {
        case .search(let string):
            print(string)
        }
    }
}
