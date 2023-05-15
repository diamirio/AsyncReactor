//
//  AsyncReactor.swift
//
//
//  Created by oanhof on 23.06.22.
//

import Foundation

@dynamicMemberLookup
public protocol AsyncReactor: ObservableObject {
    associatedtype Action
    associatedtype State
    
    @MainActor
    var state: State { get }
    
    @MainActor
    func action(_ action: Action) async
    
    subscript<Value>(dynamicMember keyPath: KeyPath<State, Value>) -> Value { get }
}

extension AsyncReactor {
    @MainActor
    public func send(_ action: Action) {
        Task { await self.action(action) }
    }
}

// MARK: - DynamicMemberLookup

extension AsyncReactor {
    @MainActor
    public subscript<Value>(dynamicMember keyPath: KeyPath<State, Value>) -> Value {
        state[keyPath: keyPath]
    }
}

// MARK: - Cancellation Support

public struct CancelId: Hashable {
    let id: AnyHashable
    let mode: Mode
    
    public init(id: AnyHashable, mode: Mode) {
        self.id = id
        self.mode = mode
    }
    
    public struct Mode: OptionSet, Hashable {
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static let lifecycle = Mode(rawValue: 1 << 0)
        public static let inFlight  = Mode(rawValue: 1 << 1)
    }
}

private struct TasksHolder {
    @MainActor
    static var tasks = [TaskKey: Task<Void, Never>]()
}

private struct TaskKey: Hashable {
    let reactorId: ObjectIdentifier
    let id: CancelId
    
    init(reactor: AnyObject, id: CancelId) {
        reactorId = ObjectIdentifier(reactor)
        self.id = id
    }
}

extension AsyncReactor {
    @MainActor
    public func action(_ action: Action, id: CancelId) async {
        let key = TaskKey(reactor: self, id: id)
        
        if id.mode.contains(.inFlight) {
            TasksHolder.tasks[key]?.cancel()
        }
        
        let task = Task {
            await self.action(action)
        }
        
        TasksHolder.tasks[key] = task
        
        await task.value
        
        if !task.isCancelled {
            TasksHolder.tasks.removeValue(forKey: key)
        }
    }
    
    public func send(_ action: Action, id: CancelId) {
        Task { await self.action(action, id: id) }
    }
    
    public func lifecycleTask(_ action: @escaping @Sendable () async -> Void) {
        Task { @MainActor in
            let key = TaskKey(reactor: self, id: .init(id: UUID(), mode: .lifecycle))
            
            let task = Task.detached {
                await action()
                await MainActor.run { _ = TasksHolder.tasks.removeValue(forKey: key) }
            }
            
            TasksHolder.tasks[key] = task
        }
    }
    
    public func cancelLifecycleTasks() {
        Task { @MainActor in
            let keys = TasksHolder.tasks.keys.filter { $0.id.mode.contains(.lifecycle) && $0.reactorId == ObjectIdentifier(self) }
            
            for key in keys {
                TasksHolder.tasks[key]?.cancel()
                TasksHolder.tasks.removeValue(forKey: key)
            }
        }
    }
}
