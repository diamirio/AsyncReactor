import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Implementation of the `stringify` macro, which takes an expression
/// of any type and produces a tuple containing the value of that expression
/// and the source code that produced the value. For example
///
///     #stringify(x + y)
///
///  will expand to
///
///     (x + y, "x + y")
public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.argumentList.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        return "(\(argument), \(literal: argument.description))"
    }
}

public struct ReactorMacro: ConformanceMacro, MemberMacro, PeerMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingConformancesOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [(SwiftSyntax.TypeSyntax, SwiftSyntax.GenericWhereClauseSyntax?)] {
        [("AsyncReactor", nil)]
    }
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        [
            """
            @Published
            @MainActor
            private(set) var state: State
            """
        ]
    }
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        guard let classDeclaration = declaration.as(ClassDeclSyntax.self) else {
            preconditionFailure("@Reactor can only be applied to classes")
        }
        
        let reactorType = classDeclaration.identifier.text
        
        var dependencies = [(variableName: String, keyPath: String)]()
        
        for member in classDeclaration.memberBlock.members {
            guard let variable = member.decl.as(VariableDeclSyntax.self), let attributes = variable.attributes else { continue }
            
            for attribute in attributes {
                guard let attribute = attribute.as(AttributeSyntax.self),
                      let name = attribute.attributeName.as(SimpleTypeIdentifierSyntax.self)?.name, name.text == "Dependency",
                      let argument = attribute.argument?.as(TupleExprElementListSyntax.self),
                      let keyPath = argument.first?.as(TupleExprElementSyntax.self)?.expression.as(KeyPathExprSyntax.self),
                      let keyPathName = keyPath.components.first?.component.as(KeyPathPropertyComponentSyntax.self)?.identifier.text,
                      let variableName = variable.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else { continue }
                dependencies.append((variableName: variableName, keyPath: keyPathName))
            }
        }
        
        var environmentDeclarations = ""
        
        for dependency in dependencies {
            environmentDeclarations.append(
                """
                @Environment(\\.\(dependency.keyPath))
                private var \(dependency.keyPath)
                """
            )
        }
        
        var providers = ""
        
        for dependency in dependencies {
            providers.append(
                """
                reactor.$\(dependency.variableName).value = {
                    \(dependency.keyPath)
                }
                """
            )
        }
        
        // NOTE: AnyView for body is a workaround for a bug where `var body: some View` produces a linker error...
        return [
            """
            struct \(raw: reactorType)View<Content: SwiftUI.View>: SwiftUI.View {
                let content: Content
                let definesLifecycle: Bool
                
                @StateObject
                private var reactor: \(raw: reactorType)
                
                \(raw: environmentDeclarations)
                
                init(_ reactor: @escaping @autoclosure () -> \(raw: reactorType), definesLifecycle: Bool = true, @ViewBuilder content: () -> Content) {
                    _reactor = StateObject(wrappedValue: reactor())
                    self.content = content()
                    self.definesLifecycle = definesLifecycle
                }
                
                private var realBody: some SwiftUI.View {
                    content
                        .environmentObject(reactor)
                        .reactorLifecycle(definesLifecycle ? reactor : nil)
                        .onAppear {
                            \(raw: providers)
                        }
                }
            
                var body: AnyView {
                    AnyView(realBody)
                }
            }
            """
        ]
    }
}

@main
struct MacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
        ReactorMacro.self
    ]
}
