//
//  ErrorsFactory.swift
//
//
//  Created by Anton Cherkasov on 06.06.2024.
//

import SwiftSyntax

protocol ErrorsFactoryProtocol {
	static func makeVariable(with configuration: Configuration.Errors) -> VariableDeclSyntax
}

final class ErrorsFactory {

}

// MARK: - ErrorsFactoryProtocol
extension ErrorsFactory: ErrorsFactoryProtocol {

	static func makeStruct(
		for functions: [FunctionDeclSyntax],
		with data: MacrosData,
		configuration: Configuration.Errors
	) -> StructDeclSyntax {

		var result: [VariableDeclSyntax] = []

		for function in functions {

			guard function.signature.effectSpecifiers?.throwsSpecifier != nil else {
				continue
			}

			let name = data[function.signature].name
			let identifier = IdentifierPatternSyntax(identifier: name)

			let typeAnnotation = TypeAnnotationSyntax(
				colon: .colonToken(),
				type: OptionalTypeSyntax(wrappedType: IdentifierTypeSyntax(name: .identifier("Error")))
			)

			let pattern = PatternBindingSyntax(
				pattern: identifier,
				typeAnnotation: typeAnnotation
			)

			let variable = VariableDeclSyntax(
				modifiers: DeclModifierListSyntax([]),
				bindingSpecifier: .keyword(.var),
				bindings: PatternBindingListSyntax([pattern])
			)
			result.append(variable)
		}

		let memberBlockItemList = MemberBlockItemListSyntax(
			result.map {
				MemberBlockItemSyntax(decl: $0)
			}
		)
		let memberBlock = MemberBlockSyntax(members: memberBlockItemList)

		return StructDeclSyntax(
			structKeyword: .keyword(.struct),
			name: configuration.token,
			memberBlock: memberBlock
		)
	}

	static func makeVariable(with configuration: Configuration.Errors) -> VariableDeclSyntax {

		let identifier = IdentifierPatternSyntax(identifier: .identifier(configuration.variable))

		let errorsType = IdentifierTypeSyntax(name: configuration.token)

		let type = TypeAnnotationSyntax(type: errorsType)

		let functionCallExprSyntax = FunctionCallExprSyntax(
			calledExpression: DeclReferenceExprSyntax(baseName: .identifier(configuration.type)),
			leftParen: .leftParenToken(),
			arguments: LabeledExprListSyntax([]),
			rightParen: .rightParenToken(),
			additionalTrailingClosures: MultipleTrailingClosureElementListSyntax { }
		)
		let initializer = InitializerClauseSyntax(value: functionCallExprSyntax)

		let pattern = PatternBindingSyntax(
			pattern: identifier,
			typeAnnotation: type,
			initializer: initializer
		)

		return VariableDeclSyntax(
			modifiers: DeclModifierListSyntax([]),
			bindingSpecifier: .keyword(.var),
			bindings: PatternBindingListSyntax([pattern])
		)
	}
}
