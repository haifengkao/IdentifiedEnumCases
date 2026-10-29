/// Encodes and decodes an enum as the single string `caseID.rawValue`.
///
/// Pair it with `@IdentifiedEnumCases` on an enum without associated values; the `caseStyle:` you choose decides
/// the wire string:
///
///     @IdentifiedEnumCases(caseStyle: .snakeCase)
///     enum Status: CaseIDCodable {
///       case inProgress
///       case done
///     }
///
///     // Status.inProgress encodes as "in_progress"
///
/// Decoding an unknown string throws `DecodingError.dataCorrupted`.
public protocol CaseIDCodable: Codable, CaseIterable {
  associatedtype CaseID: RawRepresentable where CaseID.RawValue == String

  var caseID: CaseID { get }
}

public extension CaseIDCodable {
  init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    let token = try container.decode(String.self)
    guard let value = Self.allCases.first(where: { $0.caseID.rawValue == token }) else {
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Unknown \(Self.self) token: \(token)"
      )
    }
    self = value
  }

  func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(caseID.rawValue)
  }
}
