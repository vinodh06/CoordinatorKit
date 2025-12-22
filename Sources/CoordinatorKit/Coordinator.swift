//
//  CoordinatorCore.swift
//
//  Created by Vinodhkumar Govindaraj on 11/06/25.
//

@_exported import SwiftUI
@preconcurrency @_exported import Combine

import OSLog

// MARK: - Debug Configuration
@MainActor
public struct CoordinatorDebugConfiguration {
    public static var isLoggingEnabled = false
    
    #if DEBUG
    private static let logger = Logger(subsystem: "com.coordinator", category: "navigation")
    #endif
    
    public static func enable() {
        isLoggingEnabled = true
    }
    
    public static func disable() {
        isLoggingEnabled = false
    }
    
    internal static func log(_ message: String, level: OSLogType = .debug) {
        #if DEBUG
        if isLoggingEnabled {
            logger.log(level: level, "\(message)")
        }
        #endif
    }
}

@MainActor
private func debugLog(_ message: String) {
    CoordinatorDebugConfiguration.log(message)
}

// MARK: - NavigationRoute Protocol
public protocol NavigationRoute: Hashable, Identifiable, Sendable {
    associatedtype Destination: View
    associatedtype Action: Sendable
    
    @MainActor
    @ViewBuilder
    func build(actionDispatcher: ActionDispatcher<Action>) -> Destination
}

public extension NavigationRoute {
    var id: Self { self }
}

// MARK: - ActionDispatcher
@MainActor
public final class ActionDispatcher<Action: Sendable> {
    private let subject = PassthroughSubject<Action, Never>()
    private var isFinished = false
    
    public var publisher: AnyPublisher<Action, Never> {
        subject.eraseToAnyPublisher()
    }
    
    public init() {}
    
    public func send(_ action: Action) {
        guard !isFinished else {
            debugLog("⚠️ Attempted to send action after ActionDispatcher was finished")
            return
        }
        subject.send(action)
    }
    
    public func finish() {
        guard !isFinished else { return }
        isFinished = true
        subject.send(completion: .finished)
        debugLog("🏁 ActionDispatcher finished")
    }
    
    deinit {
#if DEBUG
        print("🗑️ ActionDispatcher deallocated")
#endif
    }
}

// MARK: - Presentation State Management
@MainActor
public struct PresentationState<Route: NavigationRoute> {
    private var _sheet: (route: Route, isDismissing: Bool)?
    private var _fullScreen: (route: Route, isDismissing: Bool)?
    
    public var sheetRoute: Route? {
        get { _sheet?.route }
        set {
            if let newValue = newValue {
                debugLog("📄 Sheet route set: \(newValue)")
                _sheet = (newValue, false)
            } else if _sheet != nil {
                debugLog("📄 Sheet route cleared")
                _sheet = nil
            }
        }
    }
    
    public var fullScreenRoute: Route? {
        get { _fullScreen?.route }
        set {
            if let newValue = newValue {
                debugLog("🖥️ Full screen route set: \(newValue)")
                _fullScreen = (newValue, false)
            } else if _fullScreen != nil {
                debugLog("🖥️ Full screen route cleared")
                _fullScreen = nil
            }
        }
    }
    
    public var isSheetDismissing: Bool {
        get { _sheet?.isDismissing ?? false }
        set {
            if let sheet = _sheet {
                _sheet = (sheet.route, newValue)
                debugLog("📄 Sheet dismissing state: \(newValue)")
            }
        }
    }
    
    public var isFullScreenDismissing: Bool {
        get { _fullScreen?.isDismissing ?? false }
        set {
            if let fullScreen = _fullScreen {
                _fullScreen = (fullScreen.route, newValue)
                debugLog("🖥️ Full screen dismissing state: \(newValue)")
            }
        }
    }
    
    public init() {}
    
    public mutating func reset() {
        debugLog("🔄 Presentation state reset")
        _sheet = nil
        _fullScreen = nil
    }
}

// MARK: - Enums
public enum PresentationType: Sendable {
    case sheet
    case fullScreen
}

// MARK: - Coordinator Error
public enum CoordinatorError: Error, LocalizedError, Sendable {
    case navigationStackOverflow(maxDepth: Int)
    case invalidRoute(String)
    case presentationConflict(String)
    case navigationNotAllowed(String)
    case dismissNotAllowed(String)
    case popNotAllowed(String)
    
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
        case .dismissNotAllowed(let message):
            return "Dismiss not allowed: \(message)"
        case .popNotAllowed(let message):
            return "Pop not allowed: \(message)"
        }
    }
}

