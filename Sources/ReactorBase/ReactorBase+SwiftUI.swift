//
//  ReactorBase+SwiftUI.swift
//  AsyncReactor
//
//  Created by Dominik Arnhof on 23.11.24.
//

#if canImport(SwiftUI)
import SwiftUI

extension ReactorBase {
    @MainActor
    public func bind<T>(
        _ keyPath: KeyPath<State, T>,
        cancelId: CancelId? = nil,
        action: @escaping (T) -> AsyncAction
    ) -> Binding<T> {
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
    public func bind<T>(
        _ keyPath: KeyPath<State, T>
        , cancelId: CancelId? = nil,
        action: @escaping @autoclosure () -> AsyncAction
    ) -> Binding<T> {
        bind(keyPath, cancelId: cancelId) { _ in action() }
    }
    
    @MainActor
    public func bind<T>(
        _ keyPath: KeyPath<State, T>,
        action: @escaping (T) -> SyncAction
    ) -> Binding<T> {
        Binding {
            self.state[keyPath: keyPath]
        } set: { newValue in
            self.action(action(newValue))
        }
    }
    
    @MainActor
    public func bind<T>(
        _ keyPath: KeyPath<State, T>,
        action: @escaping @autoclosure () -> SyncAction
    ) -> Binding<T> {
        bind(keyPath) { _ in action() }
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
    
    init(reactor: (any ReactorBase)?) {
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
    public func reactorLifecycle(_ reactor: (any ReactorBase)?) -> some View {
        modifier(ReactorLifecycleCancel(reactor: reactor))
    }
}
#endif

