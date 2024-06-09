
import Mockable
import Foundation

@MockableMacro
protocol MyTestProtocol {

	func functionWithoutParameters(_ t: String)
	func functionWithUnnamedParameters(_ value: Int)
	func functionWithParameters(outerValue1 innerValue1: Int, _ innerValue2: inout String?) -> Int?
	func functionWithParameters(value1: String, outerValue2 innerValue2: String) -> Int
	func functionWithParametersHasOptionalReturnClause(value: String, value2 innerValue2: String) -> Double?
	func functionWithCompletionBlock(_ block: @escaping () -> Void) async -> UUID
	func functionWithCompletionBlock(_ block: @escaping () -> Void) throws
}

let mock = MyTestProtocolMock()
