//
//  CoordinatorView.swift
//  CoordinatorKit
//
//  Created by Vinodhkumar Govindaraj on 02/07/25.
//

import SwiftUI
import CoordinatorKitInterface

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
                RouteViewBuilder(route: route, actionDispatcher: coordinator.actionDispatcher)
            }
#if os(iOS)
            .fullScreenCover(item: $coordinator.fullScreenRoute) { route in
                RouteViewBuilder(route: route, actionDispatcher: coordinator.actionDispatcher)
            }
#endif
        }
    }
}
