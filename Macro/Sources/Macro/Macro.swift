// The Swift Programming Language
// https://docs.swift.org/swift-book

import AsyncReactor

/// A macro that produces both a value and a string containing the
/// source code that generated the value. For example,
///
///     #stringify(x + y)
///
/// produces a tuple `(x + y, "x + y")`.
@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(module: "MacroMacros", type: "StringifyMacro")

@attached(extension, conformances: AsyncReactor)
@attached(member, names: named(state))
@attached(peer, names: suffixed(View))
public macro Reactor() = #externalMacro(module: "MacroMacros", type: "ReactorMacro")

//@attached(member, names: named(_$backingData), named(backingData), named(schemaMetadata), named(`init`), named(_$observationRegistrar)) @attached(memberAttribute) @attached(conformance) public macro Model() = #externalMacro(module: "SwiftDataMacros", type: "PersistentModelMacro")
