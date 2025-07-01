# CoordinatorKit

CoordinatorKit is a modern, lightweight SwiftUI navigation framework built with the power of Swift Macros. It enables a clean, type-safe, and declarative way to manage navigation flows in SwiftUI apps with minimal boilerplate.

> 🧠 Built with Swift 6 Macros — Requires Xcode 15.3+ and Swift 6 toolchain.

---

## ✨ Features

- ✅ **Macro-based coordinator system** — Automatically generates boilerplate.
- 🧭 **Type-safe routing** — Routes are enums that conform to `NavigationRoute`.
- 🧼 **Clean architecture** — Coordinators handle logic, routes build views.
- 📱 **SwiftUI-first** — Built for NavigationStack, `.sheet`, `.fullScreenCover`.
- 📦 **Composable & scalable** — Perfect for modular or feature-based architecture.
- 🧪 **Integrated ActionDispatcher** — Enables unidirectional data flow.

---

## 📦 Installation

### Swift Package Manager (SPM)

1. Open your Xcode project
2. Go to **File > Add Packages…**
3. Use the following URL:

```
https://github.com/vinodh06/CoordinatorKit
```

4. Choose `CoordinatorKit` and add it to your target.

---

## 🚀 Quick Start

Here’s how to build a coordinator-driven navigation flow in minutes:

### 1. Define Your Routes

Create an enum that conforms to `NavigationRoute` and define your `Action` type.

```swift
import CoordinatorKit
import SwiftUI

enum AppRoute: NavigationRoute {
    case home
    case detail(message: String)

    enum Action {
        case goToDetail
    }

    func build(actionDispatcher: ActionDispatcher<Action>) -> some View {
        switch self {
        case .home:
            VStack {
                Text("Welcome to Home")
                Button("Go to Detail") {
                    actionDispatcher.send(.goToDetail)
                }
            }

        case .detail(let message):
            Text("Detail screen: \(message)")
        }
    }
}
```

---

### 2. Create a Macro-powered Coordinator

Use the `@Coordinator` macro to auto-generate the boilerplate for managing navigation state.

```swift
@Coordinator(AppRoute)
final class AppCoordinator {
    @MainActor
    func handle(_ action: AppRoute.Action) {
        switch action {
        case .goToDetail:
            push(.detail(message: "Hello from Home"))
        }
    }
}
```

> The macro adds state like `navigationPath`, `sheetRoute`, and `actionDispatcher` automatically.

---

### 3. Plug into SwiftUI

Render your coordinator in your root SwiftUI view.

```swift
struct ContentView: View {
    var body: some View {
        CoordinatorView(
            coordinator: AppCoordinator(),
            initialRoute: .home
        )
    }
}
```

---

## 🔍 Behind the Scenes

When you use `@Coordinator(AppRoute)`, it expands to:

- Published properties for managing:
  - `navigationPath`
  - `sheetRoute`
  - `fullScreenRoute`
- An `ActionDispatcher` and cancellables
- Conformance to `Coordinator` protocol

---

## 📚 API Reference

### `NavigationRoute`
A protocol requiring a `build(actionDispatcher:)` method to generate views.

```swift
func build(actionDispatcher: ActionDispatcher<Action>) -> some View
```

### `Coordinator`
A protocol defining:

- `push`, `pop`, `presentSheet`, `dismissSheet`, etc.
- `handle(_ action: Action)`
- Navigation properties auto-injected by the macro

### `ActionDispatcher`
A Combine-based publisher to decouple view actions from navigation logic.

---

## ✅ Supported Navigation Types

| Navigation Style     | Supported? |
|----------------------|------------|
| `NavigationStack`    | ✅ Yes      |
| `.sheet`             | ✅ Yes      |
| `.fullScreenCover`   | ✅ Yes      |
| Deep linking         | ✅ Planned  |

---

## 🧪 Testing

All components are testable. You can instantiate coordinators and simulate route transitions or actions.

```swift
let coordinator = AppCoordinator()
coordinator.handle(.goToDetail)
```

Use Swift’s test suite to validate navigation logic.

---

## 🛠 Requirements

- Xcode 15.3+
- Swift 6 toolchain
- iOS 16+, macOS 10.15+, watchOS 6+, tvOS 13+

---

## 📄 License

MIT License — see [LICENSE](./LICENSE)

---

## 🙌 Contributing

Pull requests and feedback welcome! If you spot a bug or have ideas, please open an issue or submit a PR.

---

## 🔗 Links

- [CoordinatorKit on GitHub](https://github.com/vinodh06/CoordinatorKit)

---
