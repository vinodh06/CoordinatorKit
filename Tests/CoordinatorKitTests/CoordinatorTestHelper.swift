//
//  CoordinatorTesting.swift
//  CoordinatorKit
//
//  Created by Vinodhkumar Govindaraj on 01/07/25.
//

import Foundation
import Combine
import SwiftUI
@testable import CoordinatorKit
import CoordinatorKitMacros

public protocol CoordinatorTesting {
    associatedtype Route: NavigationRoute
    associatedtype Action
    
    var currentRoute: Route? { get }
    var navigationHistory: [Route] { get }
    var presentedSheet: Route? { get }
    var presentedFullScreen: Route? { get }
    
    func simulateAction(_ action: Action)
    func simulateDeepLink(_ url: URL) throws
    func getNavigationState() -> NavigationState<Route>
}

public struct NavigationState<Route: NavigationRoute>: Equatable {
    public let navigationPath: [Route]
    public let sheetRoute: Route?
    public let fullScreenRoute: Route?
    public let timestamp: Date
    
    public init(navigationPath: [Route], sheetRoute: Route?, fullScreenRoute: Route?) {
        self.navigationPath = navigationPath
        self.sheetRoute = sheetRoute
        self.fullScreenRoute = fullScreenRoute
        self.timestamp = Date()
    }
}

public extension Coordinator {
    var currentRoute: Route? {
        navigationPath.last
    }
    
    var navigationHistory: [Route] {
        navigationPath
    }
    
    var presentedSheet: Route? {
        sheetRoute
    }
    
    var presentedFullScreen: Route? {
        fullScreenRoute
    }
    
    func getNavigationState() -> NavigationState<Route> {
        NavigationState(
            navigationPath: navigationPath,
            sheetRoute: sheetRoute,
            fullScreenRoute: fullScreenRoute
        )
    }
    
    func simulateAction(_ action: Action) {
        handle(action)
    }
}

//// Mock coordinator for testing
//public class MockCoordinator<R: NavigationRoute, A>: ObservableObject, Coordinator, @preconcurrency CoordinatorTesting where A == R.Action {
//    public typealias Route = R
//    public typealias Action = A
//    
//    @Published public var navigationPath: [R] = []
//    @Published public var sheetRoute: R?
//    @Published public var fullScreenRoute: R?
//    
//    public var actionCancellables: Set<AnyCancellable> = []
//    public let actionDispatcher = ActionDispatcher<A>()
//    
//    public var handledActions: [A] = []
//    public var navigationStates: [NavigationState<R>] = []
//    
//    public init() {
//        bindActionDispatcher()
//    }
//    
//    public func handle(_ action: A) {
//        handledActions.append(action)
//        // Override in tests to add specific behavior
//    }
//    
//    public func simulateDeepLink(_ url: URL) throws {
//        // Override to implement deep link simulation
//        throw CoordinatorError.invalidRoute("Deep link simulation not implemented")
//    }
//    
//    // Test helpers
//    public func captureNavigationState() {
//        navigationStates.append(getNavigationState())
//    }
//    
//    public func resetTestState() {
//        handledActions.removeAll()
//        navigationStates.removeAll()
//        navigationPath.removeAll()
//        sheetRoute = nil
//        fullScreenRoute = nil
//    }
//}
