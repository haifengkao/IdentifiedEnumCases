import Foundation

/// The single word-boundary and casing rule set. The macro target uses it to
/// write `CaseID` raw values at expansion time, and the runtime target
/// re-exports it, so both always produce the same strings.
public enum CaseStyle: Sendable {
  case verbatim
  case camelCase
  case pascalCase
  case snakeCase
  case screamingSnakeCase
  case kebabCase
}

public struct CaseConverter: Sendable {
  public static func tokenize(_ input: String) -> [String] {
    let splitAcronyms = input.replacingOccurrences(
      of: "([A-Z]+)([A-Z][a-z])",
      with: "$1 $2",
      options: .regularExpression
    )
    let splitCamel = splitAcronyms.replacingOccurrences(
      of: "([a-z0-9])([A-Z])",
      with: "$1 $2",
      options: .regularExpression
    )

    let separators = CharacterSet.alphanumerics.inverted
    let components = splitCamel.components(separatedBy: separators)

    return components
      .filter { !$0.isEmpty }
      .map { $0.lowercased() }
  }

  public static func format(_ string: String, to style: CaseStyle) -> String {
    let tokens = tokenize(string)
    guard !tokens.isEmpty else { return string }

    switch style {
    case .verbatim:
      return string
    case .camelCase:
      let first = tokens[0]
      let rest = tokens.dropFirst().map(\.capitalized)
      return first + rest.joined()
    case .pascalCase:
      return tokens.map(\.capitalized).joined()
    case .snakeCase:
      return tokens.joined(separator: "_")
    case .screamingSnakeCase:
      return tokens.joined(separator: "_").uppercased()
    case .kebabCase:
      return tokens.joined(separator: "-")
    }
  }
}
