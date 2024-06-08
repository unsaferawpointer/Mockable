import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct MockableMacro: PeerMacro {

	public static func expansion(
		of node: AttributeSyntax,
		providingPeersOf declaration: some DeclSyntaxProtocol,
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		guard let protocolDeclaration = declaration.as(ProtocolDeclSyntax.self) else {
			throw MockableError.isNotAProtocol
		}

		// MARK: - Start configuration

		let configuration = Configuration(
			action: .init(type: "Action", variable: "invocations"),
			stub: .init(type: "Stubs", variable: "stubs"), 
			errors: .init(type: "Errors", variable: "errors")
		)

		// MARK: - End configuration

		let protocolMembers = protocolDeclaration.memberBlock.members

		let functions: [FunctionDeclSyntax] = protocolMembers.compactMap { $0.decl.as(FunctionDeclSyntax.self) }

		let implementations = createProtocolImplementation(for: functions, with: DataFactory().makeData(from: functions), configuration: configuration)

		let data = DataFactory().makeData(from: functions)

		var members = MemberBlockItemListSyntax()

		// MARK: - Actions support

		members.append(MemberBlockItemSyntax(decl: ActionsFactory.makeVariable(with: configuration.action)))
		members.append(MemberBlockItemSyntax(decl: ActionsFactory.makeStruct(from: functions, with: configuration.action)))

		// MARK: - Errors support

		if let errorStruct = ErrorsFactory.makeStruct(for: functions, with: data, configuration: configuration.errors) {
			let structMember = MemberBlockItemSyntax(decl: errorStruct)
			members.append(structMember)

			let variable = ErrorsFactory.makeVariable(with: configuration.errors)
			let variableMember = MemberBlockItemSyntax(decl: variable)
			members.append(variableMember)
		}

		// MARK: - Stubs support

		if let stub = StubsFactory.makeStruct(for: functions, with: data, configuration: configuration.stub) {
			let structMember = MemberBlockItemSyntax(decl: stub)
			members.append(structMember)

			let variable = StubsFactory.makeVariable(with: configuration.stub)
			let variableMember = MemberBlockItemSyntax(decl: variable)
			members.append(variableMember)
		}

		for implementation in implementations {
			members.append(MemberBlockItemSyntax(decl: implementation))
		}

		let memberBlock = MemberBlockSyntax(members: members)

		let mock = ClassDeclSyntax(
			modifiers: .init(itemsBuilder: {
				[DeclModifierSyntax(name: .keyword(.final))]
			}),
			name: .identifier("\(protocolDeclaration.name.text)Mock"),
			inheritanceClause: makeInheritanceClause(protocolDeclaration),
			memberBlock: memberBlock
		)

		return [mock.cast(DeclSyntax.self)]
	}
}

// MARK: - Helpers
private extension MockableMacro {

	static func makeInheritanceClause(_ target: ProtocolDeclSyntax) -> InheritanceClauseSyntax {
		let type = InheritedTypeSyntax(type: IdentifierTypeSyntax(name: target.name))
		return InheritanceClauseSyntax(inheritedTypes: .init([type]))
	}

	static func hasStubs(for functions: [FunctionDeclSyntax]) -> Bool {
		return functions.contains {
			$0.signature.returnClause != nil
		}
	}

	static func createProtocolImplementation(for functions: [FunctionDeclSyntax], with data: MacrosData, configuration: Configuration) -> [FunctionDeclSyntax] {

		var result: [FunctionDeclSyntax] = []
		for function in functions {

			let caseWrapper = data[function.signature]

			let memberAccess2 = MemberAccessExprSyntax(
				declName: DeclReferenceExprSyntax(
					baseName: caseWrapper.name,
					argumentNames: nil
				)
			)

			var labeledExprListSyntax2 = LabeledExprListSyntax()

			for parameter in caseWrapper.parameters {
				let label = LabeledExprSyntax(
					label: parameter.name,
					colon: .colonToken(),
					expression: DeclReferenceExprSyntax(baseName: parameter.name),
					trailingComma: parameter.isLast ? nil : .commaToken()
				)
				labeledExprListSyntax2.append(label)
			}

			let functionCallExpr = FunctionCallExprSyntax(
				calledExpression: memberAccess2,
				leftParen: caseWrapper.parameters.isEmpty ? nil : .leftParenToken(),
				arguments: labeledExprListSyntax2,
				rightParen: caseWrapper.parameters.isEmpty ? nil : .rightParenToken()
			)

			let lebeledExpr = LabeledExprSyntax(expression: functionCallExpr)

			let labeledExprList = LabeledExprListSyntax([lebeledExpr])

			let declName = DeclReferenceExprSyntax(baseName: .identifier("append"))
			let baseName = DeclReferenceExprSyntax(baseName: .identifier("invocations"))
			let memberAccess = MemberAccessExprSyntax(base: baseName, declName: declName)

			var body = CodeBlockItemListSyntax {
				FunctionCallExprSyntax(
					calledExpression: memberAccess,
					leftParen: .leftParenToken(),
					arguments: labeledExprList,
					rightParen: .rightParenToken()
				)
			}

			if function.signature.effectSpecifiers?.throwsSpecifier != nil {
				body.append(ErrorsFactory.makeBlock(for: function, with: data, configuration: configuration.errors))
			}

			if function.signature.returnClause != nil {

				if function.signature.returnClause?.type.is(OptionalTypeSyntax.self) == false {
					body.append(StubsFactory.makeBlock(for: function, with: data, andConfiguration: configuration.stub))

					let declReferenceSyntax = DeclReferenceExprSyntax(baseName: .identifier("stub"))

					let returnSyntax = ReturnStmtSyntax(
						returnKeyword: .keyword(.return),
						expression: declReferenceSyntax
					)

					body.append(CodeBlockItemSyntax(item: .stmt(StmtSyntax(returnSyntax))))
				} else {
					let declReferenceSyntax = DeclReferenceExprSyntax(baseName: .identifier(configuration.stub.variable))

					let declReferenceSyntax2 = DeclReferenceExprSyntax(baseName: data[function.signature].name)

					let memberAccessExpr = MemberAccessExprSyntax(base: declReferenceSyntax,
																  period: .periodToken(),
																  declName: declReferenceSyntax2)

					let returnSyntax = ReturnStmtSyntax(
						returnKeyword: .keyword(.return),
						expression: memberAccessExpr
					)

					body.append(CodeBlockItemSyntax(item: .stmt(StmtSyntax(returnSyntax))))
				}
			}

			let function = FunctionDeclSyntax(
				name: function.name,
				signature: function.signature,
				body: CodeBlockSyntax(statements: body)
			)
			result.append(function)
		}

		return result
	}
}

extension MockableMacro {


}

@main
struct MockablePlugin: CompilerPlugin {
	let providingMacros: [Macro.Type] = [
		MockableMacro.self,
	]
}
