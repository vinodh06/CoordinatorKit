@attached(member, names: arbitrary)
@attached(extension, conformances: Coordinator)
public macro Coordinator(_ route: Any) = #externalMacro(
    module: "CoordinatorKitMacros",
    type: "CoordinatorKit"
)
