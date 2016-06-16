// Part of this code is taken from TryParsec by Yasuhiro Inami, released under a MIT license
// Copyright (c) 2016 Yasuhiro Inami
//
// See also https://github.com/inhabitedtype/angstrom

/// The parser framework to implement the parsers for the micro-grammars

infix operator >>-  { associativity left precedence 100 }
infix operator <^>  { associativity left precedence 140 }
infix operator <&>  { associativity left precedence 140 }
infix operator <|>  { associativity right precedence 130 }
infix operator <*>  { associativity left precedence 140 }
infix operator *>   { associativity left precedence 140 }
infix operator <*   { associativity left precedence 140 }


/// Represents values with two possibilities:either `Left LeftType` or `Right RightType`.
public enum Either<LeftType, RightType> {
    case Left(LeftType)
    case Right(RightType)
}


/// Either `(remaining input, error message)` or `(remaining input, output)`
public typealias Result<In, Out> = Either<(In, String), (In, Out)>

public class Parser<In, Out> {
    private let _parse: (In) -> Result<In, Out>

    public init(_ parse: (In) -> Result<In, Out>) {
        self._parse = parse
    }
}

/// Runs the given parser `p`.
public func parse<In, Out>(_ p: Parser<In, Out>, _ input: In) -> Result<In, Out> {
    return p._parse(input)
}

/// Alternation, choice.
/// Uses `q` only if `p` failed.
public func <|> <In, Out>(p: Parser<In, Out>, q: @autoclosure(escaping) () -> Parser<In, Out>) -> Parser<In, Out> {
    return Parser { input in
        let result = parse(p, input)
        switch result {
        case .Left:
            return parse(q(), input)
        case .Right:
            return result
        }
    }
}

/// Lifts `output` to `Parser`.
public func pure<In, Out>(_ output: Out) -> Parser<In, Out> {
    return Parser { .Right($0, output) }
}

/// Haskell's `>>=` & Swift's `flatMap`.
public func >>- <In, Out1, Out2>(p: Parser<In, Out1>, f: ((Out1) -> Parser<In, Out2>)) -> Parser<In, Out2> {
    return Parser { input in
        switch parse(p, input) {
        case let .Left(input2, message):
            return .Left(input2, message)
        case let .Right(input2, output):
            return parse(f(output), input2)
        }
    }
}

/// Haskell's `<$>` or `fmap`, Swift's `map`.
public func <^> <In, Out1, Out2>(f: (Out1) -> Out2, p: Parser<In, Out1>) -> Parser<In, Out2> {
    return p >>- { a in pure(f(a)) }
}

/// Infix flipped fmap
public func <&> <In, Out1, Out2>(p: Parser<In, Out1>, f: (Out1) -> Out2) -> Parser<In, Out2> {
    return f <^> p
}

/// Sequential application.
public func <*> <In, Out1, Out2> (p: Parser<In, (Out1) -> Out2>, q: @autoclosure(escaping) () -> Parser<In, Out1>) -> Parser<In, Out2> {
    return p >>- { f in f <^> q() }
}

/// Sequence actions, discarding left (value of the first argument).
public func *> <In, Out1, Out2>(p: Parser<In, Out1>, q: @autoclosure(escaping) () -> Parser<In, Out2>) -> Parser<In, Out2> {
    return const(id) <^> p <*> q
}

/// Sequence actions, discarding right (value of the second argument).
public func <* <In, Out1, Out2>(p: Parser<In, Out1>, q: @autoclosure(escaping) () -> Parser<In, Out2>) -> Parser<In, Out1> {
    return const <^> p <*> q
}

extension Collection {
    /// Extracts head and tail of `Collection`, returning nil if it is empty.
    internal func uncons() -> (Iterator.Element, SubSequence)? {
        if let head = self.first {
            return (head, self.suffix(from: self.index(after: self.startIndex)))
        } else {
            return nil
        }
    }
}

/// A parser which parses one `UnicodeScalar` that passes `predicate`.
public func satisfy(_ predicate: (UnicodeScalar) -> Bool) -> Parser<String.UnicodeScalarView, UnicodeScalar> {
    return Parser { input in
        if let (head, tail) = input.uncons() where predicate(head) {
            return .Right(tail, head)
        } else {
            return .Left(input, "did not satisfy predicate")
        }
    }
}

/// Parses zero or more occurrences of `p`.
/// - Note: The returned parser never fails.
public func many<In, Out, Outs: RangeReplaceableCollection where Outs.Iterator.Element == Out>(_ p: Parser<In, Out>) -> Parser<In, Outs> {
    return many1(p) <|> pure(Outs())
}

/// Parses one or more occurrences of `p`.
public func many1<In, Out, Outs: RangeReplaceableCollection where Outs.Iterator.Element == Out>(_ p: Parser<In, Out>) -> Parser<In, Outs> {
    let insert: (Out) -> (Outs) -> Outs = { x in { xs in
        // XXX improve (copies a lot I think)
        var xs = xs
        xs.insert(x, at: xs.startIndex)
        return xs
    }}
    return insert <^> p <*> many(p)
}

