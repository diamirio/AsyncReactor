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
                        repositories: reactor.repositories.filter { !hidePrivate || $0.isVisible }
                    )
                }
            }
            .navigationTitle("Repositories")
            .refreshable {
                reactor.send(.load)
            }
            .searchable(text: $query)
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

