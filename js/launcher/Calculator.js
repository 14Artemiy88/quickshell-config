.pragma library

// A deliberately small arithmetic parser. It never evaluates the user's text
// as JavaScript, and rejects names, function calls and any unknown characters.
function evaluate(expression) {
    var displayExpression = String(expression === undefined || expression === null ? "" : expression).trim()
    if (displayExpression.length === 0 || displayExpression.length > 128)
        return null
    // Accept typographic operators and a decimal comma as well as ASCII keyboard keys.
    // Commas are decimal separators only; thousands separators and argument lists
    // are deliberately unsupported to keep the grammar unambiguous.
    var source = displayExpression
        .replace(/[−–]/g, "-")
        .replace(/×/g, "*")
        .replace(/÷/g, "/")
        .replace(/,/g, ".")
    if (!/^[0-9+\-*/%^().\s]+$/.test(source))
        return null

    var position = 0
    function skipSpaces() {
        while (position < source.length && /\s/.test(source.charAt(position)))
            position++
    }

    function parsePrimary() {
        skipSpaces()
        if (source.charAt(position) === "(") {
            position++
            var nested = parseAddSub()
            skipSpaces()
            if (source.charAt(position) !== ")")
                return null
            position++
            return nested
        }

        var start = position
        var dots = 0
        var digits = 0
        while (position < source.length) {
            var ch = source.charAt(position)
            if (ch >= "0" && ch <= "9") {
                digits++
                position++
            } else if (ch === ".") {
                dots++
                position++
                if (dots > 1)
                    return null
            } else {
                break
            }
        }
        if (digits === 0)
            return null
        var value = Number(source.slice(start, position))
        return isFinite(value) ? value : null
    }

    function parsePower() {
        var left = parsePrimary()
        if (left === null)
            return null
        skipSpaces()
        if (source.charAt(position) !== "^")
            return left
        position++
        var right = parseUnary()
        if (right === null)
            return null
        var value = Math.pow(left, right)
        return isFinite(value) ? value : null
    }

    function parseUnary() {
        skipSpaces()
        var ch = source.charAt(position)
        if (ch === "+") {
            position++
            return parseUnary()
        }
        if (ch === "-") {
            position++
            var negated = parseUnary()
            return negated === null ? null : -negated
        }
        return parsePower()
    }

    function parseMultiplyDivide() {
        var value = parseUnary()
        if (value === null)
            return null
        while (true) {
            skipSpaces()
            var op = source.charAt(position)
            if (op !== "*" && op !== "/" && op !== "%")
                return value
            position++
            var right = parseUnary()
            if (right === null)
                return null
            if ((op === "/" || op === "%") && right === 0)
                return null
            if (op === "*") value *= right
            else if (op === "/") value /= right
            else value %= right
            if (!isFinite(value))
                return null
        }
    }

    function parseAddSub() {
        var value = parseMultiplyDivide()
        if (value === null)
            return null
        while (true) {
            skipSpaces()
            var op = source.charAt(position)
            if (op !== "+" && op !== "-")
                return value
            position++
            var right = parseMultiplyDivide()
            if (right === null)
                return null
            value = op === "+" ? value + right : value - right
            if (!isFinite(value))
                return null
        }
    }

    var result = parseAddSub()
    skipSpaces()
    if (result === null || position !== source.length || !isFinite(result) || Math.abs(result) > 1e100)
        return null

    if (result === 0)
        result = 0
    var formatted = Number.isInteger(result) && Math.abs(result) < 1e16
        ? String(result)
        : String(Number(result.toPrecision(12)))
    return { value: result, text: formatted, expression: displayExpression }
}

function hasOperators(expression) {
    var source = String(expression === undefined || expression === null ? "" : expression).trim()
    return source.length > 0 && /[+\-*/%^()×÷−–]/.test(source)
}
