//
//  ObservableTestView.swift
//  AsyncReactorExample
//
//  Created by Dominik Arnhof on 21.11.24.
//

import SwiftUI
import Reactor

@available(iOS 17.0, *)
@Observable
class ObservableTestReactor: Reactor {
    enum SyncAction {
        case count
        case enterText(String)
    }
    
    @Observable
    class State {
        var count = 0
        var text = "test"
    }
    
    private(set) var state = State()
    
    init(state: State = State()) {
        self.state = state
        print("reactor init")
    }
    
    func action(_ action: SyncAction) {
        switch action {
        case .count:
            state.count += 1
        case .enterText(let text):
            state.text = text
        }
    }
}

@available(iOS 17.0, *)
struct ObservableTestView: View {
    @Environment(ObservableTestReactor.self)
    private var reactor
    
    @ActionBinding(ObservableTestReactor.self, keyPath: \.text, action: ObservableTestReactor.SyncAction.enterText)
    private var text: String
    
    var body: some View {
        let _ = Self._printChanges()
        VStack {
            Text(reactor.count.formatted())
            
            Button {
                reactor.action(.count)
            } label: {
                Text("+")
            }
            
            Text(reactor.text)

            TextField("Text", text: $text)
                .textFieldStyle(.roundedBorder)
                .padding()
        }
    }
}

#Preview {
    if #available(iOS 17.0, *) {
        ReactorView(ObservableTestReactor()) {
            ObservableTestView()
        }
    }
}
