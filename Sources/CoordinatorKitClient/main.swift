import CoordinatorKit

enum HomeRoute: NavigationRoute {
    
    case demo
    case screen2
    
    enum Action {
        case gotoScreen2
    }
    
    func build(actionDispatcher: ActionDispatcher<Action>) -> some View {
        switch self {
        case .demo:
            VStack {
                Text("demo")
                Button {
                    actionDispatcher.send(.gotoScreen2)
                } label: {
                    Text("Go to screen 2")
                }
            }


        case .screen2:
            Text("Screen 2")
        }
    }
}


@Coordinator(HomeRoute)
class HomeCoordinator {
    @MainActor
    func handle(_ action: HomeRoute.Action) {
        switch action {
        case .gotoScreen2:
            push(.demo)
        }
    }
}
