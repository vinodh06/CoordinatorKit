```markdown
# CoordinatorKit

A powerful and type-safe SwiftUI coordinator framework built for Swift 6 concurrency. Enables structured navigation using `NavigationStack`, `sheet`, and `fullScreenCover` with interactive gesture control, robust state management, and macro-based boilerplate reduction.

> ✅ Supports: Navigation Stack • Sheets • Full-Screen Covers • Interactive Dismissal Control<br>
> 🧠 Swift 6 Ready • @MainActor Isolated • Sendable-Safe<br>
> 🧩 Modular • Testable • Scalable<br>
> 🔍 OSLog-based Debug Logging<br>
> ⚡ Swift Macro Support for Zero Boilerplate

---

## 📖 Table of Contents

* [✨ Features](#-features)
* [📦 Installation](#-installation)
* [🧭 What is CoordinatorKit?](#-what-is-coordinatorkit)
* [🧱 Core Concepts](#-core-concepts)
* [🧪 Example Usage](#-example-usage)
* [⚡ Using the @Coordinator Macro](#-using-the-coordinator-macro)
* [🎯 Interactive Gesture Control](#-interactive-gesture-control)
* [🛠️ Customizing Navigation Validation](#️-customizing-navigation-validation)
* [🔗 Deep Linking](#-deep-linking)
* [🧼 Cleanup](#-cleanup)
* [🐞 Debug Logging](#-debug-logging)
* [📚 Advanced Notes](#-advanced-notes)
* [🧪 Testing](#-testing)
* [🛠 Requirements](#-requirements)
* [🙌 Contributing](#-contributing)
* [🔗 Links](#-links)

---

## ✨ Features

* ✅ **Swift 6 Concurrency** — Full `@MainActor` isolation and `Sendable` conformance for thread safety
* ⚡ **Swift Macro Support** — Zero boilerplate with `@Coordinator` macro
* 🎮 **Interactive Gesture Control** — Prevent or allow swipe-back and swipe-to-dismiss gestures
* 🧭 **Type-safe routing** — Routes are enums conforming to `NavigationRoute` protocol
* 🏠 **Root-aware navigation** — Simplified initialization with explicit root route
* 📱 **SwiftUI-first** — Built for `NavigationStack`, `.sheet`, and `.fullScreenCover`
* 🔍 **OSLog Integration** — Performance-optimized debug logging with enable/disable control
* 🧼 **Robust State Management** — `PresentationState` prevents animation glitches and race conditions
* 📦 **Composable & scalable** — Perfect for modular or feature-based apps
* 🧪 **ActionDispatcher** — Enables unidirectional data flow with proper cleanup
* 🔗 **Deep Linking** — Built-in support for navigation to specific paths

---

## 📦 Installation

### Swift Package Manager (SPM)

1. Open your Xcode project
2. Go to **File > Add Packages…**
3. Use the following URL: https://github.com/vinodh06/CoordinatorKit
4. Select CoordinatorKit and add it to your project target.

> **Note**: The macro requires **Swift 5.9+** and **Xcode 15.3+**

---

## 🧭 What is CoordinatorKit?

CoordinatorKit helps manage SwiftUI navigation in a scalable, testable, and type-safe way with full Swift 6 concurrency support.

It decouples navigation logic from your views by:

* Using **typed routes** via `NavigationRoute` with `Sendable` conformance
* Centralizing **side effects and navigation triggers** using `ActionDispatcher`
* Preventing modal presentation conflicts through **built-in error safety**
* Providing **interactive gesture control** for sheets, full-screen covers, and navigation pops
* Managing **root route** directly in the coordinator for simplified initialization
* **Eliminating boilerplate** with the `@Coordinator` macro

---

## 🧱 Core Concepts

### 1. `NavigationRoute`

A protocol that defines your app's routes. Each route builds its own destination `View` and must conform to `Sendable` for Swift 6 compatibility.

enum HomeRoute: NavigationRoute {
    case demo
    case screen2
    case details(id: String)

    enum Action: Sendable {
        case gotoScreen2
        case openDetails(id: String)
    }

    @MainActor
    func build(actionDispatcher: ActionDispatcher<Action>) -> some View {
        switch self {
        case .demo:
            VStack {
                Text("Demo Screen")
                Button {
                    actionDispatcher.send(.gotoScreen2)
                } label: {
                    Text("Go to Screen 2")
                }
            }
            
        case .screen2:
            Text("Screen 2")
            
        case .details(let id):
            DetailsView(id: id)
        }
    }
}

Requirements:

* Conform to `Hashable`, `Identifiable`, and `Sendable`
* Define a `Sendable` associated `Action` type
* Implement `@MainActor` `build()` method that returns a SwiftUI `View`

---

### 2. `Coordinator` (Manual Implementation)

You can define your coordinator manually by conforming to the `Coordinator` protocol:

@MainActor
final class HomeCoordinator: Coordinator {
    typealias Route = HomeRoute
    typealias Action = HomeRoute.Action
    
    @Published var navigationPath: [HomeRoute] = []
    @Published var presentationState = PresentationState<HomeRoute>()
    @Published var root: HomeRoute
    
    var actionCancellables = Set<AnyCancellable>()
    let actionDispatcher = ActionDispatcher<Action>()
    
    init(root: HomeRoute) {
        self.root = root
        bindActionDispatcher()
    }
    
    func handle(_ action: Action) {
        switch action {
        case .gotoScreen2:
            try? push(.screen2)
        case .openDetails(let id):
            try? push(.details(id: id))
        }
    }
    
    deinit {
        #if DEBUG
        print("🧹 HomeCoordinator deallocated")
        #endif
    }
}

---

### 3. `CoordinatorView`

Wrap your coordinator in `CoordinatorView` to start navigation.

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            CoordinatorView(coordinator: HomeCoordinator(root: .demo))
        }
    }
}

---

## ⚡ Using the @Coordinator Macro

The `@Coordinator` macro **eliminates all boilerplate** by automatically generating:

* `@Published` properties for `navigationPath`, `presentationState`, and `root`
* `ActionDispatcher` instance
* `AnyCancellable` set for subscriptions
* `init(root:)` initializer with automatic `bindActionDispatcher()` call
* `deinit` with debug logging
* `Coordinator` protocol conformance via extension

### Macro Usage

import CoordinatorKit

@Coordinator(HomeRoute.self)
class HomeCoordinator {
    @MainActor
    func handle(_ action: HomeRoute.Action) {
        switch action {
        case .gotoScreen2:
            try? push(.screen2)
        case .openDetails(let id):
            try? push(.details(id: id))
        }
    }
}

### What the Macro Generates

The macro expands to:

class HomeCoordinator {
    @Published var root: HomeRoute
    @Published var navigationPath: [HomeRoute] = []
    @Published var presentationState = PresentationState<HomeRoute>()
    let actionDispatcher = ActionDispatcher<HomeRoute.Action>()
    var actionCancellables = Set<AnyCancellable>()
    
    init(root: HomeRoute) {
        self.root = root
        bindActionDispatcher()
    }
    
    deinit {
        #if DEBUG
        print("🧹 HomeRoute Coordinator deallocated")
        #endif
    }
    
    @MainActor
    func handle(_ action: HomeRoute.Action) {
        switch action {
        case .gotoScreen2:
            try? push(.screen2)
        case .openDetails(let id):
            try? push(.details(id: id))
        }
    }
}

@MainActor extension HomeCoordinator: Coordinator {}

### Benefits

* ✅ **Zero boilerplate** — Focus only on your navigation logic
* ✅ **Type-safe** — Compiler ensures correct route type
* ✅ **Consistent** — All coordinators follow the same pattern
* ✅ **Testable** — Generated code is fully testable
* ✅ **Debuggable** — Automatic deallocation logging

---

## 🧪 Example Usage

### Complete Example with Macro

import SwiftUI
import CoordinatorKit

// 1. Define your routes
enum AppRoute: NavigationRoute {
    case home
    case profile
    case settings

    enum Action: Sendable {
        case openProfile
        case openSettings
        case logout
    }

    @MainActor
    func build(actionDispatcher: ActionDispatcher<Action>) -> some View {
        switch self {
        case .home:
            HomeScreen()
                .toolbar {
                    Button("Profile") {
                        actionDispatcher.send(.openProfile)
                    }
                }
        case .profile:
            ProfileScreen()
        case .settings:
            SettingsScreen()
        }
    }
}

// 2. Create coordinator with macro (no boilerplate!)
@Coordinator(AppRoute.self)
class AppCoordinator {
    @MainActor
    func handle(_ action: AppRoute.Action) {
        switch action {
        case .openProfile:
            try? push(.profile)
        case .openSettings:
            try? presentSheet(.settings)
        case .logout:
            setRoot(.home, clearNavigationStack: true)
        }
    }
}

// 3. Wire it into your app
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            CoordinatorView(coordinator: AppCoordinator(root: .home))
        }
    }
}

### Manual Implementation (Without Macro)

If you prefer not to use macros or need more control:

@MainActor
final class AppCoordinator: Coordinator {
    typealias Route = AppRoute
    typealias Action = AppRoute.Action
    
    @Published var navigationPath: [AppRoute] = []
    @Published var presentationState = PresentationState<AppRoute>()
    @Published var root: AppRoute
    
    var actionCancellables = Set<AnyCancellable>()
    let actionDispatcher = ActionDispatcher<Action>()
    
    init(root: AppRoute) {
        self.root = root
        bindActionDispatcher()
    }
    
    func handle(_ action: Action) {
        switch action {
        case .openProfile:
            try? push(.profile)
        case .openSettings:
            try? presentSheet(.settings)
        case .logout:
            setRoot(.home, clearNavigationStack: true)
        }
    }
}

---

## 🎯 Interactive Gesture Control

CoordinatorKit provides fine-grained control over interactive gestures like swipe-back and swipe-to-dismiss.

### Preventing Swipe-to-Dismiss on Sheets

@Coordinator(AppRoute.self)
class AppCoordinator {
    @Published var hasUnsavedChanges = false
    
    func canInteractiveDismiss(for presentationType: PresentationType) -> Bool {
        switch presentationType {
        case .sheet:
            // Prevent dismissing unsaved form
            return !hasUnsavedChanges
        case .fullScreen:
            return true
        }
    }
    
    func onInteractiveSheetDismiss() {
        // Show confirmation alert
        showUnsavedChangesAlert = true
    }
    
    @MainActor
    func handle(_ action: AppRoute.Action) {
        // Your navigation logic
    }
}

### Preventing Swipe-Back Navigation

@Coordinator(AppRoute.self)
class AppCoordinator {
    func canInteractiveNavigationPop(from route: AppRoute) -> Bool {
        if case .checkout = route {
            // Prevent back navigation from checkout
            return false
        }
        return true
    }
    
    func onInteractiveNavigationPop(from route: AppRoute) {
        // Log analytics or clean up
        print("User swiped back from: \(route)")
    }
    
    func didInteractiveNavigationPop(from route: AppRoute) {
        // Post-pop cleanup
    }
    
    @MainActor
    func handle(_ action: AppRoute.Action) {
        // Your navigation logic
    }
}

---

## 🛠️ Customizing Navigation Validation

Block or validate transitions by overriding `validateNavigation(to:from:)`:

@Coordinator(AppRoute.self)
class AppCoordinator {
    @Published var isUserLoggedIn = false
    
    func validateNavigation(to newRoute: AppRoute, from currentRoute: AppRoute?) throws {
        // Require login before accessing settings
        if case .settings = newRoute, !isUserLoggedIn {
            throw CoordinatorError.navigationNotAllowed("User must be logged in")
        }
        
        // Prevent duplicate navigation
        if currentRoute == newRoute {
            throw CoordinatorError.navigationNotAllowed("Already at this route")
        }
    }
    
    @MainActor
    func handle(_ action: AppRoute.Action) {
        // Your navigation logic
    }
}

---

## 🔗 Deep Linking

Navigate to specific paths programmatically:

// Deep link to a specific screen
coordinator.navigate(to: [.home, .profile, .settings])

// Change root and clear stack
coordinator.setRoot(.onboarding, clearNavigationStack: true)

---

## 🧼 Cleanup

Manually reset navigation stack, presentations, and subscriptions:

coordinator.cleanup()

This is automatically called when the coordinator is deallocated.

---

## 🐞 Debug Logging

CoordinatorKit uses `OSLog` for performance-optimized, non-blocking debug logging.

### Enable Logging

// In your App init
@main
struct MyApp: App {
    init() {
        CoordinatorDebugConfiguration.enable()
    }
    
    var body: some Scene {
        WindowGroup {
            CoordinatorView(coordinator: AppCoordinator(root: .home))
        }
    }
}

### Disable Logging

CoordinatorDebugConfiguration.disable()

### Log Output

When enabled, you'll see:

🚀 CoordinatorView initialized
🔗 Binding ActionDispatcher
➡️ Pushed: details | Stack depth: 1
📄 Presenting sheet: settings
👆 Interactive dismiss started for sheet
✅ Sheet dismissed interactively
⬅️ Popped: details | Stack depth: 0
🧹 HomeRoute Coordinator deallocated

View logs in:
- Xcode Console
- Console.app (filter by subsystem: `com.coordinator`)
- Instruments

---

## 📚 Advanced Notes

### Swift 6 Concurrency

* All coordinator operations are `@MainActor` isolated
* Routes and Actions must conform to `Sendable`
* `ActionDispatcher` uses `@MainActor` for thread safety
* No data races possible with proper usage

### Memory Management

* All closures use `[weak self]` to prevent retain cycles
* `ActionDispatcher` properly finishes on cleanup
* Automatic subscription cleanup on `deinit`
* Macro-generated `deinit` includes debug logging

### Presentation State

The `PresentationState` struct manages:
- Sheet route and dismissing state
- Full-screen route and dismissing state
- 150ms animation delay for smooth transitions

### Navigation Stack Management

* Maximum depth of 20 (customizable via `maxNavigationDepth`)
* Duplicate route prevention
* Safe methods: `tryPush`, `tryPresentSheet`, `tryPresentFullScreen`
* Error callbacks for custom handling

### Macro Requirements

* Swift 5.9+ (for macro support)
* Xcode 15.3+
* macOS 13.3+ (for macro compilation)

---

## 🧪 Testing

All components are testable in isolation:

@MainActor
func testNavigationFlow() async {
    let coordinator = AppCoordinator(root: .home)
    
    // Test push
    coordinator.handle(.openProfile)
    XCTAssertEqual(coordinator.navigationPath.count, 1)
    XCTAssertEqual(coordinator.navigationPath.last, .profile)
    
    // Test sheet presentation
    coordinator.handle(.openSettings)
    XCTAssertEqual(coordinator.presentationState.sheetRoute, .settings)
    
    // Test cleanup
    coordinator.cleanup()
    XCTAssertTrue(coordinator.navigationPath.isEmpty)
    XCTAssertNil(coordinator.presentationState.sheetRoute)
}

---

## 🛠 Requirements

* **Swift 6.0+**
* **Xcode 16.0+** (15.3+ for macro support)
* **iOS 17+, macOS 14+, watchOS 10+, tvOS 17+**
* Swift Concurrency support
* SwiftUI 5.0+

---

## 🙌 Contributing

Contributions and feedback are welcome!
If you spot an issue or have an idea, feel free to [open an issue](https://github.com/vinodh06/CoordinatorKit/issues) or submit a PR.

---

## 🔗 Links

* [CoordinatorKit on GitHub](https://github.com/vinodh06/CoordinatorKit)
* [Swift 6 Concurrency Documentation](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
* [Swift Macros Documentation](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/macros/)

---
```
