//
//  ContentView.swift
//  AsyncReactorExample
//
//  Created by Dominik Arnhof on 15.05.23.
//

import SwiftUI
import AsyncReactor

struct ContentView: View {
    var body: some View {
        ReactorView(TestReactor()) {
            TestView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ContentView()
        }
    }
}
