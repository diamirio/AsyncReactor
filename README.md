# AsyncReactor Example

![Tailored Apps Logo](https://www.tailored-apps.com/wp-content/uploads/2015/04/logo_TaioredApps_2x1.png)

![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-FA7343?style=for-the-badge&logo=swift&logoColor=white)

This is an iOS app template which basically is a small example project to demonstrate the usage of "AsyncReactor" package and some basic SwiftUI views. 

### Table of Contents
* [Usage & Notes](#usage_notes)
* [GitHub Example Description](#example_description)
* [License](#license)

## Usage & Notes <a name="usage_notes"></a>
AsyncReactor is a generic swift protocol which mainly stands for holding the state & handling background operations of the related SwiftUI view. Classes to be used as reactor of a view just need to implement the "AsyncReactor" protocol and implement the necessary predefined abstract functions/variables.

- Each SwiftUI view which needs to hold/observe a variable/state or needs to do some background operations should have a "Reactor" class defined in the SwiftUI view struct as "@EnvironmentObject".
- Each UI or background operations should be defined in "Action" enum in the reactor. "action()" function is the place where actual operations of these predefined actions are defined and executed. Each case in the Actions enum should be defined through a "switch" statement spesifically.
- Reactor State:
    - All the data, variables etc. should be placed in "State" struct.
    - Variables in the struct should have a default value so it can be initialized in the init block of the reactor.
    - There should be a state variable which holds the current state of the reactor. State var should be "Published" so the related SwiftUI view is notified whenever the data changed in the reactor. 
    - Setter of the reactor state should be **private** so it must be editable only from the reactor itself.
- "send()" function can be also used to invoke an action outside in non-background context.
- Variables which will be used as a "@Binding" variable in SwiftUI views can be annotated with "@ActionBinding" with an action in the reactor so the state will be updated automatically when this binding variable is reached. Various example use cases can be found in [RepositorySearchView](https://github.com/diamirio/AsyncReactor/blob/main/Example/AsyncReactorExample/Features/Repository/Search/RepositorySearchView.swift)

**Note:** "action()" function is already an async function and all the operations are being executed in a background task. So there is no need to create seperate "Task(s)" for the background operations. 

An example use case for such reactor can be found in the project ([here](https://github.com/diamirio/AsyncReactor/blob/main/Example/AsyncReactorExample/Features/Repository/Search/RepositorySearchReactor.swift))

## Description of the GitHub Search Example <a name="example_description"></a>
The example app basically uses the GitHub REST API to search repositories across the platform. It consist of two screens; RepositorySearch & RepositoryDetail.

- **Repository Search**
    RepositorySearchView uses the search endpoint of Github API to list the repositories based on user's search input. ".load" action in the reactor is the place where the network request is executed repositories are retrieved from the backend service. 
    "query" binding var is annotated with "@ActionBinding" so ".enterQuery" action will be invoked and ".load" action will be called whenever the query changes in the TextField in RepositorySearchView.
    List of repositories are being sorted by "counts of watchers or forks" chosen by user. Selected SortOption is stored in UserDefaults as key-value pairs ([see the usage here](https://github.com/diamirio/AsyncReactor/blob/main/Example/AsyncReactorExample/Features/Repository/Search/RepositorySearchReactor.swift)). Since the values stored in UserDefaults are stored in the device itself; the values are being restored even when the app is fully stopped.

- **Repository Detail**
    When a repository selected from the list in RepositorySearchView, the app is navigated to RepositoryDetailView. RepositoryDetail is basically stands for displaying more detail info about the selected repository.
    Selected repository is defined in the struct to be able to pass it to the view from the list.
    Detail view also has some additional demonstrations for such native SwiftUI functionalities like long running operations, sheet, url navigation etc. 

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
