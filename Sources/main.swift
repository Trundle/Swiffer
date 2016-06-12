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
}

internal let _singleLineComment: Parser<String.UnicodeScalarView, Token> =
    { a in { b in Token.Comment(String(a + b)) } } <^> literal("//") <*> manyTill(anyChar, endOfLine)

internal let _multiLineComment: Parser<String.UnicodeScalarView, Token> =
    literal("/*") *> fix { recur in { stillOpen in
        manyTill(anyChar, literal("*/")) >>- { (comment: String.UnicodeScalarView) in
            var comment = comment + "*/".unicodeScalars
            var nested = stillOpen
            var prev: UnicodeScalar? = nil
            for char in comment {
                if char == "*" && prev == "/" {
                    nested += 1
                }
                prev = char
            }
            if (nested > 0) {
                return { a in { a + $0 } } <^> pure(comment) <*> recur(stillOpen)
            }
            return pure(comment)
        }
    }}(0) <&> { (c: String.UnicodeScalarView) in Token.Comment("/*" + String(c)) }

internal let comment: Parser<String.UnicodeScalarView, Token> =
    _singleLineComment <|> _multiLineComment

print(parse(comment, "/* This is another \n comment /* nested /* Even more */ nested */ */".unicodeScalars))
