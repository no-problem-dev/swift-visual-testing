enum VisualTestingMacroError: Error, CustomStringConvertible {
    case onlyApplicableToStruct
    case missingViewName
    case snapshotOnlyOnFunction
    case inNavigationOnComponent
    case markerWithoutTarget(marker: String, targets: String)

    var description: String {
        switch self {
        case .onlyApplicableToStruct:
            return "@SnapshotSuite can only be applied to structs"
        case .missingViewName:
            return "@SnapshotSuite requires a view name string argument"
        case .snapshotOnlyOnFunction:
            return "@Snapshot and @ComponentSnapshot can only be applied to functions"
        case .inNavigationOnComponent:
            return "@InNavigation cannot apply to @ComponentSnapshot: a component is captured "
                + "without a device frame, so there is no navigation bar in the image. Remove "
                + "@InNavigation, or capture this state with @Snapshot"
        case .markerWithoutTarget(let marker, let targets):
            return "\(marker) does nothing on its own; it only applies to a function marked \(targets)"
        }
    }
}
