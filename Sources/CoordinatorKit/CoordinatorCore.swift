//
//  CoordinatorCore.swift
//  CoordinatorKit
//
//  Created by Vinodhkumar Govindaraj on 02/07/25.
//
import SwiftUI
import Combine
import CoordinatorKitInterface

public enum CoordinatorError: Error {
    case invalidRoute(String)
    case presentationConflict(String)
    case navigationStackOverflow(maxDepth: Int)
    case navigationNotAllowed(String)
}

@MainActor
public extension Coordinator {
    func bindActionDispatcher() {
        guard actionCancellables.isEmpty else { return }
        actionDispatcher.publisher
            .receive(on: RunLoop.main)
            .sink { [weak self] action in
                self?.handle(action)
            }
            .store(in: &actionCancellables)
    }

    func push(_ route: Route) throws {
        guard navigationPath.count < 20 else {
            throw CoordinatorError.navigationStackOverflow(maxDepth: 20)
        }
        navigationPath.append(route)
    }

    func presentSheet(_ route: Route) throws {
        guard sheetRoute == nil && fullScreenRoute == nil else {
            throw CoordinatorError.presentationConflict("Presentation already active")
        }
        sheetRoute = route
    }

    func presentFullScreen(_ route: Route) throws {
        guard fullScreenRoute == nil && sheetRoute == nil else {
            throw CoordinatorError.presentationConflict("Presentation already active")
        }
        fullScreenRoute = route
    }

    func cleanup() {
        actionCancellables.removeAll()
        navigationPath.removeAll()
        sheetRoute = nil
        fullScreenRoute = nil
    }
}

