/// A macro that creates named cases for an enum. Helpful
/// when the enum has an associated value.
/// For example,
///
///     @IdentifiedEnumCases
///     enum AppRoute {
///       case item(ItemRoute)
///       case user(UserRoute)
///     }
///
/// generates to
///
///     enum AppRoute {
///       case item(ItemRoute)
///       case user(UserRoute)
///
///       var id: ID {
///         switch self {
///         case .item: .item
///         case .user: .user
///       }
///
///       enum ID: String, Hashable, CaseIterable {
///         case item
///         case user
///       }
///     }
///
/// If the enum is `public`, the generated `ID` enum and the
/// generated `id` accessor will also be `public`
///
/// The generated `CaseID` raw values can also be transformed to a
/// serialized form:
///
///     @IdentifiedEnumCases(caseStyle: .screamingSnakeCase)
///     enum ExampleCase {
///       case sampleEntry
///       case extraValue(query: String)
///     }
///
/// generates `CaseID.sampleEntry.rawValue == "SAMPLE_ENTRY"`
/// and `CaseID.extraValue.rawValue == "EXTRA_VALUE"`.

@attached(member, names: named(CaseID), named(caseID))
public macro IdentifiedEnumCases(caseStyle: CaseStyle = .verbatim) = #externalMacro(module: "IdentifiedEnumCasesMacro", type: "IdentifiedEnumCasesMacro")
