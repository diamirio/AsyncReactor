//
//  Reactor+SwiftUI.swift
//  AsyncReactor
//
//  Created by Dominik Arnhof on 23.11.24.
//

#if canImport(SwiftUI)
import SwiftUI
import ReactorBase

/// Property wrapper to get a binding to a state keyPath and a associated Action
/// Can be used and behaves like the `@State` property wrapper
@available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, *)
@MainActor
@propertyWrapper
public struct ActionBinding<R: Reactor, Action, Value>: DynamicProperty {
    let target: Environment<R>
    
    let keyPath: KeyPath<R.State, Value>
    let action: (Value) -> Action
    
    let cancelId: CancelId?
    
    public init(_ reactorType: R.Type, keyPath: KeyPath<R.State, Value>, cancelId: CancelId? = nil, action: @escaping (Value) -> R.Action) where Action == R.Action {
        target = Environment(R.self)
        self.keyPath = keyPath
        self.action = action
        self.cancelId = cancelId
    }
    
    public init(_ reactorType: R.Type, keyPath: KeyPath<R.State, Value>, cancelId: CancelId? = nil, action: @escaping @autoclosure () -> R.Action) where Action == R.Action {
        self.init(reactorType, keyPath: keyPath, cancelId: cancelId, action: { _ in action() })
    }
    
    public init(_ reactorType: R.Type, keyPath: KeyPath<R.State, Value>, action: @escaping (Value) -> R.SyncAction) where Action == R.SyncAction {
        target = Environment(R.self)
        self.keyPath = keyPath
        self.action = action
        cancelId = nil
    }
    
    public init(_ reactorType: R.Type, keyPath: KeyPath<R.State, Value>, action: @escaping @autoclosure () -> R.SyncAction) where Action == R.SyncAction {
        self.init(reactorType, keyPath: keyPath, action: { _ in action() })
    }
    
    public var wrappedValue: Value {
        get { projectedValue.wrappedValue }
        nonmutating set { projectedValue.wrappedValue = newValue }
    }
    
    public var projectedValue: Binding<Value> {
        get {
            func bindAction() -> Binding<Value> {
                target.wrappedValue.bind(keyPath, cancelId: cancelId, action: action as! (Value) -> R.Action)
            }
            
            func bindSyncAction() -> Binding<Value> {
                target.wrappedValue.bind(keyPath, action: action as! (Value) -> R.SyncAction)
            }
            
            if Action.self == R.SyncAction.self {
                return bindSyncAction()
            } else if Action.self == R.Action.self {
                return bindAction()
            } else {
                fatalError("this should never happen :)")
            }
        }
    }
}

@available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, *)
public struct ReactorView<Content: View, R: Reactor>: View {
    let content: Content
    let definesLifecycle: Bool
    
    @State
    private var reactor: R
    
    public init(_ reactor: @escaping @autoclosure () -> R, definesLifecycle: Bool = true, @ViewBuilder content: () -> Content) {
        _reactor = State(initialValue: reactor())
        self.content = content()
        self.definesLifecycle = definesLifecycle
    }
    
    public var body: some View {
        content
            .environment(reactor)
            .reactorLifecycle(definesLifecycle ? reactor : nil)
    }
}
#endif
