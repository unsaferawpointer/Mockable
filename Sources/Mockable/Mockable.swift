// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(peer, names: suffixed(Mock))
public macro MockableMacro() = #externalMacro(module: "MockableMacros", type: "MockableMacro")

