# Testing a reactor

Reactors are `@MainActor`, so tests are too. Call `action` directly and `await` it — do not use `send`, which returns immediately.

```swift
import XCTest
@testable import MyApp

@MainActor
final class SearchReactorTests: XCTestCase {
    func testLoadSuccess() async {
        let reactor = SearchReactor(service: SearchServiceMock(items: [.fixture]))

        await reactor.action(.load)

        XCTAssertEqual(reactor.items.item, [.fixture])
    }

    func testLoadFailure() async {
        let reactor = SearchReactor(service: SearchServiceMock(error: TestError()))

        await reactor.action(.load)

        XCTAssertNotNil(reactor.items.error)
    }

    func testSyncAction() {
        let reactor = SearchReactor(service: SearchServiceMock())

        reactor.action(.setQuery("cats"))

        XCTAssertEqual(reactor.query, "cats")
    }
}
```

- Inject mocks through the reactor's initializer.
- `reactor.query` works through `@dynamicMemberLookup`; `reactor.state.query` is equivalent.
- For cancellation, start the action in a `Task`, cancel it, and assert no error state is written; for `CancelId` flows, send two actions with the same `.inFlight` id and assert only the second result is applied.
- Test the reactor, not the view: views are thin and driven by state.
