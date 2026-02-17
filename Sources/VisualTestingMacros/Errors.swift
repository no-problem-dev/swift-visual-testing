enum VisualTestingMacroError: Error, CustomStringConvertible {
    case onlyApplicableToStruct
    case missingViewName
    case snapshotOnlyOnFunction

    var description: String {
        switch self {
        case .onlyApplicableToStruct:
            return "@SnapshotSuite can only be applied to structs"
        case .missingViewName:
            return "@SnapshotSuite requires a view name string argument"
        case .snapshotOnlyOnFunction:
            return "@Snapshot and @ComponentSnapshot can only be applied to functions"
        }
    }
}
