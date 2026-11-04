import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation
import IdentifiedEnumCasesShared

public struct IdentifiedEnumCasesMacro: MemberMacro {
  struct CaseStyleTransformer {
    let memberName: String

    func transform(_ caseName: String) -> String {
      guard let style else { return caseName }
      return CaseConverter.format(caseName, to: style)
    }

    private var style: CaseStyle? {
      switch memberName {
      case "verbatim": .verbatim
      case "camelCase": .camelCase
      case "pascalCase": .pascalCase
      case "snakeCase": .snakeCase
      case "screamingSnakeCase": .screamingSnakeCase
      case "kebabCase": .kebabCase
      default: nil
      }
    }
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

      if declaration.inheritsCaseIDCodable, declaration.hasAssociatedValues {
        let codableError = Diagnostic(node: node._syntaxNode, message: Diagnostics.caseIDCodableWithAssociatedValues)
        context.diagnose(codableError)
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
    
    case mustBeEnum, mustHaveCases, caseIDCodableWithAssociatedValues
    
    public var message: String {
      switch self {
      case .mustBeEnum:
        return "`@IdentifiedEnumCasesMacro` can only be applied to an `enum`"
      case .mustHaveCases:
        return "`@IdentifiedEnumCasesMacro` can only be applied to an `enum` with `case` statements"
      case .caseIDCodableWithAssociatedValues:
        return "`CaseIDCodable` would lose associated values; use `@TaggedCodable` from MacroCodableKit instead"
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

private extension EnumDeclSyntax {
  var inheritsCaseIDCodable: Bool {
    inheritanceClause?.inheritedTypes.contains { inherited in
      ["CaseIDCodable", "IdentifiedEnumCases.CaseIDCodable"].contains(inherited.type.trimmedDescription)
    } ?? false
  }

  var hasAssociatedValues: Bool {
    memberBlock.members
      .compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
      .flatMap(\.elements)
      .contains { $0.parameterClause != nil }
  }
}

@main
struct MacroPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    IdentifiedEnumCasesMacro.self,
  ]
}
