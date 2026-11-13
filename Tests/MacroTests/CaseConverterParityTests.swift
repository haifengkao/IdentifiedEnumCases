import XCTest
import IdentifiedEnumCases
import IdentifiedEnumCasesMacro
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport

/// The macro writes `CaseID` raw values at compile time and the library formats
/// strings at run time. Both must give the same string for every case name.
final class CaseConverterParityTests: XCTestCase {
  private let testMacros: [String: Macro.Type] = [
    "IdentifiedEnumCases": IdentifiedEnumCasesMacro.self,
  ]

  private static let caseNames = [
    "sampleEntry",
    "sampleSHA256Entry",
    "invalidJSONPayload",
    "openViaURL",
    "sameDocumentURLChanged",
    "nodesSHA256Mismatch",
    "URLLoaded",
    "http2Upgrade",
  ]

  private static let styles: [(member: String, style: CaseStyle)] = [
    ("verbatim", .verbatim),
    ("camelCase", .camelCase),
    ("pascalCase", .pascalCase),
    ("snakeCase", .snakeCase),
    ("screamingSnakeCase", .screamingSnakeCase),
    ("kebabCase", .kebabCase),
  ]

  func testMacroExpansionMatchesCaseConverterForEveryStyle() {
    let caseList = Self.caseNames.map { "  case \($0)" }.joined(separator: "\n")
    for (member, style) in Self.styles {
      let caseIDLines = Self.caseNames.map { name -> String in
        let rawValue = CaseConverter.format(name, to: style)
        return rawValue == name ? "    case \(name)" : "    case \(name) = \"\(rawValue)\""
      }
      let switchLines = Self.caseNames.map { "    case .\($0):\n      .\($0)" }
      assertMacroExpansion(
        """
        @IdentifiedEnumCases(caseStyle: .\(member))
        enum Event {
        \(caseList)
        }
        """,
        expandedSource:
        """

        enum Event {
        \(caseList)

          enum CaseID: String, Codable, Sendable, Hashable, CaseIterable, CustomStringConvertible {
        \(caseIDLines.joined(separator: "\n"))

            var description: String {
              self.rawValue
            }
          }

          var caseID: CaseID {
            switch self {
        \(switchLines.joined(separator: "\n"))
            }
          }
        }
        """,
        macros: testMacros,
        indentationWidth: .spaces(2)
      )
    }
  }

  func testCompiledCaseIDRawValuesMatchCaseConverter() {
    XCTAssertEqual(rawValues(SnakeEvent.CaseID.self), Self.caseNames.map { CaseConverter.format($0, to: .snakeCase) })
    XCTAssertEqual(
      rawValues(ScreamingSnakeEvent.CaseID.self),
      Self.caseNames.map { CaseConverter.format($0, to: .screamingSnakeCase) }
    )
    XCTAssertEqual(rawValues(KebabEvent.CaseID.self), Self.caseNames.map { CaseConverter.format($0, to: .kebabCase) })
    XCTAssertEqual(rawValues(CamelEvent.CaseID.self), Self.caseNames.map { CaseConverter.format($0, to: .camelCase) })
    XCTAssertEqual(rawValues(PascalEvent.CaseID.self), Self.caseNames.map { CaseConverter.format($0, to: .pascalCase) })
  }

  /// Both sides above run the same `CaseConverter`, so they cannot catch a change to the
  /// rules themselves. These pinned strings are the wire format that callers store.
  func testCompiledCaseIDRawValuesArePinned() {
    XCTAssertEqual(rawValues(SnakeEvent.CaseID.self), [
      "sample_entry", "sample_sha256_entry", "invalid_json_payload", "open_via_url",
      "same_document_url_changed", "nodes_sha256_mismatch", "url_loaded", "http2_upgrade",
    ])
    XCTAssertEqual(rawValues(ScreamingSnakeEvent.CaseID.self), [
      "SAMPLE_ENTRY", "SAMPLE_SHA256_ENTRY", "INVALID_JSON_PAYLOAD", "OPEN_VIA_URL",
      "SAME_DOCUMENT_URL_CHANGED", "NODES_SHA256_MISMATCH", "URL_LOADED", "HTTP2_UPGRADE",
    ])
    XCTAssertEqual(rawValues(KebabEvent.CaseID.self), [
      "sample-entry", "sample-sha256-entry", "invalid-json-payload", "open-via-url",
      "same-document-url-changed", "nodes-sha256-mismatch", "url-loaded", "http2-upgrade",
    ])
    XCTAssertEqual(rawValues(CamelEvent.CaseID.self), [
      "sampleEntry", "sampleSha256Entry", "invalidJsonPayload", "openViaUrl",
      "sameDocumentUrlChanged", "nodesSha256Mismatch", "urlLoaded", "http2Upgrade",
    ])
    XCTAssertEqual(rawValues(PascalEvent.CaseID.self), [
      "SampleEntry", "SampleSha256Entry", "InvalidJsonPayload", "OpenViaUrl",
      "SameDocumentUrlChanged", "NodesSha256Mismatch", "UrlLoaded", "Http2Upgrade",
    ])
  }
}

private func rawValues<T: CaseIterable & RawRepresentable>(_: T.Type) -> [String] where T.RawValue == String {
  T.allCases.map(\.rawValue)
}

@IdentifiedEnumCases(caseStyle: .snakeCase)
private enum SnakeEvent {
  case sampleEntry, sampleSHA256Entry, invalidJSONPayload, openViaURL
  case sameDocumentURLChanged, nodesSHA256Mismatch, URLLoaded, http2Upgrade
}

@IdentifiedEnumCases(caseStyle: .screamingSnakeCase)
private enum ScreamingSnakeEvent {
  case sampleEntry, sampleSHA256Entry, invalidJSONPayload, openViaURL
  case sameDocumentURLChanged, nodesSHA256Mismatch, URLLoaded, http2Upgrade
}

@IdentifiedEnumCases(caseStyle: .kebabCase)
private enum KebabEvent {
  case sampleEntry, sampleSHA256Entry, invalidJSONPayload, openViaURL
  case sameDocumentURLChanged, nodesSHA256Mismatch, URLLoaded, http2Upgrade
}

@IdentifiedEnumCases(caseStyle: .camelCase)
private enum CamelEvent {
  case sampleEntry, sampleSHA256Entry, invalidJSONPayload, openViaURL
  case sameDocumentURLChanged, nodesSHA256Mismatch, URLLoaded, http2Upgrade
}

@IdentifiedEnumCases(caseStyle: .pascalCase)
private enum PascalEvent {
  case sampleEntry, sampleSHA256Entry, invalidJSONPayload, openViaURL
  case sameDocumentURLChanged, nodesSHA256Mismatch, URLLoaded, http2Upgrade
}
