//
//  RepositorySearchView.swift
//  AsyncReactorExample
//
//  Created by Ahmet Bozkan on 22.05.23.
//

import SwiftUI
import AsyncReactor
import Combine

struct RepositorySearchView: View {
    @EnvironmentObject
    private var reactor: RepositorySearchReactor
    
    @ActionBinding(RepositorySearchReactor.self, keyPath: \.hidePrivate, action: RepositorySearchReactor.Action.onHidePrivateToggle)
    private var hidePrivate: Bool
    
    @ActionBinding(RepositorySearchReactor.self, keyPath: \.query, action: RepositorySearchReactor.Action.enterQuery)
    private var query: String
    
    @ActionBinding(RepositorySearchReactor.self, keyPath: \.sortBy, action: RepositorySearchReactor.Action.onSortOptionSelected)
    private var sortOption: SortOptions
    
    var body: some View {
        NavigationStack {
            List {
                Toggle("Hide Private Repos", isOn: $hidePrivate)
                
                if reactor.isLoading {
                    HStack {
                        Spacer()
                        ProgressView().id(UUID())
                        Spacer()
                    }
                    .padding()
                }
                
                if !reactor.repositories.isEmpty {
                    RepositoryList(
                        repositories: reactor.repositories
                            .filter {
                                !hidePrivate || $0.isVisible
                            }
                            .sorted(by: {
                                switch sortOption {
                                case .watchers:
                                    return $0.watchersCount < $1.watchersCount
                                case .forks:
                                    return $0.forks < $1.forks
                                }
                            })
                    )
                }
            }
            .navigationTitle("Repositories")
            .refreshable {
                reactor.send(.load)
            }
            .searchable(text: $query)
            .toolbar {
                ToolbarItem {
                    Menu("Sort By") {
                        Picker("Sort By", selection: $sortOption) {
                            ForEach(SortOptions.allCases) {
                                Text($0.displayName)
                            }
                        }
                    }
                }
            }
            .navigationDestination(for: Repository.self) { repository in
                ReactorView(RepositoryDetailReactor()) {
                    RepositoryDetailView(repository: repository)
                }
            }
            .task {
                await reactor.action(.load)
            }
        }
    }
}

struct RepositorySearchView_Previews: PreviewProvider {
    static var previews: some View {
        ReactorView(RepositorySearchReactor()) {
            RepositorySearchView()
        }
    }
}

