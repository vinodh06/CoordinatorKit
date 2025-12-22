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
              let routeTypeExpr = arguments.first?.expression else {
            throw CustomError.message("@Coordinator macro requires a NavigationRoute type")
        }

        let routeType: String
        if let memberAccess = routeTypeExpr.as(MemberAccessExprSyntax.self),
           memberAccess.declName.baseName.text == "self" {
            routeType = memberAccess.base?.description.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        } else {
            routeType = routeTypeExpr.description.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        guard !routeType.isEmpty else {
            throw CustomError.message("Unable to determine route type name")
        }

        let memberDecls: [DeclSyntax] = [
            "@Published var root: \(raw: routeType)",
            "@Published var navigationPath: [\(raw: routeType)] = []",
            "@Published var presentationState = PresentationState<\(raw: routeType)>()",
            "let actionDispatcher = ActionDispatcher<\(raw: routeType).Action>()",
            "var actionCancellables = Set<AnyCancellable>()",
                """
                init(root: \(raw: routeType)) {
                    self.root = root
                    bindActionDispatcher()
                }
                """
        ]
        
        let deinitDecl = DeclSyntax(stringLiteral:
            """
            deinit {
                // AnyCancellable automatically cancels when deallocated
                #if DEBUG
                    print("🧹 \(routeType) Coordinator deallocated")
                #endif
            }
            """
        )
        
        return memberDecls + [deinitDecl]
    }

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
        case .message(let msg): return msg
        }
    }
}

@main
struct CoordinatorKitPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CoordinatorKit.self
    ]
}


