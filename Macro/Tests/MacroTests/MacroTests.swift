import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import MacroMacros

let testMacros: [String: Macro.Type] = [
    "stringify": StringifyMacro.self,
]

let testMacrosReactor: [String: Macro.Type] = [
    "Reactor": ReactorMacro.self,
]

final class MacroTests: XCTestCase {
//    func testMacro() {
//        assertMacroExpansion(
//            """
//            #stringify(a + b)
//            """,
//            expandedSource: """
//            (a + b, "a + b")
//            """,
//            macros: testMacros
//        )
//    }
//
//    func testMacroWithStringLiteral() {
//        assertMacroExpansion(
//            #"""
//            #stringify("Hello, \(name)")
//            """#,
//            expandedSource: #"""
//            ("Hello, \(name)", #""Hello, \(name)""#)
//            """#,
//            macros: testMacros
//        )
//    }
    
    func testReactorMacro() {
        assertMacroExpansion(
            #"""
            @Reactor
            class TestReactor {
                enum Action {
                    case search(String)
                }
                
                struct State {
                    var query = ""
                }
                
                @Dependency(\.managedObjectContext)
                var context
            
                @Dependency(\.modelContext)
                var modelContext
            
                @MainActor
                init(state: State = State()) {
                    self.state = state
                }
                
                func action(_ action: Action) async {
                    switch action {
                    case .search(let string):
                        print(string)
                    }
                }
            }
            """#,
            expandedSource: #"""
            @Reactor
            class TestReactor {
                enum Action {
                    case search(String)
                }
                
                struct State {
                    var query = ""
                }
                
                @Dependency(\.managedObjectContext)
                var context
            
                @Dependency(\.modelContext)
                var modelContext
            
                @MainActor
                init(state: State = State()) {
                    self.state = state
                }
                
                func action(_ action: Action) async {
                    switch action {
                    case .search(let string):
                        print(string)
                    }
                }
                @Published
                private (set) var state: State

                public struct RView<Content: SwiftUI.View>: SwiftUI.View {
                    let content: Content
                    let definesLifecycle: Bool

                    @StateObject
                    private var reactor: TestReactor

                    @Environment(\.managedObjectContext)
                    private var managedObjectContext
                    @Environment(\.modelContext)
                    private var modelContext

                    public init(_ reactor: @escaping @autoclosure () -> TestReactor, definesLifecycle: Bool = true, @ViewBuilder content: () -> Content) {
                        _reactor = StateObject(wrappedValue: reactor())
                        self.content = content()
                        self.definesLifecycle = definesLifecycle
                    }

                    public var body: some SwiftUI.View {
                        content
                            .environmentObject(reactor)
                            .reactorLifecycle(definesLifecycle ? reactor : nil)
                            .onAppear {
                                reactor.$context.value = {
                    managedObjectContext
                                }
                                reactor.$modelContext.value = {
                                    modelContext
                                }
                            }
                    }
                }
            }
            extension TestReactor: AsyncReactor {
            }
            """#,
            macros: testMacrosReactor
        )
    }
}
