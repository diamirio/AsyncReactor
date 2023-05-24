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
        case onHidePrivateToggle
        case enterQuery(String)
        case load
    }
    
    struct State {
        var hidePrivate = false
        var query = ""
        var repositories: [Repository] = []
        var isLoading = false
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
        case .onHidePrivateToggle:
            state.hidePrivate.toggle()
        case .enterQuery(let query):
            state.query = query
            
            try? await Task.sleep(for: .seconds(5))
            
            guard !Task.isCancelled else { return }
            
            logger.debug("search: \(query)")
        case .load:
            Task {
                state.isLoading = true
                
                do {
                    let currentQuery = state.query.isEmpty ? "iOS" : state.query
                    let (data, _) = try await URLSession.shared.data(from: URL(string:"https://api.github.com/search/repositories?q=\(currentQuery)")!)
                    let decodedResponse = try? JSONDecoder().decode(RepositoriesResponse.self, from: data)
                    
                    state.repositories = decodedResponse?.repositories ?? []
                    state.isLoading = false
                    
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
        state.hidePrivate.toggle()
    }
    
    deinit {
        logger.debug("deinit RepositorySearchReactor")
    }
}
