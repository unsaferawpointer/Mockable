//
//  DataFactory.swift
//
//
//  Created by Anton Cherkasov on 13.05.2024.
//

import SwiftSyntax

final class DataFactory { }

extension DataFactory {
	
	func makeData(from functions: [FunctionDeclSyntax]) -> MacrosData {

		let nameResolver = NameResolver()

		var map: [FunctionSignatureSyntax: Int] = [:]
		var cases: [CaseWrapper] = []

		for (index, function) in functions.enumerated() {

			let newName = nameResolver.resolve(function.name)
			let parameters = makeParameters(from: function)

			let caseWrapper = CaseWrapper(
				name: newName,
				parameters: parameters
			)

			map[function.signature] = index
			cases.append(caseWrapper)
		}

		return MacrosData(map: map, cases: cases)
	}
}

// MARK: - Helpers
private extension DataFactory {

	func makeParameters(from function: FunctionDeclSyntax) -> [Parameter] {

		var result = [Parameter]()
		let parameters = function.signature.parameterClause.parameters

		let nameResolver = NameResolver()

		for (index, parameter) in parameters.enumerated() {

			let isLast = parameters.count - 1 == index

			let parameterName = nameResolver.resolve(parameter.usedName)

			// Skip attributes
			let type = parameter.type.as(AttributedTypeSyntax.self)?.baseType ?? parameter.type

			let element = Parameter(
				name: parameterName,
				type: type,
				isLast: isLast
			)

			result.append(element)
		}

		return result
	}
}
