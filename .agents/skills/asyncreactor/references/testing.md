# Testing a reactor

Use Swift Testing. Test the reactor with a stubbed service; do not test the view or build a mock reactor.

## Facts that shape the tests

- `ReactorBase` is `@MainActor` → the test suite is `@MainActor`.
- `await sut.action(.x)` runs the action to completion → call it directly, then assert.
- **Never call `send` in a test.** It starts an unstructured `Task` and returns immediately, so the assertion races the action.
- `SyncAction` is handled by the synchronous `action(_:)` → call it without `await`.
- `action(_:id:)` with `CancelId(id:mode: .inFlight)` cancels the previous in-flight call with the same id. The cancelled call sees `CancellationError`.
- Work started in `init` (`send(...)`, `lifecycleTask { … }`) runs in tasks nobody can await. Move it into an action (e.g. `.onAppear`) and test that action. Do not write tests that wait for it.
- `reactor.query` (via `@dynamicMemberLookup`) and `reactor.state.query` are equivalent; tests use `sut.state.…` to make clear what is asserted.

## Template

```swift
import AsyncLoad
import Foundation
import Testing
@testable import MyApp

@MainActor
struct SearchReactorTests {
    let service = SearchServiceStub()

    @Test("Load stores the found items")
    func loadSuccess() async {
        // Given
        service.results = ["": [.fixture(title: "Cats")]]
        let sut = SearchReactor(service: service)

        // When
        await sut.action(.load)

        // Then
        #expect(sut.state.items.item == [.fixture(title: "Cats")])
    }

    @Test("Network error is stored as error state")
    func loadFailure() async {
        // Given
        service.error = URLError(.notConnectedToInternet)
        let sut = SearchReactor(service: service)

        // When
        await sut.action(.load)

        // Then
        #expect((sut.state.items.error as? URLError)?.code == .notConnectedToInternet)
    }

    @Test("Setting the query updates the state")
    func setQuery() {
        // Given
        let sut = SearchReactor(service: service)

        // When
        sut.action(.setQuery("cats"))          // SyncAction: no await

        // Then
        #expect(sut.state.query == "cats")
    }
}
```

```swift
// TestSupport/SearchServiceStub.swift
final class SearchServiceStub: SearchServiceProtocol, @unchecked Sendable {
    var results: [String: [Item]] = [:]
    var error: Error?
    /// Queries whose request stays in flight until the calling task is cancelled.
    var pendingQueries: Set<String> = []
    private(set) var queries: [String] = []

    func search(_ query: String) async throws -> [Item] {
        queries.append(query)
        if pendingQueries.contains(query) {
            let (stream, continuation) = AsyncStream<Never>.makeStream()
            await withTaskCancellationHandler {
                for await _ in stream {}
            } onCancel: {
                continuation.finish()
            }
            throw CancellationError()
        }
        if let error { throw error }
        return results[query] ?? []
    }
}
```

Pass the stub through the reactor's initializer, or register it in the project's DI container before creating the reactor.

## Coverage per reactor

- One test per `Action` / `SyncAction` case: state before → after.
- Every `catch` branch: error state set, loading flags reset, `CancellationError` leaves the state untouched.
- Calls on collaborators: the stub records the arguments (`service.queries`).
- To start from a specific state, set it up with `SyncAction`s or a preset initial state instead of replaying async actions.

## Cancellation with `CancelId`

```swift
@Test("A second load cancels the one in flight")
func inFlightLoadIsCancelled() async {
    // Given
    service.pendingQueries = [""]
    service.results = ["cats": [.fixture(title: "Cats")]]
    let sut = SearchReactor(service: service)
    let first = Task { await sut.action(.load, id: CancelId(id: "search", mode: .inFlight)) }
    while service.queries.isEmpty { await Task.yield() }   // first request is in flight

    // When
    sut.action(.setQuery("cats"))
    await sut.action(.load, id: CancelId(id: "search", mode: .inFlight))
    await first.value

    // Then
    #expect(service.queries == ["", "cats"])
    #expect(sut.state.items.item == [.fixture(title: "Cats")])
}
```

`CancelId` lives in `ReactorBase` → the test file needs `import ReactorBase`.

The same pattern covers intermediate state: keep the request pending, yield until the stub was called, assert `sut.state.items == .loading`, then cancel `first` or let it finish.

## Views

Views are thin and driven by state. Cover their look with snapshot tests and inject the reactor into the view: `ReactorView(reactor) { … }`, `.environment(reactor)` (Reactor) or `.environmentObject(reactor)` (AsyncReactor).
