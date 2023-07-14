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
import Macro
import SwiftUI

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

@Reactor
class RepositorySearchReactor {
    enum Action {
        case onHidePrivateToggle
        case enterQuery(String)
        case load
        case onSortOptionSelected(SortOptions)
    }
    
    struct State {
        var hidePrivate = false
        var query = ""
        var repositories: [Repository] = []
        var isLoading = false
        var sortBy: SortOptions = .watchers
    }
    
    @Dependency(\.gitHubApi)
    var gitHubApi
    
    @Dependency(\.managedObjectContext)
    var hallo
    
    @MainActor
    init(state: State = State()) {
        self.state = state
        
        let sortBy = UserDefaults.standard.string(forKey: "sortBy") ?? SortOptions.watchers.rawValue
        self.handleSortOption(sortBy)
        
        lifecycleTask {
            for await _ in await NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification).values {
                await self.action(.load)
            }
            
            logger.debug("lifecycleTask cancelled")
        }
    }
    
    @MainActor // NOTE: when adding AsyncReactor conformance via macro, @MainActor is not automatically added apparently...
    func action(_ action: Action) async {
        switch action {
        case .onHidePrivateToggle:
            state.hidePrivate.toggle()
            
        case .enterQuery(let query):
            print("enter query: \(query)")
            state.query = query
            
            try? await Task.sleep(for: .seconds(1))
            
            guard !Task.isCancelled else { return }
            print("load")
            await self.action(.load)
        case .load:
            state.isLoading = true
            
            do {
                let currentQuery = state.query.isEmpty ? "iOS" : state.query
                
                state.repositories = try await gitHubApi!.search(query: currentQuery)
                state.isLoading = false
                
                logger.debug("search repositories success: \(String(describing: state.repositories.count))")
            }
            catch {
                logger.error("error while searching repositories: \(error)")
            }
        case .onSortOptionSelected(let option):
            state.sortBy = option
            UserDefaults.standard.set(state.sortBy.rawValue, forKey: "sortBy")
        }
    }
    
    @MainActor
    private func handleSortOption(_ value: String) {
        state.sortBy = SortOptions(rawValue: value)!
    }
    
    deinit {
        logger.debug("deinit RepositorySearchReactor")
    }
}
