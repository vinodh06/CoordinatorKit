# CoordinatorKit

A powerful and lightweight SwiftUI coordinator framework that enables structured, type-safe navigation using `NavigationStack`, `sheet`, and `fullScreenCover`. Built with modern Swift, Combine, and macro-based boilerplate reduction.

> ✅ Supports: Navigation Stack • Sheets • Full-Screen Covers<br>
> 🧠 Inspired by TCA (The Composable Architecture)<br>
> 🧩 Modular • Testable • Scalable<br>
> 🧵 Built for Swift Concurrency

---

## 📖 Table of Contents

* [✨ Features](#-features)
* [📦 Installation](#-installation)
* [🧭 What is CoordinatorKit?](#-what-is-coordinatorkit)
* [🧱 Core Concepts](#-core-concepts)
* [🧪 Example Usage](#-example-usage)
* [🛠️ Customizing Navigation Validation](#️-customizing-navigation-validation)
* [🧼 Cleanup](#-cleanup)
* [🐞 Debug Logging](#-debug-logging)
* [📚 Advanced Notes](#-advanced-notes)
* [🧪 Testing](#-testing)
* [🛠 Requirements](#-requirements)
* [🙌 Contributing](#-contributing)
* [🔗 Links](#-links)

---

## ✨ Features

* ✅ **Macro-based coordinator system** — Automatically generates boilerplate.
* 🧭 **Type-safe routing** — Routes are enums conforming to `NavigationRoute`.
* 🧼 **Clean architecture** — Coordinators handle logic, routes build views.
* 📱 **SwiftUI-first** — Built for `NavigationStack`, `.sheet`, and `.fullScreenCover`.
* 📦 **Composable & scalable** — Perfect for modular or feature-based apps.
* 🧪 **Integrated ActionDispatcher** — Enables unidirectional data flow and side effects.

---

## 📦 Installation

### Swift Package Manager (SPM)

1. Open your Xcode project
2. Go to **File > Add Packages…**
3. Use the following URL:

```
https://github.com/vinodh06/CoordinatorKit
```

4. Select `CoordinatorKit` and add it to your project target.

---

## 🧭 What is CoordinatorKit?

CoordinatorKit helps manage SwiftUI navigation in a scalable, testable, and type-safe way.

It decouples navigation logic from your views by:

* Using **typed routes** via `NavigationRoute`
* Centralizing **side effects and navigation triggers** using `ActionDispatcher`
* Avoiding modal presentation conflicts through **built-in error safety**
* Reducing boilerplate via Swift macros (`@Coordinator`)

---

## 🧱 Core Concepts

### 1. `NavigationRoute`

A protocol that defines your app’s routes. Each route builds its own destination `View`.

```swift
enum MyRoute: NavigationRoute {
    case home, details

    enum Action {
        case didTapSomething
    }

    func build(actionDispatcher: ActionDispatcher<Action>) -> some View {
        switch self {
        case .home:
            HomeView()
                .onTapGesture {
                    actionDispatcher.send(.didTapSomething)
                }
        case .details:
            DetailsView()
        }
    }
}
```

Requirements:

* A unique `id` (provided by default)
* A `build()` method that returns a SwiftUI `View`
* An associated `Action` type

---

### 2. `Coordinator`

Define your coordinator using the `@Coordinator(MyRoute.self)` macro. It auto-generates navigation state, subscriptions, and cleanup.

```swift
@Coordinator(MyRoute.self)
final class MyAppCoordinator: ObservableObject {
    func handle(_ action: MyRoute.Action) {
        switch action {
        case .didTapSomething:
            try? push(.details)
        }
    }
}
```

The macro provides:

* `@Published` navigation stack and presentation state
* `ActionDispatcher` to pass actions into the coordinator
* Automatic cleanup on `deinit`

---

### 3. `CoordinatorView`

Wrap your coordinator in `CoordinatorView` to start navigation.

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            CoordinatorView(
                coordinator: MyAppCoordinator(),
                initialRoute: .home
            )
        }
    }
}
```

---

## 🧪 Example Usage

```swift
enum MyRoute: NavigationRoute {
    case home, details

    enum Action {
        case openDetails
    }

    func build(actionDispatcher: ActionDispatcher<Action>) -> some View {
        switch self {
        case .home:
            HomeScreen()
                .onTapGesture {
                    actionDispatcher.send(.openDetails)
                }
        case .details:
            DetailsScreen()
        }
    }
}
```

Create a coordinator:

```swift
@Coordinator(MyRoute.self)
final class MyCoordinator: ObservableObject {
    func handle(_ action: MyRoute.Action) {
        switch action {
        case .openDetails:
            try? push(.details)
        }
    }
}
```

Wire it into your app:

```swift
CoordinatorView(
    coordinator: MyCoordinator(),
    initialRoute: .home
)
```

---

## 🛠️ Customizing Navigation Validation

Block or validate transitions by overriding `validateNavigation(to:from:)`:

```swift
override func validateNavigation(to newRoute: Route, from currentRoute: Route?) throws {
    if currentRoute == .details && newRoute == .details {
        throw CoordinatorError.navigationNotAllowed("Already in details.")
    }
}
```

---

## 🧼 Cleanup

Manually reset navigation stack, sheet, fullscreen modals, and any subscriptions:

```swift
coordinator.cleanup()
```

---

## 🐞 Debug Logging

Enable debug logging to trace every action and route change:

```swift
coordinator.enableDebugLogging()
```

---

## 📚 Advanced Notes

* Macros (`@Coordinator`) require **Swift 5.9+** and **Xcode 15.3+**
* Macro support requires **macOS 13.3+** or later
* For unit testing, use mock coordinators and invoke `.handle()` manually
* Safe presentation helpers included:

  * `tryPresentSheet(_:)`
  * `tryPresentFullScreen(_:)`

---

## 🧪 Testing

All components are testable and coordinator logic can be validated in isolation:

```swift
let coordinator = AppCoordinator()
coordinator.handle(.goToDetail)
// Assert navigation stack updates accordingly
```

Use XCTest to simulate and assert navigation flow.

---

## 🛠 Requirements

* Swift 5.9+
* Xcode 15.3+
* Swift 6 toolchain
* iOS 16+, macOS 13.3+, watchOS 6+, tvOS 13+

---


## 🙌 Contributing

Contributions and feedback are welcome!
If you spot an issue or have an idea, feel free to [open an issue](https://github.com/vinodh06/CoordinatorKit/issues) or submit a PR.

---

## 🔗 Links

* [CoordinatorKit on GitHub](https://github.com/vinodh06/CoordinatorKit)

---
