
import Mockable

@MockableMacro
protocol MyTestProtocol {
	func functionWithoutParameters()
	func functionWithUnnamedParameters(_ value: Int)
	func functionWithParameters(_ value: Int, _ value2: inout String?) -> Int?
	func functionWithParameters(value: String, value2 innerValue2: String) -> Int
	func functionWithParametersHasOptionalReturnClause(value: String, value2 innerValue2: String)
	func functionWithCompletionBlock(_ block: @escaping () -> Void) async
	func functionWithCompletionBlock(_ block: @escaping () -> Void) throws
}

let mock = MyTestProtocolMock()
