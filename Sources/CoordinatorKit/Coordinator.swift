//
//  CoordinatorCore.swift
//
//  Created by Vinodhkumar Govindaraj on 11/06/25.
//

@_exported import SwiftUI
@_exported import Combine

// MARK: - NavigationRoute Protocol
public protocol NavigationRoute: Hashable, Identifiable {
    associatedtype Destination: View
    associatedtype Action
    
    @MainActor
    @ViewBuilder
    func build(actionDispatcher: ActionDispatcher<Action>) -> Destination
}

public extension NavigationRoute {
    var id: Self { self }
}

// MARK: - ActionDispatcher
public final class ActionDispatcher<Action>: ObservableObject {
    let subject = PassthroughSubject<Action, Never>()

    var publisher: AnyPublisher<Action, Never> {
        subject.eraseToAnyPublisher()
    }

    public init() {}

    public func send(_ action: Action) {
        subject.send(action)
    }
}

// MARK: - Coordinator Protocol
@MainActor
public protocol Coordinator: ObservableObject {
    associatedtype Route: NavigationRoute where Route.Action == Action
    associatedtype Action

    var navigationPath: [Route] { get set }
    var sheetRoute: Route? { get set }
    var fullScreenRoute: Route? { get set }
  
    var actionCancellables: Set<AnyCancellable> { get set }
    var actionDispatcher: ActionDispatcher<Action> { get }

    @MainActor
    func handle(_ action: Action)
}

public enum CoordinatorError: Error, LocalizedError {
    case navigationStackOverflow(maxDepth: Int)
    case invalidRoute(String)
    case presentationConflict(String)
    case navigationNotAllowed(String)
    
    public var errorDescription: String? {
        switch self {
        case .navigationStackOverflow(let maxDepth):
            return "Navigation stack exceeded maximum depth of \(maxDepth)"
        case .invalidRoute(let message):
            return "Invalid route: \(message)"
        case .presentationConflict(let message):
            return "Presentation conflict: \(message)"
        case .navigationNotAllowed(let message):
            return "Navigation not allowed: \(message)"
        }
    }
}

// MARK: - Coordinator Default Implementation
@MainActor
public extension Coordinator {
    var maxNavigationDepth: Int { 20 } // Override in subclasses if needed
    
    func push(_ route: Route) throws {
        // Validate stack depth
        guard navigationPath.count < maxNavigationDepth else {
            throw CoordinatorError.navigationStackOverflow(maxDepth: maxNavigationDepth)
        }
        
        // Prevent duplicate consecutive routes
        guard navigationPath.last != route else {
#if DEBUG
            print("🔄 Ignoring duplicate route: \(route)")
#endif
            return
        }
        
        // Custom validation (override in subclasses)
        try validateNavigation(to: route, from: navigationPath.last)
        
        navigationPath.append(route)
        
#if DEBUG
        print("➡️ Pushed route: \(route), stack depth: \(navigationPath.count)")
#endif
    }
    
    /// Override this method to add custom navigation validation
    func validateNavigation(to newRoute: Route, from currentRoute: Route?) throws {
        // Default implementation does nothing
        // Subclasses can override to add specific validation logic
    }
    
    func pop() throws {
        guard !navigationPath.isEmpty else {
            throw CoordinatorError.navigationNotAllowed("Cannot pop from empty navigation stack")
        }
        
        let poppedRoute = navigationPath.removeLast()
        
#if DEBUG
        print("⬅️ Popped route: \(poppedRoute), remaining depth: \(navigationPath.count)")
#endif
    }

    func presentSheet(_ route: Route) throws {
        guard sheetRoute == nil else {
            throw CoordinatorError.presentationConflict("Sheet already presented: \(sheetRoute!)")
        }
        guard fullScreenRoute == nil else {
            throw CoordinatorError.presentationConflict("Full screen already presented: \(fullScreenRoute!)")
        }
        
        sheetRoute = route
        
#if DEBUG
        print("Presenting sheet: \(route)")
#endif
    }
    
