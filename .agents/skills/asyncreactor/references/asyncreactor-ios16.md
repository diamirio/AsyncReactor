# AsyncReactor (iOS 15/16)

For deployment targets below iOS 17 use `import AsyncReactor`.

```swift
import AsyncReactor

final class SearchReactor: AsyncReactor {
    enum Action { case load }
    enum SyncAction { case setQuery(String) }

    struct State {
        var query = ""
        var items = AsyncLoad<[Item]>.none
    }

    @Published
    private(set) var state = State()

    func action(_ action: Action) async {
        switch action {
        case .load:
            state.items = .loading
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

- `AsyncReactor` is `ObservableObject & ReactorBase`; `State` may be a struct held in `@Published`.
- View access: `@EnvironmentObject private var reactor: SearchReactor`. `ReactorView` uses `@StateObject` and `.environmentObject(reactor)`.
- `@ActionBinding`, `bind`, `send`, `CancelId` and `reactorLifecycle` behave as in the `Reactor` flavour.
- Any change to `state` republishes the whole object, so every view reading the reactor re-renders. Keep `State` small, or move to `Reactor` where observation is per property.
