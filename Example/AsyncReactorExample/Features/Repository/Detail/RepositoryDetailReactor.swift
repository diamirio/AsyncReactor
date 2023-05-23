//
//  RepositoryDetailReactor.swift
//  AsyncReactorExample
//
//  Created by Ahmet Bozkan on 22.05.23.
//

import Foundation
import AsyncReactor
import Logging

private let logger = Logger(label: "RepositoryDetailReactor")

class RepositoryDetailReactor: AsyncReactor {
    
    enum Action {
        case setSheetPresented(Bool)
        case longRunningAction
    }
    
    struct State {
        var sheetPresented = false
        var longRunningActionRunning = false
    }
    
    @Published
    private(set) var state: State
    
    @MainActor
    init(state: State = State()) {
        self.state = state
    }
    
    
    func action(_ action: Action) async {
        switch(action)  {
        case .setSheetPresented(let isPresented):
            state.sheetPresented = isPresented
        case .longRunningAction:
            do {
                state.longRunningActionRunning = true
                
                try await Task.sleep(for: .seconds(5))
                
                state.longRunningActionRunning = false
                
                logger.debug("long running action success")
            } catch {
                logger.error("long running action error: \(error)")
            }
        }
    }
    
}
