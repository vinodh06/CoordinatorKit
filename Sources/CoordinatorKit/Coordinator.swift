//
//  CoordinatorCore.swift
//
//  Created by Vinodhkumar Govindaraj on 11/06/25.
//
/*
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

*/
