//
//  StubFactory.swift
//  
//
//  Created by Anton Cherkasov on 26.05.2024.
//

import SwiftSyntax

final class StubFactory {

}

extension StubFactory {

	static func makeVariable(with configuration: Configuration.Stub) -> VariableDeclSyntax {

		let identifier = IdentifierPatternSyntax(identifier: .identifier(configuration.variable))

		let stubType = IdentifierTypeSyntax(name: configuration.token)

		let type = TypeAnnotationSyntax(
			colon: .colonToken(),
			type: stubType
		)

		let rightSide = FunctionCallExprSyntax(
			calledExpression: DeclReferenceExprSyntax(baseName: .identifier("Stubs")),
			leftParen: .leftParenToken(),
			arguments: LabeledExprListSyntax([]),
			rightParen: .rightParenToken(),
			additionalTrailingClosures: MultipleTrailingClosureElementListSyntax { }
		)
		let initializer = InitializerClauseSyntax(equal: .equalToken(), value: rightSide)

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
