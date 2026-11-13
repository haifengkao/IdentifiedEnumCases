/// Encodes and decodes an enum as the single string `caseID.rawValue`.
///
/// Pair it with `@IdentifiedEnumCases` on an enum without associated values; the `caseStyle:` you choose decides
/// the wire string:
///
///     @IdentifiedEnumCases(caseStyle: .snakeCase)
///     enum Color: CaseIDCodable {
///       case lightBlue
///       case red
///     }
///
///     // Color.lightBlue encodes as "light_blue"
///
/// Decoding an unknown string throws `DecodingError.dataCorrupted`.
///
/// Declare `CaseIDCodable` on the enum itself, next to `@IdentifiedEnumCases`: the macro then writes
/// `init(from:)` and `encode(to:)` as members. That matters for an enum with a raw type, whose
/// compiler-synthesized `Codable` would otherwise win over this protocol's default implementation.
///
/// Associated values are not encoded. `@IdentifiedEnumCases` rejects an enum that declares both; use
/// MacroCodableKit's `@TaggedCodable` for those enums.
public protocol CaseIDCodable: Codable, CaseIterable {
  associatedtype CaseID: RawRepresentable where CaseID.RawValue == String

  var caseID: CaseID { get }
}

public extension CaseIDCodable {
  init(from decoder: any Decoder) throws {
    self = try Self.decodeCaseID(from: decoder)
  }

  func encode(to encoder: any Encoder) throws {
    try encodeCaseID(to: encoder)
  }

  /// Decodes the case whose `caseID.rawValue` equals the single string in `decoder`.
  static func decodeCaseID(from decoder: any Decoder) throws -> Self {
    let container = try decoder.singleValueContainer()
    let token = try container.decode(String.self)
    guard let value = allCases.first(where: { $0.caseID.rawValue == token }) else {
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Unknown \(Self.self) token: \(token)"
      )
    }
    return value
  }

  /// Encodes `caseID.rawValue` as a single string.
  func encodeCaseID(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(caseID.rawValue)
  }
}
