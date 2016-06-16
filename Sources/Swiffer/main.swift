///
/// Swiffer
/// =======
///
/// A Git pre-commit hook for ensuring a minimal amount of documentation quality
/// for Swift code.
///
/// - author: Andreas Stührk <andy@hammerhartes.de>
///

import Checkers
import Core

let against = try headExists() ? "HEAD" : emptyTree
let diff = try getDiff(against)
print(diff)

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
