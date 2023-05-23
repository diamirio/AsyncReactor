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

private let logger = Logger(label: "RepositorySearchReactor")

class RepositorySearchReactor: AsyncReactor {
    enum Action {
        case toggle(Bool)
        case togglePressed
        case enterQuery(String)
        case longRunningAction
        case setSheetPresented(Bool)
        case load
    }
    
    struct State {
        var isOn = false
        var query = ""
        var sheetPresented = false
        var repositories: AsyncLoad<[Repository]> = .none
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
            
        case .load:
            Task {
                state.repositories = .loading
            
                
                do {
                    let currentQuery = state.query.isEmpty ? "iOS" : state.query
                    let (data, _) = try await URLSession.shared.data(from: URL(string:"https://api.github.com/search/repositories?q=\(currentQuery)")!)
                    let decodedResponse = try? JSONDecoder().decode(RepositoriesResponse.self, from: data)
                    
                    state.repositories = .loaded(decodedResponse?.repositories ?? [])
                    
                    logger.debug("search repositories success: \(String(describing: decodedResponse?.repositories.count))")
                }
                catch {
                    logger.error("error while searching repositories: \(error)")
                }
            }
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
