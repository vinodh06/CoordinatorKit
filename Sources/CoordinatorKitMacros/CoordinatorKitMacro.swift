import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum CoordinatorKit: MemberMacro, ExtensionMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf decl: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self),
              let routeType = arguments.first?.expression.description else {
            throw CustomError.message("@Coordinator macro requires a type NavigationRoute")
        }

        // Members
        let memberDecls: [DeclSyntax] = [
            "@Published internal var navigationPath: [\(routeType)] = []",
            "@Published internal var sheetRoute: \(routeType)?",
            "@Published internal var fullScreenRoute: \(routeType)?",
            "let actionDispatcher = ActionDispatcher<\(routeType).Action>()",
            "var actionCancellables = Set<AnyCancellable>()"
        ].map { DeclSyntax(stringLiteral: $0) }

        let deinitDecl = DeclSyntax(stringLiteral: """
            deinit {
                Task { @MainActor in
                    cleanup()
                }
            }
            """
        )
        
        return memberDecls + [deinitDecl]
    }

    // Adds protocol conformance via extension
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let typeName = type.as(IdentifierTypeSyntax.self)?.name.text else {
            throw CustomError.message("Unable to determine type name for extension.")
        }

        let ext = try ExtensionDeclSyntax("@MainActor extension \(raw: typeName): Coordinator {}")
        return [ext]
    }
}


enum CustomError: Error, CustomStringConvertible {
    case message(String)
    var description: String {
        switch self {
        case .message(let msg): return msg }
    }
}

@main
struct CoordinatorKitPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CoordinatorKit.self
    ]
}


