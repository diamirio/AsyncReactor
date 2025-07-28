# AsyncReactor Example

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/diamirio/AsyncReactor/assets/19715246/56eef378-e63e-4732-8710-040d3440afbb">
  <img alt="DIAMIR Logo" src="https://github.com/diamirio/AsyncReactor/assets/19715246/8424fef3-5aeb-4e15-af36-55f1f3fc37b0">
</picture>

![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-FA7343?style=for-the-badge&logo=swift&logoColor=white)

AsyncReactor is a reactive architecural pattern to organize your Swift code.

## Table of Contents
 - [Usage](#usage)
   - [General](#general)
   - [Reactor Package (iOS 17+)](#reactor-package-ios-17)
   - [AsyncReactor Package (iOS <17)](#asyncreactor-package-ios-17)
   - [Integration](#integration)
     - [State updates](#state-updates)
     - [Actions](#actions)
     - [Action Bindings](#action-bindings)
 - [Example ](#example)
   - [License ](#license)

## Usage<a name="usage"></a>
### General
AsyncReactor is a reactive architecural pattern. The main component is an `AsyncReactor`. This `AsyncReactor` holds the `State` as well as the `Actions`.

### Reactor Package (iOS 17+)

With iOS 17 and later, we introduced the new **`Reactor`** package, which includes a protocol also named `Reactor`.

Thanks to the new `@Observable` macro in Swift, there’s no longer the need to explicitly mark the `State` as `@published`. By addibg the `@Observable` macro to your reactor class, the entire class is now automatically observable. If you want to exclude specific properties from observation, you can use the `@ObservationIgnored` macro.

The way actions are handled remains the same as before — simply define an `Action` enum and implement the `action(_:)` method asynchronously.

> ✅ Both versions of the Reactor (pre-iOS 17 and the new iOS 17+ version) can coexist in your app, as they are implemented in separate packages.

```Swift
import Reactor

@Observable
public class CatFactsReactor: Reactor

public enum Action {
    case loadCatFact
}

@Observable
public class State {
    var fact: AsyncLoad<String> = .none
}
    
public private(set) var state = State()
    
@ObservationIgnored
private var catFactService: CatFactService

public init() {
    send(.loadCatFact)
}

public func action(_ action: Action) async {
    switch action {
    case .loadCatFact:
        state.fact = .loading

        do {
            let fact = try await catFactService.getRandomCatFact().fact
            state.fact = .loaded(fact)
        } catch {
             state.fact = .error(error)
        }
    }
}
```

## AsyncReactor Package (iOS <17)

```Swift
class RepositorySearchReactor: AsyncReactor {
    enum Action {
        ...
    }
    
    struct State {
        ...
    }
    
    @Published
    private(set) var state: State

    func action(_ action: Action) async { 
        ...
    }
}
```

## Integration
The `AsyncReactor` is provided to the child view as an `EnvironmentObject`. This is set by the `ReactorView`.
```Swift
ReactorView(RepositorySearchReactor()) {
    RepositorySearchView()
}
```

Now the reactor can simply be used in the SwiftUI view as follows.
```Swift
struct RepositorySearchView: View {

    @EnvironmentObject
    private var reactor: RepositorySearchReactor

    var body: some View { 
        ... 
    }
}
```

### State updates
Whenever the `State` in the reactor changes, the view will updated accordingly. It is also possibel to bind the `State`.

```Swift
var body: some View { 
    Text(reactor.state.name)
}
``````


### Actions
Actions are used to trigger a behaviour in our reactor. 

```Swift
var body: some View { 
    Button("Click me") {
        reactor.action(.buttonClick)
    }
}
``````


### Action Bindings
Action bindings enable us to bind values of the state in our view.

```Swift
struct RepositorySearchView: View {

    ...

    @ActionBinding(RepositorySearchReactor.self, 
                   keyPath: \.hidePrivate,
                   action: .onHidePrivateToggle)
    private var hidePrivate: Bool

    var body: some View { 
        Toggle("Hide Private Repos", isOn: $hidePrivate)
    }
}

class RepositorySearchReactor: AsyncReactor {
  
    ...

    func action(_ action: Action) async {
        switch action {
        case .onHidePrivateToggle:
            state.hidePrivate.toggle()

        ...

        }
    }
}
```

## Example <a name="example"></a>
An example can be found in the [Example](./Example/AsyncReactorExample) folder.

## License <a name="license"></a>
```
MIT License

Copyright (c) 2023 DIAMIR Holding

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
