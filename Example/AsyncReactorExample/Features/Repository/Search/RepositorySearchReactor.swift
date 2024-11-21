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

enum SortOptions: String, CaseIterable, Identifiable {
    var id: Self { return self }
    
    case watchers
    case forks
    
    var displayName: String {
        switch self {
        case .watchers:
            return "Watchers Count"
        case .forks:
            return "Forks"
        }
    }
}

class RepositorySearchReactor: AsyncReactor {
    enum Action {
        case onHidePrivateToggle
        case enterQuery(String)
        case load
        case onSortOptionSelected(SortOptions)
    }
    
    enum SyncAction {
        case toggleHidePrivate
    }
    
    struct State {
        var hidePrivate = false
        var query = ""
        var repositories: [Repository] = []
        var isLoading = false
        var sortBy: SortOptions = .watchers
    }
    
    @Published
    private(set) var state: State
    
    init(state: State = State()) {
        self.state = state
        
        let sortBy = UserDefaults.standard.string(forKey: "sortBy") ?? SortOptions.watchers.rawValue
        self.handleSortOption(sortBy)
        
        lifecycleTask {
            for await _ in NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification).values {
                await self.action(.load)
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
            
            try? await Task.sleep(for: .seconds(1))
            
            guard !Task.isCancelled else { return }
            
            await self.action(.load)
        case .load:
            state.isLoading = true
            
            do {
                let currentQuery = state.query.isEmpty ? "iOS" : state.query
                let (data, _) = try await URLSession.shared.data(from: URL(string:"https://api.github.com/search/repositories?q=\(currentQuery)")!)
                let decodedResponse = try JSONDecoder().decode(RepositoriesResponse.self, from: data)
                
                state.repositories = decodedResponse.repositories
                state.isLoading = false
                
                logger.debug("search repositories success: \(String(describing: decodedResponse.repositories.count))")
            }
            catch {
                logger.error("error while searching repositories: \(error)")
            }
            
        case .onSortOptionSelected(let option):
            state.sortBy = option
            UserDefaults.standard.set(option.rawValue, forKey: "sortBy")
        }
    }
    
    func action(_ action: SyncAction) {
        switch action {
        case .toggleHidePrivate:
            state.hidePrivate.toggle()
        }
    }
    
    private func handleSortOption(_ value: String) {
        state.sortBy = SortOptions(rawValue: value)!
    }
    
    deinit {
        logger.debug("deinit RepositorySearchReactor")
    }
}
