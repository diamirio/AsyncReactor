//
//  Reactor.swift
//  AsyncReactor
//
//  Created by Dominik Arnhof on 23.11.24.
//

import Foundation
import ReactorBase

@available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, *)
@dynamicMemberLookup
public protocol Reactor: Observable, ReactorBase where State: Observable {}

// MARK: - DynamicMemberLookup
@available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, *)
extension Reactor {
    @MainActor
    public subscript<Value>(dynamicMember keyPath: KeyPath<State, Value>) -> Value {
        state[keyPath: keyPath]
    }
}