// MARK: - Core Coordinator Protocol

/// A protocol that defines the core navigation coordination behavior.
///
/// Coordinators manage navigation flow, including push/pop operations,
/// modal presentations (sheets and full-screen covers), and action handling.
///
/// ## Thread Safety
/// All coordinator methods must be called from the main thread.
/// The `@MainActor` isolation ensures thread safety for UI operations.
///
/// ## Debug Logging
/// To enable debug logging, call:
/// ```
/// CoordinatorDebugConfiguration.enable()
/// ```
///
/// ## Usage
/// ```
/// @MainActor
/// final class AppCoordinator: Coordinator {
///     typealias Route = AppRoute
///     typealias Action = AppAction
///
///     @Published var navigationPath: [AppRoute] = []
///     @Published var presentationState = PresentationState<AppRoute>()
///     @Published var root: AppRoute = .home
///     var actionCancellables = Set<AnyCancellable>()
///     let actionDispatcher = ActionDispatcher<AppAction>()
///
///     func handle(_ action: AppAction) {
///         // Handle actions here
///     }
/// }
/// ```
@MainActor
public protocol Coordinator: ObservableObject {
    associatedtype Route: NavigationRoute where Route.Action == Action
    associatedtype Action: Sendable

    var navigationPath: [Route] { get set }
    var presentationState: PresentationState<Route> { get set }
    var actionCancellables: Set<AnyCancellable> { get set }
    var actionDispatcher: ActionDispatcher<Action> { get }
    
    var root: Route { get set }

    /// Handle actions dispatched by views or child coordinators.
    /// Override this method to implement your navigation logic.
    func handle(_ action: Action)
    
    // MARK: - Interactive Handling Methods
    
    /// Called when a sheet is about to be dismissed interactively (swipe down).
    func onInteractiveSheetDismiss()
    
    /// Called when a full-screen cover is about to be dismissed interactively.
    func onInteractiveFullScreenDismiss()
    
    /// Determines if interactive dismissal is allowed for the given presentation type.
    /// Return `false` to prevent swipe-to-dismiss gestures.
    func canInteractiveDismiss(for presentationType: PresentationType) -> Bool
    
    /// Called after interactive dismissal completes.
    func didInteractiveDismiss(for presentationType: PresentationType)
    
    /// Called when a route is about to be popped interactively (swipe back).
    func onInteractiveNavigationPop(from route: Route)
    
    /// Determines if interactive navigation pop is allowed for the given route.
    /// Return `false` to prevent swipe-back gestures.
    func canInteractiveNavigationPop(from route: Route) -> Bool
    
    /// Called after interactive navigation pop completes.
    func didInteractiveNavigationPop(from route: Route)
}

// MARK: - Default Implementation
@MainActor
public extension Coordinator {
    var maxNavigationDepth: Int { 20 }
    
    var sheetRoute: Route? {
        get { presentationState.sheetRoute }
        set { presentationState.sheetRoute = newValue }
    }
    
    var fullScreenRoute: Route? {
        get { presentationState.fullScreenRoute }
        set { presentationState.fullScreenRoute = newValue }
    }
    
    // MARK: - Default Implementations
    func onInteractiveSheetDismiss() {}
    func onInteractiveFullScreenDismiss() {}
    func canInteractiveDismiss(for presentationType: PresentationType) -> Bool { true }
    func didInteractiveDismiss(for presentationType: PresentationType) {}
    func onInteractiveNavigationPop(from route: Route) {}
    func canInteractiveNavigationPop(from route: Route) -> Bool { true }
    func didInteractiveNavigationPop(from route: Route) {}
    
    // MARK: - Interactive Handlers
    
