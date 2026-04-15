import XCTest
import IdentifiedEnumCases
import IdentifiedEnumCasesMacro
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import SwiftDiagnostics

final class MacroTests: XCTestCase {
  private let testMacros: [String: Macro.Type] = [
    "IdentifiedEnumCases": IdentifiedEnumCasesMacro.self,
  ]

  func testMacro() {
    
    assertMacroExpansion(
            """
            @IdentifiedEnumCases
            enum Nightshade {
              case potato(PotatoVariety), tomato(TomatoVariety)
              case eggplant(EggplantVariety)

              enum PotatoVariety {}
              enum TomatoVariety {}
              enum EggplantVariety {}
            }
            """,
            expandedSource:
            """

            enum Nightshade {
              case potato(PotatoVariety), tomato(TomatoVariety)
              case eggplant(EggplantVariety)

              enum PotatoVariety {}
              enum TomatoVariety {}
              enum EggplantVariety {}
            
              enum CaseID: String, Hashable, CaseIterable, CustomStringConvertible {
                case potato
                case tomato
                case eggplant

                var description: String {
                  self.rawValue
                }
              }
            
              var caseID: CaseID {
                switch self {
                case .potato:
                  .potato
                case .tomato:
                  .tomato
                case .eggplant:
                  .eggplant
                }
              }
            }
            """,
            macros: testMacros,
            indentationWidth: .spaces(2)
    )
  }
  
  func testPublicMacro() {
    assertMacroExpansion(
          """
          @IdentifiedEnumCases
          public enum Nightshade {
            case potato(PotatoVariety), tomato(TomatoVariety)
            case eggplant(EggplantVariety)
          
            public enum PotatoVariety {}
            public enum TomatoVariety {}
            public enum EggplantVariety {}
          }
          """,
          expandedSource:
          """
          
          public enum Nightshade {
            case potato(PotatoVariety), tomato(TomatoVariety)
            case eggplant(EggplantVariety)
          
            public enum PotatoVariety {}
            public enum TomatoVariety {}
            public enum EggplantVariety {}
          
            public enum CaseID: String, Hashable, CaseIterable, CustomStringConvertible {
              case potato
              case tomato
              case eggplant

              public var description: String {
                self.rawValue
              }
            }
          
            public var caseID: CaseID {
              switch self {
              case .potato:
                .potato
              case .tomato:
                .tomato
              case .eggplant:
                .eggplant
              }
            }
          }
          """,
          macros: testMacros,
          indentationWidth: .spaces(2)
    )
  }

  func testScreamingSnakeCaseMacro() {
    assertMacroExpansion(
          """
          @IdentifiedEnumCases(caseStyle: .screamingSnakeCase)
          enum ExampleCase {
            case sampleEntry
            case extraValue(query: String)
          }
          """,
          expandedSource:
          """

          enum ExampleCase {
            case sampleEntry
            case extraValue(query: String)

            enum CaseID: String, Hashable, CaseIterable, CustomStringConvertible {
              case sampleEntry = "SAMPLE_ENTRY"
              case extraValue = "EXTRA_VALUE"

              var description: String {
                self.rawValue
              }
            }

            var caseID: CaseID {
              switch self {
              case .sampleEntry:
                .sampleEntry
              case .extraValue:
                .extraValue
              }
            }
          }
          """,
          macros: testMacros,
          indentationWidth: .spaces(2)
    )
  }

  func testSnakeCaseMacro() {
    assertMacroExpansion(
          """
          @IdentifiedEnumCases(caseStyle: .snakeCase)
          enum Command {
            case sendMessage(text: String)
          }
          """,
          expandedSource:
          """

          enum Command {
            case sendMessage(text: String)

            enum CaseID: String, Hashable, CaseIterable, CustomStringConvertible {
              case sendMessage = "send_message"

              var description: String {
                self.rawValue
              }
            }

            var caseID: CaseID {
              switch self {
              case .sendMessage:
                .sendMessage
              }
            }
          }
          """,
          macros: testMacros,
          indentationWidth: .spaces(2)
    )
  }

  func testVerbatimMacro() {
    assertMacroExpansion(
          """
          @IdentifiedEnumCases(caseStyle: .verbatim)
          enum Command {
            case sample_entry
          }
          """,
          expandedSource:
          """

          enum Command {
            case sample_entry

            enum CaseID: String, Hashable, CaseIterable, CustomStringConvertible {
              case sample_entry

              var description: String {
                self.rawValue
              }
            }

            var caseID: CaseID {
              switch self {
              case .sample_entry:
                .sample_entry
              }
            }
          }
          """,
          macros: testMacros,
          indentationWidth: .spaces(2)
    )
  }

