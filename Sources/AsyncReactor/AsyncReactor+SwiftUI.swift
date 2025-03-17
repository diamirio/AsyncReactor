//
//  AsyncReactor+SwiftUI.swift
//  
//
//  Created by Dominik Arnhof on 14.04.23.
//

#if canImport(SwiftUI)
import SwiftUI
import ReactorBase

/// Property wrapper to get a binding to a state keyPath and a associated Action
/// Can be used and behaves like the `@State` property wrapper
@MainActor
@propertyWrapper
public struct ActionBinding<Reactor: AsyncReactor, Action, Value>: DynamicProperty {
    let target: EnvironmentObject<Reactor>
    
    let keyPath: KeyPath<Reactor.State, Value>
    let action: (Value) -> Action
    
    let cancelId: CancelId?
    
    public init(
        _ reactorType: Reactor.Type,
        keyPath: KeyPath<Reactor.State, Value>,
        cancelId: CancelId? = nil,
        action: @escaping (Value) -> Reactor.AsyncAction
    ) where Action == Reactor.AsyncAction {
        target = EnvironmentObject()
        self.keyPath = keyPath
        self.action = action
        self.cancelId = cancelId
    }
    
    public init(
        _ reactorType: Reactor.Type,
        keyPath: KeyPath<Reactor.State, Value>,
        cancelId: CancelId? = nil,
        action: @escaping @autoclosure () -> Reactor.AsyncAction
    ) where Action == Reactor.AsyncAction {
        self.init(
            reactorType,
            keyPath: keyPath,
            cancelId: cancelId,
            action: { _ in action() }
        )
    }
    
    public init(
        _ reactorType: Reactor.Type,
        keyPath: KeyPath<Reactor.State, Value>,
        action: @escaping (Value) -> Reactor.SyncAction
    ) where Action == Reactor.SyncAction {
        target = EnvironmentObject()
        self.keyPath = keyPath
        self.action = action
        cancelId = nil
    }
    
    public init(
        _ reactorType: Reactor.Type,
        keyPath: KeyPath<Reactor.State, Value>,
        action: @escaping @autoclosure () -> Reactor.SyncAction
    ) where Action == Reactor.SyncAction {
        self.init(reactorType, keyPath: keyPath, action: { _ in action() })
    }
    
    public var wrappedValue: Value {
        get { projectedValue.wrappedValue }
        nonmutating set { projectedValue.wrappedValue = newValue }
    }
    
    public var projectedValue: Binding<Value> {
        get {
            func bindAction() -> Binding<Value> {
                target.wrappedValue.bind(keyPath, cancelId: cancelId, action: action as! (Value) -> Reactor.AsyncAction)
            }
            
            func bindSyncAction() -> Binding<Value> {
                target.wrappedValue.bind(keyPath, action: action as! (Value) -> Reactor.SyncAction)
            }
            
            if Action.self == Reactor.SyncAction.self {
                return bindSyncAction()
            } else if Action.self == Reactor.AsyncAction.self {
                return bindAction()
            } else {
                fatalError("this should never happen :)")
            }
        }
    }
}

public struct ReactorView<Content: View, R: AsyncReactor>: View {
    let content: Content
    let definesLifecycle: Bool
    
    @StateObject
    private var reactor: R
    
    public init(
        _ reactor: @escaping @autoclosure () -> R,
        definesLifecycle: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        _reactor = StateObject(wrappedValue: reactor())
        self.content = content()
        self.definesLifecycle = definesLifecycle
    }
    
    public var body: some View {
        content
            .environmentObject(reactor)
            .reactorLifecycle(definesLifecycle ? reactor : nil)
    }
}
#endif
