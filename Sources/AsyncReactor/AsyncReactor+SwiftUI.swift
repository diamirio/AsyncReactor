//
//  AsyncReactor+SwiftUI.swift
//  
//
//  Created by Dominik Arnhof on 14.04.23.
//

#if canImport(SwiftUI)
import SwiftUI

extension AsyncReactor {
    @MainActor
    public func bind<T>(_ keyPath: KeyPath<State, T>, cancelId: CancelId? = nil, action: @escaping (T) -> Action) -> Binding<T> {
        Binding {
            self.state[keyPath: keyPath]
        } set: { newValue in
            Task {
                if let cancelId {
                    await self.action(action(newValue), id: cancelId)
                } else {
                    await self.action(action(newValue))
                }
            }
        }
    }
    
    @MainActor
    public func bind<T>(_ keyPath: KeyPath<State, T>, cancelId: CancelId? = nil, action: @escaping @autoclosure () -> Action) -> Binding<T> {
        bind(keyPath, cancelId: cancelId) { _ in action() }
    }
    
    @MainActor
    public func bind<T>(_ keyPath: KeyPath<State, T>, action: @escaping (T) -> SyncAction) -> Binding<T> {
        Binding {
            self.state[keyPath: keyPath]
        } set: { newValue in
            self.action(action(newValue))
        }
    }
    
    @MainActor
    public func bind<T>(_ keyPath: KeyPath<State, T>, action: @escaping @autoclosure () -> SyncAction) -> Binding<T> {
        bind(keyPath) { _ in action() }
    }
}

/// Property wrapper to get a binding to a state keyPath and a associated Action
/// Can be used and behaves like the `@State` property wrapper
@MainActor
@propertyWrapper
public struct ActionBinding<Reactor: AsyncReactor, Action, Value>: DynamicProperty {
    let target: EnvironmentObject<Reactor>
    
    let keyPath: KeyPath<Reactor.State, Value>
    let action: (Value) -> Action
    
    let cancelId: CancelId?
    
    public init(_ reactorType: Reactor.Type, keyPath: KeyPath<Reactor.State, Value>, cancelId: CancelId? = nil, action: @escaping (Value) -> Reactor.Action) where Action == Reactor.Action {
        target = EnvironmentObject()
        self.keyPath = keyPath
        self.action = action
        self.cancelId = cancelId
    }
    
    public init(_ reactorType: Reactor.Type, keyPath: KeyPath<Reactor.State, Value>, cancelId: CancelId? = nil, action: @escaping @autoclosure () -> Reactor.Action) where Action == Reactor.Action {
        self.init(reactorType, keyPath: keyPath, cancelId: cancelId, action: { _ in action() })
    }
    
    public init(_ reactorType: Reactor.Type, keyPath: KeyPath<Reactor.State, Value>, action: @escaping (Value) -> Reactor.SyncAction) where Action == Reactor.SyncAction {
        target = EnvironmentObject()
        self.keyPath = keyPath
        self.action = action
        cancelId = nil
    }
    
    public init(_ reactorType: Reactor.Type, keyPath: KeyPath<Reactor.State, Value>, action: @escaping @autoclosure () -> Reactor.SyncAction) where Action == Reactor.SyncAction {
        self.init(reactorType, keyPath: keyPath, action: { _ in action() })
    }
    
    public var wrappedValue: Value {
        get { projectedValue.wrappedValue }
        nonmutating set { projectedValue.wrappedValue = newValue }
    }
    
    public var projectedValue: Binding<Value> {
        get {
            func bindAction() -> Binding<Value> {
                target.wrappedValue.bind(keyPath, cancelId: cancelId, action: action as! (Value) -> Reactor.Action)
            }
            
            func bindSyncAction() -> Binding<Value> {
                target.wrappedValue.bind(keyPath, action: action as! (Value) -> Reactor.SyncAction)
            }
            
            if Action.self == Reactor.Action.self {
                return bindAction()
            } else if Action.self == Reactor.SyncAction.self {
                return bindSyncAction()
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
    
    public init(_ reactor: @escaping @autoclosure () -> R, definesLifecycle: Bool = true, @ViewBuilder content: () -> Content) {
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

private class LifecycleModel: ObservableObject {
    let onDeinit: () -> Void
    
    init(onDeinit: @escaping () -> Void) {
        self.onDeinit = onDeinit
    }
    
    deinit {
        onDeinit()
    }
}

struct ReactorLifecycleCancel: ViewModifier {
    @StateObject
    private var model: LifecycleModel
    
    init(reactor: (any AsyncReactor)?) {
        _model = StateObject(wrappedValue: LifecycleModel(onDeinit: {
            reactor?.cancelLifecycleTasks()
        }))
    }
    
    func body(content: Content) -> some View {
        content
            .task {
                // empty task because when not modifying the content at all, SwiftUI seems to optimise away the modifier
            }
    }
}

extension View {
    public func reactorLifecycle(_ reactor: (any AsyncReactor)?) -> some View {
        modifier(ReactorLifecycleCancel(reactor: reactor))
    }
}
#endif