  func testDefaultVerbatimMacro() {
    assertMacroExpansion(
          """
          @IdentifiedEnumCases
          enum Command {
            case sample_entry
          }
          """,
          expandedSource:
          """

          enum Command {
            case sample_entry

            enum CaseID: String, Hashable, CaseIterable, CustomStringConvertible {
              case sample_entry

              var description: String {
                self.rawValue
              }
            }

            var caseID: CaseID {
              switch self {
              case .sample_entry:
                .sample_entry
              }
            }
          }
          """,
          macros: testMacros,
          indentationWidth: .spaces(2)
    )
  }

  func testCamelCaseMacro() {
    assertMacroExpansion(
          """
          @IdentifiedEnumCases(caseStyle: .camelCase)
          enum Command {
            case sample_entry
          }
          """,
          expandedSource:
          """

          enum Command {
            case sample_entry

            enum CaseID: String, Hashable, CaseIterable, CustomStringConvertible {
              case sample_entry = "sampleEntry"

              var description: String {
                self.rawValue
              }
            }

            var caseID: CaseID {
              switch self {
              case .sample_entry:
                .sample_entry
              }
            }
          }
          """,
          macros: testMacros,
          indentationWidth: .spaces(2)
    )
  }

  func testPascalCaseMacro() {
    assertMacroExpansion(
          """
          @IdentifiedEnumCases(caseStyle: .pascalCase)
          enum Command {
            case sample_entry
          }
          """,
          expandedSource:
          """

          enum Command {
            case sample_entry

            enum CaseID: String, Hashable, CaseIterable, CustomStringConvertible {
              case sample_entry = "SampleEntry"

              var description: String {
                self.rawValue
              }
            }

            var caseID: CaseID {
              switch self {
              case .sample_entry:
                .sample_entry
              }
            }
          }
          """,
          macros: testMacros,
          indentationWidth: .spaces(2)
    )
  }

  func testKebabCaseMacro() {
    assertMacroExpansion(
          """
          @IdentifiedEnumCases(caseStyle: .kebabCase)
          enum Command {
            case sample_entry
          }
          """,
          expandedSource:
          """

          enum Command {
            case sample_entry

            enum CaseID: String, Hashable, CaseIterable, CustomStringConvertible {
              case sample_entry = "sample-entry"

              var description: String {
                self.rawValue
              }
            }

            var caseID: CaseID {
              switch self {
              case .sample_entry:
                .sample_entry
              }
            }
          }
          """,
          macros: testMacros,
          indentationWidth: .spaces(2)
    )
  }

  func testCaseConverter() {
    XCTAssertEqual(CaseConverter.format("sample_entry", to: .verbatim), "sample_entry")
    XCTAssertEqual(CaseConverter.tokenize("sampleEntry"), ["sample", "entry"])
    XCTAssertEqual(CaseConverter.tokenize("SampleEntry"), ["sample", "entry"])
    XCTAssertEqual(CaseConverter.tokenize("sample_entry"), ["sample", "entry"])
    XCTAssertEqual(CaseConverter.tokenize("sample-entry"), ["sample", "entry"])

    XCTAssertEqual(CaseConverter.format("sample_entry", to: .camelCase), "sampleEntry")
    XCTAssertEqual(CaseConverter.format("sample_entry", to: .pascalCase), "SampleEntry")
    XCTAssertEqual(CaseConverter.format("sampleEntry", to: .snakeCase), "sample_entry")
    XCTAssertEqual(CaseConverter.format("sampleEntry", to: .screamingSnakeCase), "SAMPLE_ENTRY")
    XCTAssertEqual(CaseConverter.format("sampleEntry", to: .kebabCase), "sample-entry")
  }
    
  func testMustBeEnumDiagnostic() {
    assertMacroExpansion("@IdentifiedEnumCases struct Tomato {}",
                         expandedSource: "struct Tomato {}",
                         diagnostics: [DiagnosticSpec(message: "`@IdentifiedEnumCasesMacro` can only be applied to an `enum`", line: 1, column: 1)],
                         macros: testMacros)
    
    assertMacroExpansion("@IdentifiedEnumCases class Tomato {}",
                         expandedSource: "class Tomato {}",
                         diagnostics: [DiagnosticSpec(message: "`@IdentifiedEnumCasesMacro` can only be applied to an `enum`", line: 1, column: 1)],
                         macros: testMacros)
    
    assertMacroExpansion("@IdentifiedEnumCases protocol Tomato {}",
                         expandedSource: "protocol Tomato {}",
                         diagnostics: [DiagnosticSpec(message: "`@IdentifiedEnumCasesMacro` can only be applied to an `enum`", line: 1, column: 1)],
                         macros: testMacros)

  }
  
  func testEnumMustHaveCasesDiagnostic() {
    assertMacroExpansion("@IdentifiedEnumCases enum Tomato {}",
                         expandedSource: "enum Tomato {}",
                         diagnostics: [DiagnosticSpec(message: "`@IdentifiedEnumCasesMacro` can only be applied to an `enum` with `case` statements", line: 1, column: 1)],
                         macros: testMacros)
  }
}
