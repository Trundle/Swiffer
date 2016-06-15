/// The actual checkers

import Foundation

internal func pairwise<C: Collection>(_ c: C) -> Zip2Sequence<C, C.SubSequence> {
    return zip(c, c.dropFirst())
}

// XXX fix for operators ("public func <&> …")
private let publicFunc: Parser<String.UnicodeScalarView, String> =
    skipSpaces
    *> literal("public")
    *> space *> skipSpaces
    *> literal("func")
    *> space *> skipSpaces
    *> manyTill(anyChar, satisfy { $0 == "<" || $0 == "(" }) <&> { String($0) }

private func getAllPublicFunctionNames(_ text: String) -> [String] {
    let p: Parser<String.UnicodeScalarView, [Optional<String>]> =
        many(publicFunc <&> { .some($0) } <|> anyChar <&> const(.none))
    switch parse(p, text.unicodeScalars) {
        case let .Right(_, names):
            return names.flatMap { $0 }
        case .Left:
            // Can't happen (`many` never fails)
            return []
    }
}

/// Returns whether the given token is a documentation comment.
private func isDocComment(_ token: Token) -> Bool {
    switch token {
    case let .Comment(comment):
        return comment.hasPrefix("/**") || comment.hasPrefix("///")
    default:
        return false
    }
}

private func textToken(_ token: Token) -> String? {
    switch token {
    case let .Text(text):
        return text
    default:
        return nil
    }
}

internal func publicFunctionsAreDocumented(_ tokens: [Token]) -> [String] {
    var documented = 0
    var undocumented: [String] = []
    for (prev, token) in pairwise(tokens) {
        let text = textToken(token)
        if text != nil {
           let names =  getAllPublicFunctionNames(text!)
           if isDocComment(prev) {
              // XXX simplification: we assume any doc comment is for the first func
              documented += 1
              undocumented.append(contentsOf: names.dropFirst())
           } else {
              undocumented.append(contentsOf: names)
           }
        }
    }
    // XXX threshold with documented?
    return undocumented
}
