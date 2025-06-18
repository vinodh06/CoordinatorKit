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

// MARK: - Coordinator Default Implementation
@MainActor
public extension Coordinator {
    func push(_ route: Route) {
        guard navigationPath.last != route else { return }
        navigationPath.append(route)
    }
    
    func pop() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }

    func presentSheet(_ route: Route) {
        sheetRoute = route
    }

    func dismissSheet() {
        sheetRoute = nil
    }

    func presentFullScreen(_ route: Route) {
        fullScreenRoute = route
    }

    func dismissFullScreen() {
        fullScreenRoute = nil
    }

    func start(initialRoute: Route) {
        if navigationPath.isEmpty {
            push(initialRoute)
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
                self?.handle(action)
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
            .fullScreenCover(item: $coordinator.fullScreenRoute) { route in
                RouteViewBuilder(
                    route: route,
                    actionDispatcher: coordinator.actionDispatcher
                )
            }
        }
    }
}
