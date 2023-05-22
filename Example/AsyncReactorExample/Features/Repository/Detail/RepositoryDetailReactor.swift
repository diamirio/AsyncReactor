//
//  RepositoryDetailReactor.swift
//  AsyncReactorExample
//
//  Created by Ahmet Bozkan on 22.05.23.
//

import Foundation
import AsyncReactor

class RepositoryDetailReactor: AsyncReactor {
    
    enum Action {
        
    }
    
    struct State {
        
    }
    
    @Published
    private(set) var state: State
    
    @MainActor
    init(state: State = State()) {
        self.state = state
    }
    
    
    func action(_ action: Action) async {
        
    }
    
}
