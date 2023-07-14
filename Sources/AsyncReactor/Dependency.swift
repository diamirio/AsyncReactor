//
//  Dependency.swift
//
//
//  Created by Dominik Arnhof on 14.07.23.
//

import SwiftUI

@propertyWrapper
public struct Dependency<Value> {
    public var wrappedValue: Value {
        valueProvider.value()
    }
    
    public var projectedValue: Provider {
        valueProvider
    }
    
    public class Provider {
        public var value: (() -> Value)!
    }
    
    public let valueProvider = Provider()
    
    public init(_ keyPath: KeyPath<EnvironmentValues, Value>) {
        
    }
}
