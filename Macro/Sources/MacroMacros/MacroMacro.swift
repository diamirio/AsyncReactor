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

public struct ReactorMacro: ExtensionMacro, MemberMacro, PeerMacro {
    public static func expansion(of node: AttributeSyntax, attachedTo declaration: some DeclGroupSyntax, providingExtensionsOf type: some TypeSyntaxProtocol, conformingTo protocols: [TypeSyntax], in context: some MacroExpansionContext) throws -> [ExtensionDeclSyntax] {
        let reactorExtension: DeclSyntax =
              """
              extension \(type.trimmed): AsyncReactor {}
              """
        
        guard let extensionDecl = reactorExtension.as(ExtensionDeclSyntax.self) else {
            return []
        }
        
        return [extensionDecl]
    }
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        guard let classDeclaration = declaration.as(ClassDeclSyntax.self) else {
            preconditionFailure("@Reactor can only be applied to classes")
        }
        
        let info = extractInfo(declaration: classDeclaration)
        
        var results = [
            """
            @Published
            @MainActor
            private(set) var state: State
            """
        ]
        
        var initializer = ""
        
        if info.canGenerateInitializer {
            initializer += "@MainActor convenience init("
            
            for dependency in info.dependencies {
                initializer += "\(dependency.variableName): Type,"
            }
        }
        
        /*
         @MainActor
         convenience init(gitHubApi: GitHubAPI) {
             self.init()
             
             $gitHubApi.value = {
                 gitHubApi
             }
         }
         */
        
        return results.map { DeclSyntax(stringLiteral: $0) }
    }
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        guard let classDeclaration = declaration.as(ClassDeclSyntax.self) else {
            preconditionFailure("@Reactor can only be applied to classes")
        }
        
        let info = extractInfo(declaration: classDeclaration)
        
        var environmentDeclarations = ""
        
        for dependency in info.dependencies {
            environmentDeclarations.append(
                """
                @Environment(\\.\(dependency.envKeyPath))
                private var \(dependency.envKeyPath)
                """
            )
        }
        
        var providers = ""
        
        for dependency in info.dependencies {
            providers.append(
                """
                reactor.$\(dependency.variableName).value = {
                    \(dependency.envKeyPath)
                }
                """
            )
        }
        
        var initWithDefaultReactor = ""
        
        if info.canGenerateInitializer {
            initWithDefaultReactor = """
            @MainActor
            init(definesLifecycle: Bool = true, @ViewBuilder content: () -> Content) {
                self.init(\(info.reactorType)(), definesLifecycle: definesLifecycle, content: content)
            }
            """
        }
        
        return [
            """
            struct \(raw: info.reactorType)View<Content: SwiftUI.View>: SwiftUI.View {
                let content: Content
                let definesLifecycle: Bool
                
                @StateObject
                private var reactor: \(raw: info.reactorType)
                
                \(raw: environmentDeclarations)
                
                @MainActor
                init(_ reactor: @escaping @autoclosure () -> \(raw: info.reactorType), definesLifecycle: Bool = true, @ViewBuilder content: () -> Content) {
                    _reactor = StateObject(wrappedValue: reactor())
                    self.content = content()
                    self.definesLifecycle = definesLifecycle
                }
            
                \(raw: initWithDefaultReactor)
            
                var body: some View {
                    content
                        .environmentObject(reactor)
                        .reactorLifecycle(definesLifecycle ? reactor : nil)
                        .onAppear {
                            \(raw: providers)
                        }
                }
            }
            """
        ]
    }
    
    struct Info {
        struct Dependency {
            let variableName: String
            let type: String
            let envKeyPath: String
        }
        
        let reactorType: String
        let dependencies: [Dependency]
        let canGenerateInitializer: Bool
    }
    
    static func extractInfo(declaration: ClassDeclSyntax) -> Info {
        let reactorType = declaration.identifier.text
        
        var dependencies = [Info.Dependency]()
        
        var canGenerateInitializer = false
        
        for member in declaration.memberBlock.members {
            if let variable = member.decl.as(VariableDeclSyntax.self), let attributes = variable.attributes {
                for attribute in attributes {
                    guard let attribute = attribute.as(AttributeSyntax.self),
                          let name = attribute.attributeName.as(SimpleTypeIdentifierSyntax.self)?.name, name.text == "Dependency",
                          let argument = attribute.argument?.as(TupleExprElementListSyntax.self),
                          let keyPath = argument.first?.as(TupleExprElementSyntax.self)?.expression.as(KeyPathExprSyntax.self),
                          let keyPathName = keyPath.components.first?.component.as(KeyPathPropertyComponentSyntax.self)?.identifier.text,
                          let variableName = variable.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else { continue }
                    
                    dependencies.append(.init(variableName: variableName, type: "", envKeyPath: keyPathName))
                }
            } else if let initializer = member.decl.as(InitializerDeclSyntax.self) {
                let parameterList = initializer.signature.input.parameterList
                
                if parameterList.isEmpty || parameterList.allSatisfy({ $0.defaultArgument != nil }) {
                    canGenerateInitializer = true
                }
            }
        }
        
        return Info(reactorType: reactorType, dependencies: dependencies, canGenerateInitializer: canGenerateInitializer)
    }
}

@main
struct MacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
        ReactorMacro.self
    ]
}
