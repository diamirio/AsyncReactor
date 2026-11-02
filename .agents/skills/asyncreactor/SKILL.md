---
name: asyncreactor
description: Build SwiftUI features with diamirio/AsyncReactor — the Reactor protocol (iOS 17+, @Observable) and AsyncReactor protocol (iOS 15/16, ObservableObject), State, Action and SyncAction, ReactorView, ActionBinding, bind(_:action:), send, cancellation with CancelId (inFlight / lifecycle) and reactorLifecycle. Use when a project imports Reactor or AsyncReactor, when creating or reviewing a reactor, its view, actions, bindings or cancellation, when testing a reactor, or when choosing between Reactor and AsyncReactor.
---

# AsyncReactor

A small architecture for SwiftUI: a **reactor** owns a feature's `State` and handles `Action`s; the **view** renders state and sends actions. The package has three modules:

| Module | Import | Use |
|---|---|---|
| `Reactor` | `import Reactor` | iOS 17 / macOS 14 / tvOS 17 / watchOS 10+. `@Observable` reactors. **Default choice.** |
| `AsyncReactor` | `import AsyncReactor` | iOS 15 / macOS 12+. `ObservableObject` reactors with `@Published`. |
| `ReactorBase` | (internal) | Shared protocol `ReactorBase`, `CancelId`, binding helpers. Not a product. |

Both reactor flavours can coexist in one app, but a feature uses one. Source of truth: `Sources/ReactorBase`, `Sources/Reactor`, `Sources/AsyncReactor` — read them when unsure. `AsyncLoad<T>` used in examples is **not** part of this package (separate package `diamirio/AsyncLoad`).

## References

- `references/patterns.md` — cancellation (`CancelId`, `lifecycleTask`), bindings, composition, mocks.
- `references/testing.md` — testing a reactor.
- `references/asyncreactor-ios16.md` — the `ObservableObject` flavour.

## Anatomy (Reactor, iOS 17+)

```swift
import Reactor

@Observable
final class SearchReactor: Reactor {
    enum Action {
        case load
        case select(Item)
    }

    enum SyncAction {
        case setQuery(String)
    }

    @Observable
    final class State {
        var query = ""
        var items = AsyncLoad<[Item]>.none
    }

    private(set) var state = State()

    @ObservationIgnored
    private let service: SearchServiceProtocol

    init(service: SearchServiceProtocol) {
        self.service = service
    }

    func action(_ action: Action) async {
        switch action {
        case .load:
            state.items = .loading
            do {
                state.items = .loaded(try await service.search(state.query))
            } catch {
                state.items = .error(error)
            }
        case let .select(item):
            ...
        }
    }

    func action(_ action: SyncAction) {
        switch action {
        case let .setQuery(query):
            state.query = query
        }
    }
}
```

Requirements enforced by the protocols:

- `ReactorBase` is `@MainActor` and `AnyObject` → reactors are main-actor classes.
- `Reactor` requires the reactor **and** its `State` to be `Observable` → put `@Observable` on both; `State` must be a class.
- `Action` and `SyncAction` default to `Never`. Declare only what you need; the matching `action(_:)` has a default empty implementation when the type is `Never`.
- `state` is `private(set)`; views read it, only the reactor mutates it.
- `@dynamicMemberLookup` lets views read `reactor.query` instead of `reactor.state.query`.

## Action vs SyncAction

| | `Action` | `SyncAction` |
|---|---|---|
| Handler | `func action(_:) async` | `func action(_:)` (sync) |
| Use for | async work, I/O, anything with `await` | immediate state changes (text field, toggle, selection) |
| From a view | `reactor.send(.x)` (starts a `Task`) | `reactor.action(.x)` directly |
| From tests | `await reactor.action(.x)` | `reactor.action(.x)` |

`send(_:)` is fire-and-forget. Calling `reactor.action(.asyncAction)` from a synchronous closure does not compile without `await`/`Task`; use `send`.

## Views

```swift
struct SearchView: View {
    private init() {}

    static func create(service: SearchServiceProtocol = SearchService.current) -> some View {
        ReactorView(SearchReactor(service: service)) {
            SearchView()
        }
    }

    @Environment(SearchReactor.self)
    private var reactor

    @ActionBinding(SearchReactor.self, keyPath: \.query, action: { .setQuery($0) })
    private var query: String

    var body: some View {
        List(reactor.items.item ?? []) { item in
            Button(item.title) { reactor.send(.select(item)) }
        }
        .searchable(text: $query)
        .task { await reactor.action(.load) }
    }
}
```

- `ReactorView(_ reactor: @autoclosure …, definesLifecycle: true) { content }` stores the reactor in `@State` (Reactor) / `@StateObject` (AsyncReactor), injects it into the environment and cancels its lifecycle tasks when the view goes away. Pass the reactor expression directly. With `Reactor`, the autoclosure is evaluated every time the `ReactorView` is initialized (the extra instance is discarded), so keep reactor `init` cheap and free of side effects — start loading from `.task { }` rather than from `init`.
- Read the reactor with `@Environment(MyReactor.self)` (Reactor) or `@EnvironmentObject` (AsyncReactor). `ActionBinding` requires that a `ReactorView` for that reactor type is an ancestor.
- A reactor on `ReactorView` with `definesLifecycle: false` leaves cancellation to a parent (child view sharing the parent's reactor).

## Bindings

Two ways to bind state to a control; both write through an action instead of mutating state:

- `@ActionBinding(R.self, keyPath: \.value, action: { .set($0) })` — property wrapper in a view. Add `cancelId:` for async actions.
- `reactor.bind(\.value, action: { .set($0) })` → `Binding<T>`; use for ad-hoc bindings (`Toggle(isOn: reactor.bind(\.flag, action: .toggle))`).

A `SyncAction` binding applies immediately; an `Action` binding runs in a `Task`, so the state updates after the action's first suspension point — use `SyncAction` for text fields.

## Cancellation (summary)

`CancelId(id:mode:)` with `mode` `.inFlight` (cancel the previous task with the same id, e.g. search-as-you-type) and/or `.lifecycle` (cancel when the owning `ReactorView` disappears). Use `reactor.send(.search, id: CancelId(id: "search", mode: [.inFlight, .lifecycle]))`. Cancellation is cooperative: the action body must hit a cancellable `await` or check `Task.isCancelled`, and must not write an error state for a `CancellationError`. See `references/patterns.md`.

## Rules

- One reactor per feature screen, in its own file next to the view. Do not share a parent reactor with child screens.
- Reactor owns state, validation and async work; the view owns layout, focus and presentation. Dismissal and navigation are owned by the presenter: pass callbacks into the reactor/child instead of using `@Environment(\.dismiss)` in a child.
- Inject side-effecting dependencies (API, storage, clock) through protocols in `init`, default to the live one; previews and tests pass mocks. Never construct live services in a view body.
- Mark non-state stored properties of an `@Observable` reactor with `@ObservationIgnored`.
- Model request state with one value (`AsyncLoad<T>`: `.none/.loading/.loaded/.error`), not separate `isLoading`/`error`/`data` flags.
- Do not call `Task { await reactor.action(...) }` from views when `send` does the same.
- Do not mutate `state` from outside the reactor.

## Choosing a flavour

Deployment target iOS 17+: `Reactor`. Supporting iOS 15/16: `AsyncReactor`. Migrating: change the protocol, `@Published private(set) var state` → `private(set) var state` with `@Observable`, `State` struct → `@Observable class`, `@EnvironmentObject` → `@Environment(R.self)`. The action API stays the same.
