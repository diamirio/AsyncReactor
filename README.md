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
   - [Integration](#integration)
     - [State updates](#state-updates)
     - [Actions](#actions)
     - [Action Bindings](#action-bindings)
 - [Example ](#example)
   - [License ](#license)

## Usage<a name="usage"></a>
### General
AsyncReactor is a reactive architecural pattern. The main component is an `AsyncReactor`. This `AsyncReactor` holds the `State` as well as the `Actions`.

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
