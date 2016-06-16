public enum Token {
    case Comment(String)
    case StringLiteral(String)
    case Text(String)
}

private let _singleLineComment: Parser<String.UnicodeScalarView, Token> =
    { a in { b in Token.Comment(String(a + b)) } } <^> literal("//") <*> manyTill(anyChar, endOfLine)

private let _multiLineComment: Parser<String.UnicodeScalarView, Token> =
    balanced(anyChar, literal("/*"), literal("*/"))
    <&> fix { recur in { (node: Nested<String.UnicodeScalarView>) in
            switch node {
            case let .Leaf(comment):
                return "/*" + String(comment) + "*/"
            case let .Branch(.Leaf(left), .Leaf(right)):
                return "/*" + String(left) + "/*" + String(right) + "*/"
            case let .Branch(l, .Leaf(tail)):
                return recur(l) + String(tail) + "*/"
            case let .Branch(.Leaf(head), r):
                return "/*" + String(head) + recur(r)
            default:
                // Can't happen
                return ""
            }
        }}
    <&> { Token.Comment($0) }

private let comment: Parser<String.UnicodeScalarView, Token> =
    _singleLineComment <|> _multiLineComment

private let string: Parser<String.UnicodeScalarView, Token> = {
    let delimiter = literal("\"")
    let inner =
        literal("\\\\")
        <|>  literal("\\\"")
        <|> (anyChar <&> { String($0).unicodeScalars })
    let m: Parser<String.UnicodeScalarView, [String.UnicodeScalarView]> =
        manyTill(inner, delimiter)
    let parser =
        delimiter
        *> (m <&> { x in x.reduce(String.UnicodeScalarView(), combine: +) })
    return parser <&> { Token.StringLiteral(String($0)) }
}()

private let text: Parser<String.UnicodeScalarView, Token> =
    manyTill(anyChar, lookAhead(comment <|> string)) <&> { Token.Text(String($0)) }

private let tokens: Parser<String.UnicodeScalarView, [Token]> =
    many(skipSpaces *> (comment <|> string <|> text))

public func tokenize(_ input: String) -> [Token] {
    switch parse(tokens, input.unicodeScalars) {
    case .Left:
        return []
    case let .Right(remainingInput, tokens):
        return tokens + (remainingInput.isEmpty ? [] : [Token.Text(String(remainingInput))])
    }
}
