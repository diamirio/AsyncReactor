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
    
    @ActionBinding(RepositorySearchReactor.self, keyPath: \.isOn, action: RepositorySearchReactor.Action.toggle)
    private var isOn: Bool
    
    @ActionBinding(RepositorySearchReactor.self, keyPath: \.isOn, action: .togglePressed)
    private var isOnToggle: Bool
    
    @ActionBinding(RepositorySearchReactor.self, keyPath: \.query, action: RepositorySearchReactor.Action.enterQuery)
    private var query: String
    
    @ActionBinding(RepositorySearchReactor.self, keyPath: \.sheetPresented, action: RepositorySearchReactor.Action.setSheetPresented)
    private var sheetPresented: Bool
    
    var body: some View {
        NavigationView {
            List {
                if reactor.repositories.item?.isEmpty == false || reactor.repositories.item != nil {
                    RepositoryList(repositories: reactor.repositories.item ?? [])
                }
                
                Toggle("Toggle", isOn: $isOn)
                Toggle("Toggle Action", isOn: $isOnToggle)
                Text("Toggle: \(String(reactor.isOn))")
                
                Button("Long running action") {
                    reactor.send(.longRunningAction, id: .init(id: "longRunning", mode: [.lifecycle, .inFlight]))
                }
                
                NavigationLink("Push") {
                    ReactorView(RepositorySearchReactor()) {
                        RepositorySearchView()
                    }
                }
                  
                Button("Present") {
                    reactor.send(.setSheetPresented(true))
                }
            }
            .navigationTitle("Repositories")
            .sheet(isPresented: $sheetPresented) {
                NavigationStack {
                    ReactorView(RepositorySearchReactor()) {
                        RepositorySearchView()
                    }
                }
            }
            .refreshable {
                await reactor.action(.load)
            }
        }
        .searchable(text: $query)
        
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

