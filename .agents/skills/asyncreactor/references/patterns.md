# Patterns

## Cancellation

```swift
// In-flight: a new search cancels the previous one
reactor.send(.search(text), id: CancelId(id: "search", mode: .inFlight))

// Lifecycle: cancelled when the owning ReactorView goes away
reactor.send(.observeUpdates, id: CancelId(id: "updates", mode: .lifecycle))

// Both
reactor.send(.search(text), id: CancelId(id: "search", mode: [.inFlight, .lifecycle]))
```

How it works (see `ReactorBase.swift`):

- Tasks are kept in a main-actor dictionary keyed by reactor identity + `CancelId`.
- `.inFlight` cancels the existing task for the same key before starting the new one.
- `cancelLifecycleTasks()` cancels every task of that reactor whose mode contains `.lifecycle`. `ReactorView` calls it when its lifecycle model deinitializes (`definesLifecycle: true`). Without `.lifecycle`, a task is not cancelled when the view goes away.
- `lifecycleTask { ... }` runs a long-lived `@Sendable` async closure as a lifecycle task (detached from the main actor — hop back to `@MainActor` to touch state, e.g. via a reactor method or `await MainActor.run`).

Cancellation is cooperative. In the action:

```swift
case let .search(text):
    state.results = .loading
    do {
        let results = try await service.search(text)     // throws CancellationError if cancelled
        state.results = .loaded(results)
    } catch is CancellationError {
        return                                           // do not show an error for cancelled work
    } catch {
        state.results = .error(error)
    }
```

URLSession's `async` APIs throw `URLError(.cancelled)` rather than `CancellationError`; handle both or check `Task.isCancelled` before writing state.

## Bindings

```swift
// SyncAction: immediate (text fields, toggles)
@ActionBinding(FormReactor.self, keyPath: \.name, action: { .setName($0) })
private var name: String

// Async Action with cancellation
@ActionBinding(
    SearchReactor.self,
    keyPath: \.query,
    cancelId: CancelId(id: "search", mode: .inFlight),
    action: { .search($0) }
)
private var query: String

// One-off binding
Toggle("Private", isOn: reactor.bind(\.hidePrivate, action: .togglePrivate))
```

The `action:` closure receives the new value; an autoclosure form without a parameter is available for actions that carry no value.

## Composition and navigation

- Give each screen a `static func create(...)` factory that wraps the view in `ReactorView(Reactor(...))`; call sites never instantiate reactors.
- Parent → child: pass data and callbacks (`onSave: () -> Void`) to the child's factory. The parent changes its own sheet/navigation state in the callback.
- Child views that only render parent state and own no business logic may read the parent's reactor from the environment and use `ReactorView(..., definesLifecycle: false)` only when they really share it; prefer a separate reactor.

## Dependencies and mocks

```swift
protocol SearchServiceProtocol: Sendable {
    func search(_ query: String) async throws -> [Item]
}

struct SearchServiceMock: SearchServiceProtocol { ... }

#Preview {
    SearchView.create(service: SearchServiceMock())
}
```

Use the real reactor with a mock service; do not build a mock reactor.

## Request state

Use one `AsyncLoad<T>` (optional package `diamirio/AsyncLoad`, see skill `asyncload`) per request: `.none`, `.loading`, `.loaded(T)`, `.error(Error)`. Set `.loading` before the work, `.loaded`/`.error` after. Do not mirror it with `isLoading`/`errorMessage` booleans.