    /// Handles interactive dismissal with proper state management and animation timing.
    ///
    /// The 150ms delay allows SwiftUI's dismissal animation to complete before
    /// clearing the presentation state, preventing visual glitches.
    func handleInteractiveDismiss(for presentationType: PresentationType) {
        guard canInteractiveDismiss(for: presentationType) else {
            debugLog("🚫 Interactive dismiss blocked for \(presentationType)")
            return
        }
        
        debugLog("👆 Interactive dismiss started for \(presentationType)")
        
        switch presentationType {
        case .sheet:
            presentationState.isSheetDismissing = true
            onInteractiveSheetDismiss()
            
            Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(150))
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.presentationState.sheetRoute = nil
                    self.presentationState.isSheetDismissing = false
                    self.didInteractiveDismiss(for: .sheet)
                    debugLog("✅ Sheet dismissed interactively")
                }
            }
            
        case .fullScreen:
            presentationState.isFullScreenDismissing = true
            onInteractiveFullScreenDismiss()
            
            Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(150))
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.presentationState.fullScreenRoute = nil
                    self.presentationState.isFullScreenDismissing = false
                    self.didInteractiveDismiss(for: .fullScreen)
                    debugLog("✅ Full screen dismissed interactively")
                }
            }
        }
    }
    
    func handleInteractiveNavigationPop() {
        guard !navigationPath.isEmpty else { return }
        
        let currentRoute = navigationPath.last!
        guard canInteractiveNavigationPop(from: currentRoute) else {
            debugLog("🚫 Interactive pop blocked for route: \(currentRoute)")
            return
        }
        
        debugLog("👆 Interactive pop started from: \(currentRoute)")
        
        onInteractiveNavigationPop(from: currentRoute)
        navigationPath.removeLast()
        didInteractiveNavigationPop(from: currentRoute)
        
        debugLog(
            "✅ Popped to: \(navigationPath.last.debugDescription ?? "root")"
        )
    }
    
    // MARK: - Navigation Methods
    
    /// Pushes a new route onto the navigation stack.
    /// - Parameter route: The route to push.
    /// - Throws: `CoordinatorError.navigationStackOverflow` if max depth is exceeded,
    ///          or custom validation errors from `validateNavigation`.
    func push(_ route: Route) throws {
        guard navigationPath.count < maxNavigationDepth else {
            debugLog("❌ Navigation stack overflow: \(navigationPath.count)/\(maxNavigationDepth)")
            throw CoordinatorError.navigationStackOverflow(maxDepth: maxNavigationDepth)
        }
        
        guard navigationPath.last != route else {
            debugLog("⚠️ Attempted to push duplicate route: \(route)")
            return
        }
        
        try validateNavigation(to: route, from: navigationPath.last)
        navigationPath.append(route)
        
        debugLog("➡️ Pushed: \(route) | Stack depth: \(navigationPath.count)")
    }
    
    /// Override this method to add custom navigation validation.
    ///
    /// Example usage:
    /// ```
    /// func validateNavigation(to newRoute: Route, from currentRoute: Route?) throws {
    ///     if case .settings = newRoute, !isUserLoggedIn {
    ///         throw CoordinatorError.navigationNotAllowed("User must be logged in")
    ///     }
    /// }
    /// ```
    func validateNavigation(to newRoute: Route, from currentRoute: Route?) throws {
        // Default implementation does nothing
        // Subclasses can override to add specific validation logic
    }
    
    func pop() throws {
        guard !navigationPath.isEmpty else {
            debugLog("❌ Cannot pop from empty navigation stack")
            throw CoordinatorError.popNotAllowed("Cannot pop from empty navigation stack")
        }
        
        let poppedRoute = navigationPath.removeLast()
        
        debugLog("⬅️ Popped: \(poppedRoute) | Stack depth: \(navigationPath.count)")
    }
    
    func popToRoot() {
        let count = navigationPath.count
        navigationPath.removeAll()
        
        debugLog("🏠 Popped to root | Removed \(count) routes")
    }
    
    func popTo(_ route: Route) {
        guard let index = navigationPath.firstIndex(of: route) else {
            debugLog("⚠️ Route not found in stack: \(route)")
            return
        }
        
        let removedCount = navigationPath.count - (index + 1)
        navigationPath = Array(navigationPath.prefix(index + 1))
        
        debugLog("⬅️ Popped to: \(route) | Removed \(removedCount) routes")
    }
    
    // MARK: - Presentation Methods
    
    func presentSheet(_ route: Route) throws {
        guard presentationState.sheetRoute == nil else {
            debugLog("❌ Sheet already presented: \(presentationState.sheetRoute!)")
            throw CoordinatorError.presentationConflict("Sheet already presented")
        }
        guard presentationState.fullScreenRoute == nil else {
            debugLog("❌ Full screen already presented: \(presentationState.fullScreenRoute!)")
            throw CoordinatorError.presentationConflict("Full screen already presented")
        }
        
        presentationState.sheetRoute = route
        
        debugLog("📄 Presenting sheet: \(route)")
    }
    
    func presentFullScreen(_ route: Route) throws {
        guard presentationState.fullScreenRoute == nil else {
            debugLog("❌ Full screen already presented: \(presentationState.fullScreenRoute!)")
            throw CoordinatorError.presentationConflict("Full screen already presented")
        }
        guard presentationState.sheetRoute == nil else {
            debugLog("❌ Sheet already presented: \(presentationState.sheetRoute!)")
            throw CoordinatorError.presentationConflict("Sheet already presented")
        }
        
        presentationState.fullScreenRoute = route
        
        debugLog("🖥️ Presenting full screen: \(route)")
    }
    
    func dismissSheet() {
        if presentationState.sheetRoute != nil {
            debugLog("❌ Dismissing sheet: \(presentationState.sheetRoute!)")
        }
        
        presentationState.sheetRoute = nil
        presentationState.isSheetDismissing = false
    }
    
    func dismissFullScreen() {
        if presentationState.fullScreenRoute != nil {
            debugLog("❌ Dismissing full screen: \(presentationState.fullScreenRoute!)")
        }
        
        presentationState.fullScreenRoute = nil
        presentationState.isFullScreenDismissing = false
    }
    
    func dismissAllPresentations() {
        let hadSheet = presentationState.sheetRoute != nil
        let hadFullScreen = presentationState.fullScreenRoute != nil
        
        dismissSheet()
        dismissFullScreen()
        
        if hadSheet || hadFullScreen {
            debugLog("❌ Dismissed all presentations (sheet: \(hadSheet), fullScreen: \(hadFullScreen))")
        }
    }
    
    // MARK: - Safe Methods
    
    /// Attempts to push a route without throwing errors.
    /// - Parameters:
    ///   - route: The route to push.
    ///   - onError: Optional closure called with the error if push fails.
    /// - Returns: `true` if successful, `false` otherwise.
    @discardableResult
    func tryPush(_ route: Route, onError: ((CoordinatorError) -> Void)? = nil) -> Bool {
        do {
            try push(route)
            return true
        } catch let error as CoordinatorError {
            onError?(error)
            debugLog("⚠️ Navigation failed: \(error.localizedDescription)")
            return false
        } catch {
            return false
        }
    }
    
    @discardableResult
    func tryPresentSheet(_ route: Route, onError: ((CoordinatorError) -> Void)? = nil) -> Bool {
        do {
            try presentSheet(route)
            return true
        } catch let error as CoordinatorError {
            onError?(error)
            debugLog("⚠️ Sheet presentation failed: \(error.localizedDescription)")
            return false
        } catch {
            return false
        }
    }
    
    @discardableResult
    func tryPresentFullScreen(_ route: Route, onError: ((CoordinatorError) -> Void)? = nil) -> Bool {
        do {
            try presentFullScreen(route)
            return true
        } catch let error as CoordinatorError {
            onError?(error)
            debugLog("⚠️ Full screen presentation failed: \(error.localizedDescription)")
            return false
        } catch {
            return false
        }
    }

    /// Sets a new root route and optionally clears the navigation stack.
    /// - Parameters:
    ///   - route: The new root route.
    ///   - clearNavigationStack: If `true`, clears all navigation and presentations.
    func setRoot(_ route: Route, clearNavigationStack: Bool = true) {
        guard root != route || clearNavigationStack else {
            debugLog("⚠️ Root unchanged: \(route)")
            return
        }
        
        debugLog("🏠 Setting root: \(route) (clear stack: \(clearNavigationStack))")
        
        // Clear presentations before changing root for smoother UX
        if clearNavigationStack {
            dismissAllPresentations()
            navigationPath.removeAll()
        }
        
        root = route
    }
    
    /// Navigates to a specific path, clearing all presentations.
    /// Useful for deep linking scenarios.
    /// - Parameters:
    ///   - path: The navigation path to set.
    ///   - animated: Whether to animate the transition (currently unused, for future API compatibility).
    func navigate(to path: [Route], animated: Bool = true) {
        debugLog("🔗 Deep link navigation to path: \(path.map { "\($0)" })")
        
        dismissAllPresentations()
        navigationPath = path
    }
    
    func cleanup() {
        debugLog("🧹 Coordinator cleanup started: \(type(of: self))")
        
        actionDispatcher.finish()
        actionCancellables.removeAll()
        navigationPath.removeAll()
        presentationState.reset()
        
        debugLog("🧹 Coordinator cleaned up: \(type(of: self))")
    }
    
    func bindActionDispatcher() {
        guard actionCancellables.isEmpty else {
            debugLog("⚠️ ActionDispatcher already bound")
            return
        }
        
        debugLog("🔗 Binding ActionDispatcher")
        
        actionDispatcher.publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] action in
                guard let self = self else { return }
                self.handle(action)
            }
            .store(in: &actionCancellables)
    }
    
    func enableDebugLogging() {
        actionDispatcher.publisher
            .sink { action in
                debugLog("🎯 Coordinator Action: \(action)")
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
    @State private var isHandlingNavigation = false
    @State private var hasInitialized = false

    public init(coordinator: C) {
        _coordinator = StateObject(wrappedValue: coordinator)
    }

    public var body: some View {
        NavigationStack(path: createNavigationBinding()) {
            RouteViewBuilder(
                route: coordinator.root,
                actionDispatcher: coordinator.actionDispatcher
            )
            .id(coordinator.root.id)
            .navigationDestination(for: C.Route.self) { route in
                RouteViewBuilder(
                    route: route,
                    actionDispatcher: coordinator.actionDispatcher
                )
            }
            .sheet(item: createSheetBinding()) { route in
                RouteViewBuilder(
                    route: route,
                    actionDispatcher: coordinator.actionDispatcher
                )
            }
            .fullScreenCover(item: createFullScreenBinding()) { route in
                RouteViewBuilder(
                    route: route,
                    actionDispatcher: coordinator.actionDispatcher
                )
            }
        }
        .onAppear {
            if !hasInitialized {
                debugLog("🚀 CoordinatorView initialized")
                coordinator.bindActionDispatcher()
                hasInitialized = true
            }
        }
    }
    
    @MainActor
    private func createNavigationBinding() -> Binding<[C.Route]> {
        Binding(
            get: { coordinator.navigationPath },
            set: { newPath in
                guard !isHandlingNavigation else { return }
                
                if newPath.count < coordinator.navigationPath.count {
                    guard !coordinator.navigationPath.isEmpty else {
                        coordinator.navigationPath = newPath
                        return
                    }
                    
                    let currentRoute = coordinator.navigationPath.last!
                    
                    if coordinator.canInteractiveNavigationPop(from: currentRoute) {
                        coordinator.handleInteractiveNavigationPop()
                    } else {
                        isHandlingNavigation = true
                        
                        debugLog("🚫 Preventing navigation pop for route: \(currentRoute)")
                        
                        // Use animation completion instead of arbitrary delay
                        withAnimation {
                            coordinator.navigationPath = coordinator.navigationPath
                        }
                        
                        Task {
                            await MainActor.run {
                                self.isHandlingNavigation = false
                            }
                        }
                    }
                } else {
                    coordinator.navigationPath = newPath
                }
            }
        )
    }
    
    @MainActor
    private func createSheetBinding() -> Binding<C.Route?> {
        Binding(
            get: { coordinator.presentationState.sheetRoute },
            set: { newValue in
                if newValue == nil &&
                   coordinator.presentationState.sheetRoute != nil &&
                   !coordinator.presentationState.isSheetDismissing {
                    
                    if coordinator.canInteractiveDismiss(for: .sheet) {
                        coordinator.handleInteractiveDismiss(for: .sheet)
                    } else {
                        debugLog("🚫 Sheet dismiss prevented")
                        return
                    }
                } else if newValue != nil {
                    coordinator.presentationState.sheetRoute = newValue
                    coordinator.presentationState.isSheetDismissing = false
                }
            }
        )
    }
    
    @MainActor
    private func createFullScreenBinding() -> Binding<C.Route?> {
        Binding(
            get: { coordinator.presentationState.fullScreenRoute },
            set: { newValue in
                if newValue == nil &&
                   coordinator.presentationState.fullScreenRoute != nil &&
                   !coordinator.presentationState.isFullScreenDismissing {
                    
                    if coordinator.canInteractiveDismiss(for: .fullScreen) {
                        coordinator.handleInteractiveDismiss(for: .fullScreen)
                    } else {
                        debugLog("🚫 Full screen dismiss prevented")
                        return
                    }
                } else if newValue != nil {
                    coordinator.presentationState.fullScreenRoute = newValue
                    coordinator.presentationState.isFullScreenDismissing = false
                }
            }
        )
    }
}

