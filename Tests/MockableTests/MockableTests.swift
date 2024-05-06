import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(MockableMacros)
import MockableMacros

let testMacros: [String: Macro.Type] = [
	"MockableMacro": MockableMacro.self,
]
#endif

final class MockableTests: XCTestCase {
	func testMacro() throws {
	#if canImport(MockableMacros)
		assertMacroExpansion(
			"""
			@MockableMacro
			protocol TestProtocol {
				func perform()
				var value: Int { get set } 
			}
			""",
			expandedSource: """
			(a + b, "a + b")
			""",
			macros: testMacros
		)
	#else
		throw XCTSkip("macros are only supported when running tests for the host platform")
	#endif
	}
}
