//
//  RepositorySearchView.swift
//  AsyncReactorExample
//
//  Created by Ahmet Bozkan on 22.05.23.
//

import SwiftUI
import AsyncReactor

struct RepositorySearchView: View {
    @EnvironmentObject
    private var reactor: RepositorySearchReactor
    
    @ActionBinding(RepositorySearchReactor.self, keyPath: \.hidePrivate, action: RepositorySearchReactor.Action.onHidePrivateToggle)
    private var hidePrivate: Bool
    
    @ActionBinding(RepositorySearchReactor.self, keyPath: \.query, action: RepositorySearchReactor.Action.enterQuery)
    private var query: String
    
    var body: some View {
        NavigationView {
            List {
                Toggle("Hide Private Repos", isOn: $hidePrivate)
                
                if reactor.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding()
                }
                
                if !reactor.repositories.isEmpty {
                    RepositoryList(repositories: reactor.repositories.filter { !hidePrivate || $0.isVisible })
                }
            }
            .navigationTitle("Repositories")
            .refreshable {
                reactor.send(.load)
            }
        }
        .searchable(text: $query)
        .onSubmit(of: .search) {
            reactor.send(.load)
        }
        .task {
            await reactor.action(.load)
        }
    }
}

struct TestView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ReactorView(RepositorySearchReactor()) {
                RepositorySearchView()
            }
        }
    }
}