/// Parses one or more occurrences of `p` until `end` succeeds,
/// and returns the list of values returned by `p`.
public func manyTill<In, Out, Out2, Outs: RangeReplaceableCollection where Outs.Iterator.Element == Out>(
    _ p: Parser<In, Out>,
    _ end: Parser<In, Out2>
) -> Parser<In, Outs> {
    let append: (Out) -> (Outs) -> Outs = { x in { xs in
        var xs = xs
        xs.append(x)
        return xs
    }}
    return fix { (recur: () -> Parser<In, Outs>) -> () -> Parser<In, Outs> in {
        (end *> pure(Outs())) <|> append <^> p <*> recur()
    }}() <&> { Outs($0.reversed()) }
}

/// Skips zero or more occurrences of `p`.
/// - Note: The returned parser never fails.
public func skipMany<In, Out>(_ p: Parser<In, Out>) -> Parser<In, ()> {
    return skipMany1(p) <|> pure(())
}

/// Skips one or more occurrences of `p`.
public func skipMany1<In, Out>(_ p: Parser<In, Out>) -> Parser<In, ()> {
    return p *> skipMany(p)
}

public func isSpace(_ c: UnicodeScalar) -> Bool {
    return c == " " || c == "\t" || c == "\n" || c == "\r"
}

/// Parses one `UnicodeScalar` which is in `[" ", "\t", "\n", "\r"]`.
public let space: Parser<String.UnicodeScalarView, UnicodeScalar> = satisfy(isSpace)

/// Skips zero or more occurrences of `space`.
public let skipSpaces: Parser<String.UnicodeScalarView, ()> = skipMany(space)

/// Matches '\n', '\r' or "\r\n".
public let endOfLine: Parser<String.UnicodeScalarView, String.UnicodeScalarView> =
    char("\n") *> pure("\n".unicodeScalars)
    <|> literal("\r\n")
    <|> char("\r") *> pure("\n".unicodeScalars)

/// Matches against one `UnicodeScalar` `c`.
public func char(_ c: UnicodeScalar) -> Parser<String.UnicodeScalarView, UnicodeScalar> {
    return satisfy { $0 == c }
}

/// Matches any char.
public let anyChar: Parser<String.UnicodeScalarView, UnicodeScalar> = satisfy(const(true))

/// Matches against the given literal `expected`.
public func literal(_ expected: String.UnicodeScalarView) -> Parser<String.UnicodeScalarView, String.UnicodeScalarView> {
    if let (head, tail) = expected.uncons() {
        return char(head) *> literal(tail) *> pure(expected)
    } else {
        // EOF
        return pure(String.UnicodeScalarView())
    }
}

/// Convenient overload for `literal`
public func literal(_ expected: String) -> Parser<String.UnicodeScalarView, String.UnicodeScalarView> {
    return literal(expected.unicodeScalars)
}

/// Applies `p` without consuming any input.
public func lookAhead<In, Out>(_ p: Parser<In, Out>) -> Parser<In, Out> {
    return Parser { input in
        let result = parse(p, input)
        switch result {
            case .Left:
                return result
            case let .Right(_, output):
                return .Right(input, output)
        }
    }
}

/// Parses `open`, followed by `p` and `close`. Returns the value returned by `p`.
public func between<In, Out1, Out2, Out>(
    _ p: Parser<In, Out>,
    _ open: Parser<In, Out1>,
    _ close: Parser<In, Out2>
) -> Parser<In, Out> {
    return open *> p <* close
}

public enum Nested<O, I, C> {
    case Open(O)
    case Inner(I)
    case Close(C)
}

/// Returns a parser that matches the same as `p`, but returns `()` and doesn't consume any input.
internal func _matchAndDiscard<In, Out>(_ p: Parser<In, Out>) -> Parser<In, ()> {
    return lookAhead(p) <&> const(())
}

/// Parses `open`, then zero or more occurrences of `p` and then `close`.
/// This sequence can be nested, as long as the occurrences of `open` and `closed` are balanced.
public func balanced<In, Out, OutOpen, OutClose,
                     Outs: RangeReplaceableCollection where Outs.Iterator.Element == Out>(
    _ p: Parser<In, Out>,
    _ open: Parser<In, OutOpen>,
    _ close: Parser<In, OutClose>
) -> Parser<In, [Nested<OutOpen, Outs, OutClose>]> {
    return { o in { [.Open(o)] + $0 } }
        <^> open <*> fix { (recur: () -> Parser<In, [Nested<OutOpen, Outs, OutClose>]>)
                            -> () -> Parser<In, [Nested<OutOpen, Outs, OutClose>]> in {
        close <&> { [.Close($0)] }
        <|> { o in { i in { [.Open(o)] + i + $0 } } } <^> open <*> recur() <*> recur()
        <|> { i in { [.Inner(i)] + $0 } }
            <^> manyTill(p, _matchAndDiscard(open) <|> _matchAndDiscard(close)) <*> recur()
    }}()
}