    func presentFullScreen(_ route: Route) throws {
        guard fullScreenRoute == nil else {
            throw CoordinatorError.presentationConflict("Full screen already presented: \(fullScreenRoute!)")
        }
        guard sheetRoute == nil else {
            throw CoordinatorError.presentationConflict("Sheet already presented: \(sheetRoute!)")
        }
        
        fullScreenRoute = route
        
#if DEBUG
        print("Presenting full screen: \(route)")
#endif
    }
    
    /// Safe presentation that returns success/failure
    func tryPresentSheet(_ route: Route) -> Bool {
        do {
            try presentSheet(route)
            return true
        } catch {
#if DEBUG
            print("Failed to present sheet: \(error)")
#endif
            return false
        }
    }
    
    /// Safe presentation that returns success/failure
    func tryPresentFullScreen(_ route: Route) -> Bool {
        do {
            try presentFullScreen(route)
            return true
        } catch {
#if DEBUG
            print("Failed to present sheet: \(error)")
#endif
            return false
        }
    }

    func dismissSheet() {
        sheetRoute = nil
    }

    func dismissFullScreen() {
        fullScreenRoute = nil
    }

    func start(initialRoute: Route) {
        if navigationPath.isEmpty {
            try? push(initialRoute)
        }
    }
    
    func popToRoot() {
        if let first = navigationPath.first {
            navigationPath = [first]
        }
    }
  
    func bindActionDispatcher() {
        guard actionCancellables.isEmpty else { return }
        actionDispatcher.publisher
            .receive(on: RunLoop.main)
            .sink { [weak self] action in
                guard let self else {
#if DEBUG
                    print("Coordinator deallocated while handling action: \(action)")
#endif
                    return
                }
                self.handle(action)
            }
            .store(in: &actionCancellables)
    }
}

public extension Coordinator {
    func cleanup() {
        actionCancellables.removeAll()
        navigationPath.removeAll()
        sheetRoute = nil
        fullScreenRoute = nil
#if DEBUG
        print("Coordinator cleaned up: \(type(of: self))")
#endif
    }
    
    func enableDebugLogging() {
        actionDispatcher.publisher
            .sink { action in
                print("Coordinator Action: \(action)")
            }
            .store(in: &actionCancellables)
    }
}

// MARK: - RouteViewBuilder
public struct RouteViewBuilder<Route: NavigationRoute>: View {
    public let route: Route
    public let actionDispatcher: ActionDispatcher<Route.Action>

    public init(route: Route, actionDispatcher: ActionDispatcher<Route.Action>) {
        self.route = route
        self.actionDispatcher = actionDispatcher
    }

    public var body: some View {
        route.build(actionDispatcher: actionDispatcher)
    }
}

// MARK: - CoordinatorView
public struct CoordinatorView<C: Coordinator>: View {
    @StateObject public var coordinator: C
    public let initialRoute: C.Route

    public init(coordinator: C, initialRoute: C.Route) {
        _coordinator = StateObject(wrappedValue: coordinator)
        self.initialRoute = initialRoute
        coordinator.bindActionDispatcher()
    }

    public var body: some View {
        NavigationStack(path: Binding(
            get: { coordinator.navigationPath },
            set: { coordinator.navigationPath = $0 }
        )) {
            RouteViewBuilder(
                route: initialRoute,
                actionDispatcher: coordinator.actionDispatcher
            )
            .navigationDestination(for: C.Route.self) { route in
                RouteViewBuilder(
                    route: route,
                    actionDispatcher: coordinator.actionDispatcher
                )
            }
            .sheet(item: $coordinator.sheetRoute) { route in
                RouteViewBuilder(
                    route: route,
                    actionDispatcher: coordinator.actionDispatcher
                )
            }
#if os(iOS)
            .fullScreenCover(item: $coordinator.fullScreenRoute) { route in
                RouteViewBuilder(
                    route: route,
                    actionDispatcher: coordinator.actionDispatcher
                )
            }
#endif
        }
        .background(Color.clear)
    }
}

