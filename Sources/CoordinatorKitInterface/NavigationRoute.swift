//
//  NavigationRoute.swift
//  CoordinatorKit
//
//  Created by Vinodhkumar Govindaraj on 02/07/25.
//


import SwiftUI
import Combine

public protocol NavigationRoute: Hashable, Identifiable {
    associatedtype Destination: View
    associatedtype Action

    @ViewBuilder
    func build(actionDispatcher: ActionDispatcher<Action>) -> Destination
}

public extension NavigationRoute {
    var id: Self { self }
}
