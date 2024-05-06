//
//  MacrosData.swift
//
//
//  Created by Anton Cherkasov on 12.05.2024.
//

import SwiftSyntax

struct CaseWrapper {
	var name: TokenSyntax
	var parameters: [Parameter] = []
}

struct Parameter {
	var name: TokenSyntax
	var type: TypeSyntax
	var isLast: Bool
}

struct MacrosData {
	
	private (set) var map: [FunctionSignatureSyntax: Int]

	private (set) var cases: [CaseWrapper] = []

	// MARK: - Initialization

	init(map: [FunctionSignatureSyntax : Int], cases: [CaseWrapper]) {
		self.map = map
		self.cases = cases
	}
}

// MARK: - Subscripts
extension MacrosData {

	subscript(_ signature: FunctionSignatureSyntax) -> CaseWrapper {
		guard let index = map[signature] else {
			fatalError("Cant find case in map")
		}
		return cases[index]
	}
}
