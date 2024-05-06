//
//  Configuration.swift
//
//
//  Created by Anton Cherkasov on 12.05.2024.
//

import SwiftSyntax

struct Configuration {

	private (set) var action: Action

	private (set) var stub: Stub

	init(action: Action, stub: Stub) {
		self.action = action
		self.stub = stub
	}
}

extension Configuration {

	struct Action {
		let type: String
		let variable: String
	}

	struct Stub {
		let type: String
		let variable: String
	}
}

// MARK: - Computed properties for Stub
extension Configuration.Stub {

	var token: TokenSyntax {
		return .identifier(type)
	}
}

// MARK: - Computed properties for Action
extension Configuration.Action {

	var token: TokenSyntax {
		return .identifier(type)
	}
}
