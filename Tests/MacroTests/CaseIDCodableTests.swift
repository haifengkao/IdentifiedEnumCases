import Foundation
import IdentifiedEnumCases
import XCTest

@IdentifiedEnumCases(caseStyle: .snakeCase)
private enum Color: CaseIDCodable, Equatable {
  case lightBlue
  case red
}

@IdentifiedEnumCases(caseStyle: .kebabCase)
private enum Mode: CaseIDCodable, Equatable {
  case readOnly
}

final class CaseIDCodableTests: XCTestCase {
  func testEncodesCaseIDRawValue() throws {
    let data = try JSONEncoder().encode([Color.lightBlue, .red])
    XCTAssertEqual(String(decoding: data, as: UTF8.self), #"["light_blue","red"]"#)
    XCTAssertEqual(String(decoding: try JSONEncoder().encode(Mode.readOnly), as: UTF8.self), #""read-only""#)
  }

  func testDecodesCaseIDRawValue() throws {
    let decoded = try JSONDecoder().decode([Color].self, from: Data(#"["red","light_blue"]"#.utf8))
    XCTAssertEqual(decoded, [.red, .lightBlue])
  }

  func testRejectsUnknownToken() {
    XCTAssertThrowsError(try JSONDecoder().decode(Color.self, from: Data(#""lightBlue""#.utf8))) { error in
      guard case DecodingError.dataCorrupted = error else {
        return XCTFail("unexpected error \(error)")
      }
    }
  }
}
