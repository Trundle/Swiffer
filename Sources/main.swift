///
/// Swiffer
/// =======
///
/// A Git pre-commit hook for ensuring a minimal amount of documentation quality
/// for Swift code.
///
/// - author: Andreas Stührk <andy@hammerhartes.de>
///

let against = try headExists() ? "HEAD" : emptyTree
let diff = try getDiff(against)
print(diff)


enum Token {
    case Comment(String)
    case StringLiteral(String)
    case Text(String)
}

internal let _singleLineComment: Parser<String.UnicodeScalarView, Token> =
    { a in { b in Token.Comment(String(a + b)) } } <^> literal("//") <*> manyTill(anyChar, endOfLine)

internal let _multiLineComment: Parser<String.UnicodeScalarView, Token> =
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

internal let comment: Parser<String.UnicodeScalarView, Token> =
    _singleLineComment <|> _multiLineComment

internal let string: Parser<String.UnicodeScalarView, Token> = {
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

internal let text: Parser<String.UnicodeScalarView, Token> =
    manyTill(anyChar, lookAhead(comment <|> string)) <&> { Token.Text(String($0)) }

internal let tokens: Parser<String.UnicodeScalarView, [Token]> =
    many(skipSpaces *> (comment <|> string <|> text))

internal func tokenize(_ input: String) -> [Token] {
    switch parse(tokens, input.unicodeScalars) {
    case .Left:
        return []
    case let .Right(remainingInput, tokens):
        return tokens + (remainingInput.isEmpty ? [] : [Token.Text(String(remainingInput))])
    }
}


var input = ""
var line: String? = nil
repeat {
    line = readLine(strippingNewline: false)
    if line != nil {
       input += line!
    }
} while line != nil

let tokenizedInput = tokenize(input)
let undocumented = publicFunctionsAreDocumented(tokenizedInput)
if !undocumented.isEmpty {
    print(":sadpanda: The following functions are undocumented: " + undocumented.joined(separator: ", "))
}
