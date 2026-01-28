//
//  ReactorBase.swift
//  AsyncReactor
//
//  Created by Dominik Arnhof on 23.11.24.
//

import Foundation

@MainActor
@dynamicMemberLookup
public protocol ReactorBase: AnyObject {
    associatedtype Action = Never
    associatedtype SyncAction = Never
    associatedtype State
    
    var state: State { get }
    
    func action(_ action: Action) async
    
    func action(_ action: SyncAction)
    
    subscript<Value>(dynamicMember keyPath: KeyPath<State, Value>) -> Value { get }
}

extension ReactorBase {
    @MainActor
    public func send(_ action: Action) {
        Task { await self.action(action) }
    }
}

extension ReactorBase where Action == Never {
    public func action(_ action: Action) async {
        
    }
}

extension ReactorBase where SyncAction == Never {
    public func action(_ action: SyncAction) {
        
    }
}

// MARK: - DynamicMemberLookup

extension ReactorBase {
    @MainActor
    public subscript<Value>(dynamicMember keyPath: KeyPath<State, Value>) -> Value {
        state[keyPath: keyPath]
    }
}

// MARK: - Cancellation Support

public struct CancelId: Hashable, Sendable {
    let id: UUID
    let mode: Mode
    
    public init(id: UUID, mode: Mode) {
        self.id = id
        self.mode = mode
    }
    
    public struct Mode: OptionSet, Hashable, Sendable {
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static var lifecycle: Mode {
            Mode(rawValue: 1 << 0)
        }
        
        public static var inFlight: Mode {
            Mode(rawValue: 1 << 1)
        }
    }
}

@MainActor
class TasksHolder {
    var tasks = [TaskKey: Task<Void, Never>]()
    
    static var shared: TasksHolder = TasksHolder()
}

struct TaskKey: Hashable, Sendable {
    let reactorId: ObjectIdentifier
    let id: CancelId
    
    init(reactor: AnyObject, id: CancelId) {
        reactorId = ObjectIdentifier(reactor)
        self.id = id
    }
}

extension ReactorBase {
    @MainActor
    public func action(_ action: Action, id: CancelId) async {
        let key = TaskKey(reactor: self, id: id)
        
        if id.mode.contains(.inFlight) {
            TasksHolder.shared.tasks[key]?.cancel()
        }
        
        let task = Task {
            await self.action(action)
        }
        
        TasksHolder.shared.tasks[key] = task
        
        await task.value
        
        if !task.isCancelled {
            TasksHolder.shared.tasks.removeValue(forKey: key)
        }
    }
    
    public func send(_ action: Action, id: CancelId) {
        Task { await self.action(action, id: id) }
    }
    
    public func lifecycleTask(_ action: @escaping @Sendable () async -> ()) {
        Task { @MainActor in
            let key = TaskKey(reactor: self, id: .init(id: UUID(), mode: .lifecycle))
            
            let task = Task.detached {
                await action()
                await MainActor.run { _ = TasksHolder.shared.tasks.removeValue(forKey: key) }
            }
            
            TasksHolder.shared.tasks[key] = task
        }
    }
    
    public func cancelLifecycleTasks() {
        Task { @MainActor in
            let keys = TasksHolder.shared.tasks.keys.filter { $0.id.mode.contains(.lifecycle) && $0.reactorId == ObjectIdentifier(self) }
            
            for key in keys {
                TasksHolder.shared.tasks[key]?.cancel()
                TasksHolder.shared.tasks.removeValue(forKey: key)
            }
        }
    }
}

