import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation

public struct IdentifiedEnumCasesMacro: MemberMacro {
  struct CaseStyleTransformer {
    let memberName: String

    func transform(_ caseName: String) -> String {
      switch memberName {
      case "verbatim":
        return caseName
      case "camelCase":
        return CaseConverter.format(caseName, to: .camelCase)
      case "pascalCase":
        return CaseConverter.format(caseName, to: .pascalCase)
      case "snakeCase":
        return CaseConverter.format(caseName, to: .snakeCase)
      case "screamingSnakeCase":
        return CaseConverter.format(caseName, to: .screamingSnakeCase)
      case "kebabCase":
        return CaseConverter.format(caseName, to: .kebabCase)
      default:
        return caseName
      }
    }
  }

  struct CaseConverter {
    static func tokenize(_ input: String) -> [String] {
      let splitCamel = input.replacingOccurrences(
        of: "([a-z])([A-Z])",
        with: "$1 $2",
        options: .regularExpression
      )

      let separators = CharacterSet.alphanumerics.inverted
      let components = splitCamel.components(separatedBy: separators)

      return components
        .filter { !$0.isEmpty }
        .map { $0.lowercased() }
    }

    static func format(_ string: String, to style: Style) -> String {
      let tokens = tokenize(string)
      guard !tokens.isEmpty else { return string }

      switch style {
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

  enum Style {
    case camelCase
    case pascalCase
    case snakeCase
    case screamingSnakeCase
    case kebabCase
  }

  public static func expansion<Declaration, Context>(
    of node: SwiftSyntax.AttributeSyntax,
    providingMembersOf declaration: Declaration,
    in context: Context) throws -> [SwiftSyntax.DeclSyntax] where Declaration : SwiftSyntax.DeclGroupSyntax, Context : SwiftSyntaxMacros.MacroExpansionContext {
      
      guard let declaration = declaration.as(EnumDeclSyntax.self) else {
        let enumError = Diagnostic(node: node._syntaxNode, message: Diagnostics.mustBeEnum)
        context.diagnose(enumError)
        return []
      }
      
      let caseIds = declaration.memberBlock.members
        .compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
        .flatMap(\.elements)
        .map(\.name.text)
      
      guard !caseIds.isEmpty else {
        let enumError = Diagnostic(node: node._syntaxNode, message: Diagnostics.mustHaveCases)
        context.diagnose(enumError)
        return []
      }

      let caseStyle = parseCaseStyle(from: node)
      let modifier = declaration.hasPublicModifier ? "public " : ""
      let enumID = """
      \(modifier)enum CaseID: String, Hashable, CaseIterable, CustomStringConvertible {
      \(caseIds.map { caseDeclaration(for: $0, using: caseStyle) }.joined())
        \(modifier)var description: String {
          self.rawValue
        }
      }
      """
      let idAccessor = "\(modifier)var caseID: CaseID {\n  switch self {\n\(caseIds.map { "  case .\($0): .\($0)\n" }.joined())  }\n}"

      return [
        DeclSyntax(stringLiteral: enumID),
        DeclSyntax(stringLiteral: idAccessor)
      ]
    }

  static func parseCaseStyle(from node: AttributeSyntax) -> CaseStyleTransformer {
    guard case let .argumentList(arguments) = node.arguments,
          let caseStyleArgument = arguments.first(where: { $0.label?.text == "caseStyle" }),
          let member = caseStyleArgument.expression.as(MemberAccessExprSyntax.self)
    else {
      return CaseStyleTransformer(memberName: "verbatim")
    }

    return CaseStyleTransformer(memberName: member.declName.baseName.text)
  }

  static func caseDeclaration(for caseID: String, using transformer: CaseStyleTransformer) -> String {
    let rawValue = transformer.transform(caseID)

    if rawValue == caseID {
      return "  case \(caseID)\n"
    }

    return "  case \(caseID) = \"\(rawValue)\"\n"
  }
  
  public enum Diagnostics: String, DiagnosticMessage {
    
    case mustBeEnum, mustHaveCases
    
    public var message: String {
      switch self {
      case .mustBeEnum:
        return "`@IdentifiedEnumCasesMacro` can only be applied to an `enum`"
      case .mustHaveCases:
        return "`@IdentifiedEnumCasesMacro` can only be applied to an `enum` with `case` statements"
      }
    }
    
    public var diagnosticID: MessageID {
      MessageID(domain: "IdentifiedEnumCasesMacro", id: rawValue)
    }
    
    public var severity: DiagnosticSeverity { .error }
  }
}

private extension DeclGroupSyntax {
  var hasPublicModifier: Bool {
    self.modifiers.children(viewMode: .fixedUp)
      .compactMap { syntax in
        syntax.as(DeclModifierSyntax.self)?
          .children(viewMode: .fixedUp)
          .contains { syntax in
            switch syntax.as(TokenSyntax.self)?.tokenKind {
            case .keyword(.public):
              return true
            default:
              return false
            }
          }
      }
      .contains(true)
  }
}

@main
struct MacroPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    IdentifiedEnumCasesMacro.self,
  ]
}
