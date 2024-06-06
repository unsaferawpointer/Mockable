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

		let implementations = createProtocolImplementation(for: functions, with: DataFactory().makeData(from: functions))

		var members = MemberBlockItemListSyntax()
		members.append(MemberBlockItemSyntax(decl: ActionFactory.makeVariable(with: configuration.action)))
		members.append(MemberBlockItemSyntax(decl: StubFactory.makeVariable(with: configuration.stub)))
		members.append(MemberBlockItemSyntax(decl: ErrorsFactory.makeVariable(with: configuration.errors)))


		members.append(MemberBlockItemSyntax(decl: ActionFactory.makeEnum(from: functions, with: configuration.action)))
		members.append(MemberBlockItemSyntax(decl: StubFactory.makeStubs(for: functions, with:  DataFactory().makeData(from: functions))))
		members.append(MemberBlockItemSyntax(decl: ErrorsFactory.makeStruct(for: functions, with:  DataFactory().makeData(from: functions))))

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

extension MockableMacro {

	static func makeInheritanceClause(_ target: ProtocolDeclSyntax) -> InheritanceClauseSyntax {
		let type = InheritedTypeSyntax(type: IdentifierTypeSyntax(name: target.name))
		return InheritanceClauseSyntax(inheritedTypes: .init([type]))
	}

	static func hasStubs(for functions: [FunctionDeclSyntax]) -> Bool {
		return functions.contains {
			$0.signature.returnClause != nil
		}
	}

	static func createProtocolImplementation(for functions: [FunctionDeclSyntax], with data: MacrosData) -> [FunctionDeclSyntax] {

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
				body.append(makeIfBlock(for: function, with: data))
			}

			if function.signature.returnClause != nil {

				if function.signature.returnClause?.type.is(OptionalTypeSyntax.self) == false {
					body.append(makeGuardBlock(for: function, with: data))

					let declReferenceSyntax = DeclReferenceExprSyntax(baseName: .identifier("stub"))

					let returnSyntax = ReturnStmtSyntax(
						returnKeyword: .keyword(.return),
						expression: declReferenceSyntax
					)

					body.append(CodeBlockItemSyntax(item: .stmt(StmtSyntax(returnSyntax))))
				} else {
					let declReferenceSyntax = DeclReferenceExprSyntax(baseName: .identifier("stubs"))

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

	static func makeGuardBlock(for function: FunctionDeclSyntax, with data: MacrosData) -> CodeBlockItemSyntax {

		let identifierPattern = IdentifierPatternSyntax(identifier: .identifier("stub"))

		let stubs = DeclReferenceExprSyntax(baseName: .identifier("stubs"))
		let functionCall = DeclReferenceExprSyntax(baseName: data[function.signature].name)

		let memberAccessExprSyntax = MemberAccessExprSyntax(base: stubs, period: .periodToken(), declName: functionCall)

		let initializer = InitializerClauseSyntax(
			equal: .equalToken(), value: memberAccessExprSyntax)

		let condition = OptionalBindingConditionSyntax(bindingSpecifier: .keyword(.let), pattern: identifierPattern, initializer: initializer)

		let conditionElement = ConditionElementSyntax(condition: .optionalBinding(condition))
		let conditionElementListSyntax = ConditionElementListSyntax([conditionElement])
		let guardStmtSyntax = GuardStmtSyntax(
			guardKeyword: .keyword(.guard),
			conditions: conditionElementListSyntax,
			elseKeyword: .keyword(.else),
			body: makeElseBlock()
		)

		return CodeBlockItemSyntax(item: .init(guardStmtSyntax))
	}

	static func makeElseBlock() -> CodeBlockSyntax {
		let function = DeclReferenceExprSyntax(baseName: .identifier("fatalError"))
		let funtionCall = FunctionCallExprSyntax(
			calledExpression: function,
			leftParen: .leftParenToken(),
			arguments: .init([]),
			rightParen: .rightParenToken(),
			additionalTrailingClosures: .init([])
		)
		let item = CodeBlockItemSyntax(item: .init(funtionCall))
		let statements = CodeBlockItemListSyntax([item])
		return CodeBlockSyntax(statements: statements)
	}

	static func makeIfBlock(for function: FunctionDeclSyntax, with data: MacrosData) -> CodeBlockItemSyntax {
		let identifierPattern = IdentifierPatternSyntax(identifier: .identifier("error"))

		let errors = DeclReferenceExprSyntax(baseName: .identifier("errors"))
		let functionCall = DeclReferenceExprSyntax(baseName: data[function.signature].name)

		let memberAccessExprSyntax = MemberAccessExprSyntax(base: errors, period: .periodToken(), declName: functionCall)

		let initializer = InitializerClauseSyntax(
			equal: .equalToken(), value: memberAccessExprSyntax)

		let condition = OptionalBindingConditionSyntax(bindingSpecifier: .keyword(.let), pattern: identifierPattern, initializer: initializer)

		let conditionElement = ConditionElementSyntax(condition: .optionalBinding(condition))
		let conditionElementListSyntax = ConditionElementListSyntax([conditionElement])

		let expression = IfExprSyntax(
			ifKeyword: .keyword(.if),
			conditions: conditionElementListSyntax,
			body: makeIfBlockInside()
		)

		let item = ExpressionStmtSyntax(expression: expression)

		return CodeBlockItemSyntax(item: .init(item))
	}

	static func makeIfBlockInside() -> CodeBlockSyntax {

		let expression = DeclReferenceExprSyntax(baseName: .identifier("error"))
		let throwStmt = ThrowStmtSyntax(expression: expression)
		let item = CodeBlockItemSyntax(item: .init(throwStmt))
		let statements = CodeBlockItemListSyntax([item])
		return CodeBlockSyntax(statements: statements)
	}
}

@main
struct MockablePlugin: CompilerPlugin {
	let providingMacros: [Macro.Type] = [
		MockableMacro.self,
	]
}
