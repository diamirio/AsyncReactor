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
}

/// Property wrapper to get a binding to a state keyPath and a associated Action
/// Can be used and behaves like the `@State` property wrapper
@MainActor
@propertyWrapper
public struct ActionBinding<Reactor: AsyncReactor, Value>: DynamicProperty {
    let target: EnvironmentObject<Reactor>
    
    let keyPath: KeyPath<Reactor.State, Value>
    let action: (Value) -> Reactor.Action
    
    let cancelId: CancelId?
    
    public init(_ reactorType: Reactor.Type, keyPath: KeyPath<Reactor.State, Value>, cancelId: CancelId? = nil, action: @escaping (Value) -> Reactor.Action) {
        target = EnvironmentObject()
        self.keyPath = keyPath
        self.action = action
        self.cancelId = cancelId
    }
    
    public init(_ reactorType: Reactor.Type, keyPath: KeyPath<Reactor.State, Value>, cancelId: CancelId? = nil, action: @escaping @autoclosure () -> Reactor.Action) {
        self.init(reactorType, keyPath: keyPath, cancelId: cancelId, action: { _ in action() })
    }
    
    public var wrappedValue: Value {
        get { projectedValue.wrappedValue }
        nonmutating set { projectedValue.wrappedValue = newValue }
    }
    
    public var projectedValue: Binding<Value> {
        get { target.wrappedValue.bind(keyPath, cancelId: cancelId, action: action) }
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
