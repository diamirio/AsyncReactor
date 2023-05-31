//
//  AsyncReactorExampleApp.swift
//  AsyncReactorExample
//
//  Created by Dominik Arnhof on 15.05.23.
//

import SwiftUI
import Logging

@main
struct AsyncReactorExampleApp: App {
    
    init() {
        LoggingSystem.bootstrap { label in
            var standardOutputLogHandler = StreamLogHandler.standardOutput(label: label)
            standardOutputLogHandler.logLevel = .debug
            return standardOutputLogHandler
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
