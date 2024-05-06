//
//  MockableError.swift
//
//
//  Created by Anton Cherkasov on 05.05.2024.
//

import Foundation

enum MockableError: Error {
	case isNotAProtocol
}

// MARK: - CustomStringConvertible
extension MockableError: CustomStringConvertible {

	var description: String {
		switch self {
		case .isNotAProtocol:
			"@Mockable can only be applied to protocols."
		}
	}
}
