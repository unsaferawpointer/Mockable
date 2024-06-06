//
//  StubFactory.swift
//  
//
//  Created by Anton Cherkasov on 26.05.2024.
//

import SwiftSyntax

final class StubFactory { }

extension StubFactory {

	static func makeStubs(for functions: [FunctionDeclSyntax], with data: MacrosData) -> StructDeclSyntax {
		var result: [VariableDeclSyntax] = []

		for function in functions {

			guard let type = function.signature.returnClause?.type else {
				continue
			}

			let name = data[function.signature].name
			let identifier = IdentifierPatternSyntax(identifier: name)

			let resultType: TypeSyntaxProtocol = type.is(OptionalTypeSyntax.self) ? type : OptionalTypeSyntax(wrappedType: type)

			let typeAnnotation = TypeAnnotationSyntax(
				colon: .colonToken(),
				type: resultType
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
			name: .identifier("Stubs"),
			memberBlock: memberBlock
		)
	}

	static func makeVariable(with configuration: Configuration.Stub) -> VariableDeclSyntax {

		let identifier = IdentifierPatternSyntax(identifier: .identifier(configuration.variable))

		let stubType = IdentifierTypeSyntax(name: configuration.token)

		let type = TypeAnnotationSyntax(type: stubType)

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
