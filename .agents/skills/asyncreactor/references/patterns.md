# Patterns

## Cancellation

Needs `import ReactorBase` for `CancelId`.

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

## Long-lived work: observing notifications and streams

For work that lives as long as the screen — `NotificationCenter`, `AsyncSequence`s, store updates — use `lifecycleTask`. It is cancelled automatically when the owning `ReactorView` disappears.

```swift
import AsyncLoad
import Reactor
import ReactorBase

extension Notification.Name {
    static let didChangeDeviceFavorites = Notification.Name("didChangeDeviceFavorites")
}

@Observable
final class DevicesReactor: Reactor {
    enum Action {
        case startObservingFavorites
        case loadFavoriteDevices
    }

    @Observable
    final class State {
        var favorites = AsyncLoad<[Device]>.none
    }

    private(set) var state = State()

    @ObservationIgnored
    private var isObservingFavorites = false

    func action(_ action: Action) async {
        switch action {
        case .startObservingFavorites:
            guard !isObservingFavorites else { return }
            isObservingFavorites = true

            lifecycleTask { [weak self] in
                for await _ in NotificationCenter.default.notifications(named: .didChangeDeviceFavorites) {
                    guard let self else { return }
                    await self.action(.loadFavoriteDevices)
                }
            }

        case .loadFavoriteDevices:
            ...
        }
    }
}
```

```swift
.task {
    reactor.send(.startObservingFavorites)
    await reactor.action(.loadFavoriteDevices)
}
```

Things to get right:

- **Do not start it in `init`.** With `Reactor`, `ReactorView` evaluates its reactor autoclosure on every initialization of the view and keeps only the first instance. A `lifecycleTask` started in `init` of a discarded instance is never cancelled — it runs forever, keeps that instance alive and reacts to every notification. Start it from an action triggered by the view (`.task`, `.onAppear`).
- **Guard against starting twice.** `lifecycleTask` does not deduplicate, and `.task` can run again when the view re-appears. Use a flag as above, or the `CancelId` variant below.
- **Capture `self` weakly** in the loop and check it per iteration, so an idle `for await` does not keep the reactor alive.
- `lifecycleTask` takes a `@Sendable` async closure and runs it detached from the main actor. Touch state only through the reactor's main-actor API (`await self.action(...)`), not by mutating `state` inside the closure.
- The task ends when the `ReactorView` goes away (`definesLifecycle: true`). With `definesLifecycle: false`, something else must call `cancelLifecycleTasks()`.

Alternative without a flag — run the loop inside an action and give it a `CancelId`; `.inFlight` replaces a previous run and `.lifecycle` cancels it with the view:

```swift
case .observeFavorites:
    for await _ in NotificationCenter.default.notifications(named: .didChangeDeviceFavorites) {
        await self.action(.loadFavoriteDevices)
    }
```

```swift
.task {
    reactor.send(.observeFavorites, id: CancelId(id: "favorites", mode: [.inFlight, .lifecycle]))
}
```

Prefer this variant when the loop needs no extra setup; prefer `lifecycleTask` for fire-and-forget background work started from an action.

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

Use one `AsyncLoad<T>` per request: `.none`, `.loading`, `.loaded(T)`, `.error(Error)`. Set `.loading` before the work, `.loaded`/`.error` after. Do not mirror it with `isLoading`/`errorMessage` booleans. AsyncLoad is a separate, optional package (`diamirio/AsyncLoad`): recommend it if the project lacks it, never add it unasked, and use an own enum of the same shape if the user does not want it (see "Request state" in `SKILL.md`).
