import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(CoordinatorKitMacros)
import CoordinatorKitMacros

let testMacros: [String: Macro.Type] = [
    "Coordinator": CoordinatorKit.self,
]
#endif

final class CoordinatorKitTests: XCTestCase {
    
    func testCoordinatorMacroExpansion() throws {
#if canImport(CoordinatorKitMacros)
        assertMacroExpansion(
            """
            @Coordinator(MyRoute)
            class MyCoordinator { }
            """,
            expandedSource: """
            class MyCoordinator { 

                @Published internal var navigationPath: [MyRoute] = []

                @Published internal var sheetRoute: MyRoute?

                @Published internal var fullScreenRoute: MyRoute?

                let actionDispatcher = ActionDispatcher<MyRoute.Action>()

                var actionCancellables = Set<AnyCancellable>()

                deinit {
                    Task { @MainActor in
                        cleanup()
                    }
                }
            }

            @MainActor extension MyCoordinator: Coordinator {
            }
            """,
            macros: testMacros
        )

#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }
    
    func testMissingRouteArgumentThrowsError() throws {
#if canImport(CoordinatorKitMacros)
        assertMacroExpansion(
            """
            @Coordinator
            class InvalidCoordinator { }
            """,
            expandedSource: """
            class InvalidCoordinator { }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Coordinator macro requires a type NavigationRoute",
                    line: 1,
                    column: 1
                )
                
            ],
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }
}

