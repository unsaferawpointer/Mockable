
import Mockable

@MockableMacro
protocol MyTestProtocol {
	func functionWithoutParameters()
	func functionWithUnnamedParameters(_ value: Int)
	func functionWithParameters(_ value: Int, _ value2: inout String?)
	func functionWithParameters(value: String, value2 innerValue2: String) -> String
	func functionWithParametersHasOptionalReturnClause(value: String, value2 innerValue2: String) -> String?
	func functionWithCompletionBlock(_ block: @escaping () -> Void) async
	func functionWithCompletionBlock(_ block: @escaping () -> Void)
}

let mock = MyTestProtocolMock()
