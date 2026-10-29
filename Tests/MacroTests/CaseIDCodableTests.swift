import Foundation
import IdentifiedEnumCases
import XCTest

@IdentifiedEnumCases(caseStyle: .snakeCase)
private enum Status: CaseIDCodable, Equatable {
  case inProgress
  case done
}

@IdentifiedEnumCases(caseStyle: .kebabCase)
private enum Mode: CaseIDCodable, Equatable {
  case readOnly
}

final class CaseIDCodableTests: XCTestCase {
  func testEncodesCaseIDRawValue() throws {
    let data = try JSONEncoder().encode([Status.inProgress, .done])
    XCTAssertEqual(String(decoding: data, as: UTF8.self), #"["in_progress","done"]"#)
    XCTAssertEqual(String(decoding: try JSONEncoder().encode(Mode.readOnly), as: UTF8.self), #""read-only""#)
  }

  func testDecodesCaseIDRawValue() throws {
    let decoded = try JSONDecoder().decode([Status].self, from: Data(#"["done","in_progress"]"#.utf8))
    XCTAssertEqual(decoded, [.done, .inProgress])
  }

  func testRejectsUnknownToken() {
    XCTAssertThrowsError(try JSONDecoder().decode(Status.self, from: Data(#""inProgress""#.utf8))) { error in
      guard case DecodingError.dataCorrupted = error else {
        return XCTFail("unexpected error \(error)")
      }
    }
  }
}
