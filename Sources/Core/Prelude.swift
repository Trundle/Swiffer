/// The identity function.
public func id<A>(_ a: A) -> A {
    return a
}

/// The constant function.
public func const<A, B>(_ a: A) -> (B) -> A {
    return { _ in a }
}

/// Fixed-point combinator.
public func fix<T, U>(_ f: ((T) -> U) -> (T) -> U) -> (T) -> U {
    return { x in f(fix(f))(x) }
}
