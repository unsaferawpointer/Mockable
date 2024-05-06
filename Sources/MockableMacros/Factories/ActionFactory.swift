//
//  ActionFactory.swift
//
//
//  Created by Anton Cherkasov on 10.05.2024.
//

import SwiftSyntax

protocol ActionFactoryProtocol {
	static func makeEnum(from functions: [FunctionDeclSyntax], with configration: Configuration.Action) -> EnumDeclSyntax
	static func makeVariable(with configration: Configuration.Action) -> VariableDeclSyntax
}

final class ActionFactory { }

// MARK: - ActionFactoryProtocol
extension ActionFactory: ActionFactoryProtocol {

	static func makeStorage(from functions: [FunctionDeclSyntax]) -> MacrosData {
		DataFactory().makeData(from: functions)
	}

	static func makeEnum(from functions: [FunctionDeclSyntax], with configration: Configuration.Action) -> EnumDeclSyntax {

		let data = DataFactory().makeData(from: functions)

		let members = data.cases.compactMap { wrapper in
			let parameters = wrapper.parameters.map {
				EnumCaseParameterSyntax(
					firstName: $0.name,
					colon: .colonToken(),
					type: $0.type,
					trailingComma: $0.isLast ? nil : .commaToken()
				)
			}
			let parameterList = EnumCaseParameterListSyntax(parameters)
			let parameterClause = !parameters.isEmpty ? EnumCaseParameterClauseSyntax(parameters: parameterList) : nil
			let element = EnumCaseElementSyntax(name: wrapper.name, parameterClause: parameterClause)

			return EnumCaseDeclSyntax(
				elements: EnumCaseElementListSyntax([element])
			)
		}.map {
			MemberBlockItemSyntax(decl: $0)
		}

		let memberBlock = MemberBlockSyntax(members: MemberBlockItemListSyntax(members))

		return EnumDeclSyntax(
			enumKeyword: .keyword(.enum),
			name: configration.token,
			memberBlock: memberBlock
		)
	}

	static func makeVariable(with configuration: Configuration.Action) -> VariableDeclSyntax {

		let identifier = IdentifierPatternSyntax(identifier: .identifier(configuration.variable))

		let actionType = IdentifierTypeSyntax(name: configuration.token)

		let type = TypeAnnotationSyntax(
			colon: .colonToken(),
			type: ArrayTypeSyntax(element: actionType)
		)

		let array = ArrayExprSyntax(elements: [])
		let initializer = InitializerClauseSyntax(value: array)

		let pattern = PatternBindingSyntax(
			pattern: identifier,
			typeAnnotation: type,
			initializer: initializer
		)

		let detail = DeclModifierDetailSyntax(leftParen: .leftParenToken(), detail: .identifier("set"), rightParen: .rightParenToken())
		let modifier = DeclModifierSyntax(name: .keyword(.private), detail: detail)

		return VariableDeclSyntax(
			modifiers: DeclModifierListSyntax([modifier]),
			bindingSpecifier: .keyword(.var),
			bindings: PatternBindingListSyntax([pattern])
		)
	}
}
