//
//  TestReactor.swift
//  Rudi
//
//  Created by Dominik Arnhof on 14.04.23.
//

import Foundation
import AsyncReactor
import UIKit
import Logging

private let logger = Logger(label: "TestReactor")

class TestReactor: AsyncReactor {
    enum Action {
        case toggle(Bool)
        case togglePressed
        case enterQuery(String)
        case longRunningAction
        case setSheetPresented(Bool)
    }
    
    struct State {
        var isOn = false
        var query = ""
        var sheetPresented = false
    }
    
    @Published
    private(set) var state: State

    @MainActor
    init(state: State = State()) {
        self.state = state
        
        lifecycleTask {
            for await _ in await NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification).values {
                await self.handleNotification()
            }

            logger.debug("lifecycleTask cancelled")
        }
    }
    
    func action(_ action: Action) async {
        switch action {
        case .toggle(let isOn):
            state.isOn = isOn
        case .togglePressed:
            state.isOn.toggle()
        case .enterQuery(let query):
            state.query = query
            
            try? await Task.sleep(for: .milliseconds(500))
            
            guard !Task.isCancelled else { return }
            
            logger.debug("search: \(query)")
            
        case .longRunningAction:
            do {
                try await Task.sleep(for: .seconds(10))
                logger.debug("long running action success")
            } catch {
                logger.error("long running action error: \(error)")
            }
            
        case .setSheetPresented(let isPresented):
            state.sheetPresented = isPresented
        }
    }
    
    @MainActor
    private func handleNotification() {
        state.isOn.toggle()
    }
    
    deinit {
        logger.debug("deinit TestReactor")
    }
}
