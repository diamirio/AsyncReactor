//
//  TestView.swift
//  Rudi
//
//  Created by Dominik Arnhof on 14.04.23.
//

import SwiftUI
import AsyncReactor

struct TestView: View {
    @EnvironmentObject
    private var reactor: TestReactor
    
    @ActionBinding(TestReactor.self, keyPath: \.isOn, action: TestReactor.Action.toggle)
    private var isOn: Bool
    
    @ActionBinding(TestReactor.self, keyPath: \.isOn, action: .togglePressed)
    private var isOnToggle: Bool
    
    @ActionBinding(TestReactor.self, keyPath: \.query, action: TestReactor.Action.enterQuery)
    private var query: String
    
    @ActionBinding(TestReactor.self, keyPath: \.sheetPresented, action: TestReactor.Action.setSheetPresented)
    private var sheetPresented: Bool
    
    var body: some View {
        List {
            ForEach(reactor.repositories.item ?? []) { repo in
                Text(repo.name)
            }
            
            Toggle("Toggle", isOn: $isOn)
            Toggle("Toggle Action", isOn: $isOnToggle)
            Text("Toggle: \(String(reactor.isOn))")
            
            Button("Long running action") {
                reactor.send(.longRunningAction, id: .init(id: "longRunning", mode: [.lifecycle, .inFlight]))
            }
            
            NavigationLink("Push") {
                ReactorView(TestReactor()) {
                    TestView()
                }
            }
            
            Button("Present") {
                reactor.send(.setSheetPresented(true))
            }
        }
        .searchable(text: $query)
        .navigationTitle("Test")
        .sheet(isPresented: $sheetPresented) {
            NavigationStack {
                ReactorView(TestReactor()) {
                    TestView()
                }
            }
        }
        .refreshable {
            await reactor.action(.load)
        }
    }
}

struct TestView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ReactorView(TestReactor()) {
                TestView()
            }
        }
    }
}
