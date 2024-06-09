//
//  MockableError.swift
//
//
//  Created by Anton Cherkasov on 05.05.2024.
//

import Foundation

enum MockableError: Error {
	case isNotAProtocol
	case protocolIsInherited
	case containsPrimaryAssociatedTypeClause
	case containsAssociatedTypeDeclSyntax
}

// MARK: - CustomStringConvertible
extension MockableError: CustomStringConvertible {

	var description: String {
		switch self {
		case .isNotAProtocol:
			"@Mockable can only be applied to protocols."
		case .protocolIsInherited:
			"@Mockable does not support inheritance"
		case .containsPrimaryAssociatedTypeClause:
			"@Mockable does not support primary associated type"
		case .containsAssociatedTypeDeclSyntax:
			"@Mockable does not support associated types"
		}
	}
}
