import Foundation

// MARK: - Rational Numbers

public struct Rational: Equatable, Comparable, Hashable, CustomStringConvertible, Sendable {
    public let num: Int64
    public let den: Int64

    public init(_ num: Int64, _ den: Int64 = 1) {
        guard den != 0 else {
            self.num = num
            self.den = 1
            return
        }
        let g = Rational.gcd(abs(num), abs(den))
        let sign: Int64 = den < 0 ? -1 : 1
        self.num = (num / g) * sign
        self.den = abs(den) / g
    }

    public static let zero = Rational(0, 1)
    public static let one = Rational(1, 1)

    public var isZero: Bool { num == 0 }

    public func toDouble() -> Double {
        Double(num) / Double(den)
    }

    public var description: String {
        if den == 1 { return "\(num)" }
        return "\(num)/\(den)"
    }

    public static func gcd(_ a: Int64, _ b: Int64) -> Int64 {
        var x = a, y = b
        while y != 0 {
            let t = y
            y = x % y
            x = t
        }
        return max(1, x)
    }

    public static func lcm(_ a: Int64, _ b: Int64) -> Int64 {
        guard a != 0, b != 0 else { return 0 }
        return abs(a * b) / gcd(a, b)
    }

    public static func < (lhs: Rational, rhs: Rational) -> Bool {
        lhs.num * rhs.den < rhs.num * lhs.den
    }

    public static func + (lhs: Rational, rhs: Rational) -> Rational {
        let n = lhs.num * rhs.den + rhs.num * lhs.den
        let d = lhs.den * rhs.den
        return Rational(n, d)
    }

    public static prefix func - (val: Rational) -> Rational {
        Rational(-val.num, val.den)
    }

    public static func - (lhs: Rational, rhs: Rational) -> Rational {
        lhs + (-rhs)
    }

    public static func * (lhs: Rational, rhs: Rational) -> Rational {
        Rational(lhs.num * rhs.num, lhs.den * rhs.den)
    }

    public static func / (lhs: Rational, rhs: Rational) -> Rational? {
        guard rhs.num != 0 else { return nil }
        return Rational(lhs.num * rhs.den, lhs.den * rhs.num)
    }
}

// MARK: - Exact Multi-Term Symbolic Value

public struct ExactValue: Equatable, Sendable {
    /// Mapping of square-free radicand -> rational coefficient.
    /// Radicand 1 corresponds to pure rational term.
    public var surdTerms: [Int64: Rational]
    public var piCoeff: Rational

    public init(surdTerms: [Int64: Rational] = [:], piCoeff: Rational = .zero) {
        var cleaned: [Int64: Rational] = [:]
        for (rad, coeff) in surdTerms where !coeff.isZero {
            cleaned[rad] = coeff
        }
        self.surdTerms = cleaned
        self.piCoeff = piCoeff
    }

    public static let zero = ExactValue()

    public var isZero: Bool {
        surdTerms.isEmpty && piCoeff.isZero
    }

    public static func rational(_ r: Rational) -> ExactValue {
        if r.isZero { return .zero }
        return ExactValue(surdTerms: [1: r])
    }

    public static func surd(coeff: Rational = Rational(1, 1), radicand: Int64) -> ExactValue {
        guard radicand > 0 else { return .zero }
        let (outside, inside) = squareFreeFactor(radicand)
        let totalCoeff = coeff * Rational(outside, 1)
        if inside == 1 {
            return .rational(totalCoeff)
        }
        return ExactValue(surdTerms: [inside: totalCoeff])
    }

    public static func piMultiple(_ r: Rational) -> ExactValue {
        ExactValue(piCoeff: r)
    }

    // MARK: - Radical Simplification Helper

    public static func squareFreeFactor(_ n: Int64) -> (outside: Int64, inside: Int64) {
        guard n > 0 else { return (1, n) }
        var rem = n
        var outside: Int64 = 1
        var inside: Int64 = 1

        var d: Int64 = 2
        while d * d <= rem {
            var count = 0
            while rem % d == 0 {
                count += 1
                rem /= d
            }
            if count >= 2 {
                for _ in 0..<(count / 2) {
                    outside *= d
                }
            }
            if count % 2 == 1 {
                inside *= d
            }
            d += (d == 2 ? 1 : 2)
        }
        if rem > 1 {
            inside *= rem
        }
        return (outside, inside)
    }

    // MARK: - Conversions

    public func toDouble() -> Double {
        var sum = 0.0
        for (rad, coeff) in surdTerms {
            let root = rad == 1 ? 1.0 : Foundation.sqrt(Double(rad))
            sum += coeff.toDouble() * root
        }
        sum += piCoeff.toDouble() * Double.pi
        return sum
    }

    // MARK: - 2D MathAST Generation (for Natural-V.P.A.M. LCD display)

    public func toMathNodes() -> [MathNode] {
        if isZero {
            return [.text(id: UUID(), content: "0")]
        }

        // Collect all denominators to find a common denominator
        var dens: [Int64] = []
        for (_, coeff) in surdTerms {
            dens.append(coeff.den)
        }
        if !piCoeff.isZero {
            dens.append(piCoeff.den)
        }

        var commonDen: Int64 = 1
        for d in dens {
            commonDen = Rational.lcm(commonDen, d)
        }

        // Build numerator terms scaled by commonDen
        var numNodes: [MathNode] = []

        // Sort terms: rational first, then by radicand, then pi
        let sortedRadicands = surdTerms.keys.sorted { r1, r2 in
            if r1 == 1 { return false } // put radicals before rational or after? On Casio: (5√2)/6 or 1 + √2
            if r2 == 1 { return true }
            return r1 < r2
        }

        for (i, rad) in sortedRadicands.enumerated() {
            guard let coeff = surdTerms[rad] else { continue }
            let scaledNum = coeff.num * (commonDen / coeff.den)
            if scaledNum == 0 { continue }

            if i > 0 && !numNodes.isEmpty {
                let op = scaledNum >= 0 ? "+" : "−"
                numNodes.append(.text(id: UUID(), content: op))
            } else if scaledNum < 0 && numNodes.isEmpty {
                numNodes.append(.text(id: UUID(), content: "-"))
            }

            let absNum = abs(scaledNum)
            if rad == 1 {
                numNodes.append(.text(id: UUID(), content: "\(absNum)"))
            } else {
                if absNum != 1 {
                    numNodes.append(.text(id: UUID(), content: "\(absNum)"))
                }
                numNodes.append(.radical(id: UUID(), index: nil, radicand: [.text(id: UUID(), content: "\(rad)")]))
            }
        }

        if !piCoeff.isZero {
            let scaledNum = piCoeff.num * (commonDen / piCoeff.den)
            if scaledNum != 0 {
                if !numNodes.isEmpty {
                    let op = scaledNum >= 0 ? "+" : "−"
                    numNodes.append(.text(id: UUID(), content: op))
                } else if scaledNum < 0 {
                    numNodes.append(.text(id: UUID(), content: "-"))
                }
                let absNum = abs(scaledNum)
                if absNum != 1 {
                    numNodes.append(.text(id: UUID(), content: "\(absNum)"))
                }
                numNodes.append(.text(id: UUID(), content: "π"))
            }
        }

        if commonDen == 1 {
            return numNodes.isEmpty ? [.text(id: UUID(), content: "0")] : numNodes
        } else {
            return [.fraction(id: UUID(), num: numNodes, den: [.text(id: UUID(), content: "\(commonDen)")])]
        }
    }

    public func toLinearString() -> String {
        toMathNodes().map { $0.toLinearString() }.joined()
    }

    // MARK: - Arithmetic Operators

    public static func + (lhs: ExactValue, rhs: ExactValue) -> ExactValue {
        var terms = lhs.surdTerms
        for (rad, rCoeff) in rhs.surdTerms {
            let lCoeff = terms[rad] ?? .zero
            let sum = lCoeff + rCoeff
            if sum.isZero {
                terms.removeValue(forKey: rad)
            } else {
                terms[rad] = sum
            }
        }
        let newPi = lhs.piCoeff + rhs.piCoeff
        return ExactValue(surdTerms: terms, piCoeff: newPi)
    }

    public static prefix func - (val: ExactValue) -> ExactValue {
        var terms: [Int64: Rational] = [:]
        for (rad, coeff) in val.surdTerms {
            terms[rad] = -coeff
        }
        return ExactValue(surdTerms: terms, piCoeff: -val.piCoeff)
    }

    public static func - (lhs: ExactValue, rhs: ExactValue) -> ExactValue {
        lhs + (-rhs)
    }

    public static func * (lhs: ExactValue, rhs: ExactValue) -> ExactValue {
        var resultTerms: [Int64: Rational] = [:]
        var resultPi: Rational = .zero

        // Distribute surd terms
        for (rad1, c1) in lhs.surdTerms {
            for (rad2, c2) in rhs.surdTerms {
                let prod = rad1 * rad2
                let (outside, inside) = squareFreeFactor(prod)
                let termCoeff = c1 * c2 * Rational(outside, 1)
                let existing = resultTerms[inside] ?? .zero
                let newC = existing + termCoeff
                if newC.isZero {
                    resultTerms.removeValue(forKey: inside)
                } else {
                    resultTerms[inside] = newC
                }
            }
        }

        // Multiply by pi terms
        if !lhs.piCoeff.isZero {
            if let rationalR = rhs.surdTerms[1], rhs.surdTerms.count == 1 {
                resultPi = resultPi + (lhs.piCoeff * rationalR)
            }
        }
        if !rhs.piCoeff.isZero {
            if let rationalL = lhs.surdTerms[1], lhs.surdTerms.count == 1 {
                resultPi = resultPi + (rhs.piCoeff * rationalL)
            }
        }

        return ExactValue(surdTerms: resultTerms, piCoeff: resultPi)
    }

    public static func / (lhs: ExactValue, rhs: ExactValue) -> ExactValue? {
        guard !rhs.isZero else { return nil }

        // Division by pure rational
        if rhs.surdTerms.count == 1, let q = rhs.surdTerms[1], rhs.piCoeff.isZero {
            var terms: [Int64: Rational] = [:]
            for (rad, coeff) in lhs.surdTerms {
                guard let divided = coeff / q else { return nil }
                terms[rad] = divided
            }
            guard let divPi = lhs.piCoeff / q else { return nil }
            return ExactValue(surdTerms: terms, piCoeff: divPi)
        }

        // Division by single surd: (c√d) -> multiply num and den by √d
        if rhs.surdTerms.count == 1, let (d, c) = rhs.surdTerms.first, rhs.piCoeff.isZero {
            let conjugate = ExactValue.surd(coeff: Rational(1, 1), radicand: d)
            let newNum = lhs * conjugate
            let newDen = c * Rational(d, 1) // c * d is rational!
            return newNum / ExactValue.rational(newDen)
        }

        return nil
    }
}

// MARK: - Exact Evaluator for AST Nodes

public enum ExactEvaluator {
    private enum ExactToken: Equatable {
        case val(ExactValue)
        case binaryOp(String, Int) // op, precedence
        case openParen
        case closeParen
    }

    public static func evaluate(nodes: [MathNode], angleUnit: AngleUnit = .deg) -> ExactValue? {
        guard !nodes.isEmpty else { return nil }
        var tokens: [ExactToken] = []

        var i = 0
        while i < nodes.count {
            let node = nodes[i]
            switch node {
            case .text(_, let content):
                let trimmed = content.trimmingCharacters(in: .whitespaces)
                if trimmed == "+" {
                    tokens.append(.binaryOp("+", 1))
                } else if trimmed == "-" || trimmed == "−" {
                    // Check if unary negation
                    var isUnary = false
                    if let last = tokens.last {
                        switch last {
                        case .binaryOp, .openParen: isUnary = true
                        default: isUnary = false
                        }
                    } else {
                        isUnary = true
                    }
                    if isUnary {
                        tokens.append(.val(.zero))
                        tokens.append(.binaryOp("-", 1))
                    } else {
                        tokens.append(.binaryOp("-", 1))
                    }
                } else if trimmed == "×" || trimmed == "*" {
                    tokens.append(.binaryOp("×", 2))
                } else if trimmed == "÷" || trimmed == "/" {
                    tokens.append(.binaryOp("÷", 2))
                } else if trimmed == "π" {
                    if let last = tokens.last, canImplicitMultiply(last) {
                        tokens.append(.binaryOp("×", 3)) // Casio precedence 3 for implicit
                    }
                    tokens.append(.val(.piMultiple(Rational(1, 1))))
                } else if trimmed.allSatisfy({ ($0 >= "0" && $0 <= "9") || $0 == "." }) {
                    var numStr = trimmed
                    while i + 1 < nodes.count {
                        if case .text(_, let nextContent) = nodes[i + 1] {
                            let nextTrimmed = nextContent.trimmingCharacters(in: .whitespaces)
                            if !nextTrimmed.isEmpty && nextTrimmed.allSatisfy({ ($0 >= "0" && $0 <= "9") || $0 == "." }) {
                                numStr.append(nextTrimmed)
                                i += 1
                                continue
                            }
                        }
                        break
                    }
                    if let intVal = Int64(numStr) {
                        if let last = tokens.last, canImplicitMultiply(last) {
                            tokens.append(.binaryOp("×", 3))
                        }
                        tokens.append(.val(.rational(Rational(intVal, 1))))
                    } else if let dVal = Double(numStr), let frac = Fraction.fromDouble(dVal) {
                        if let last = tokens.last, canImplicitMultiply(last) {
                            tokens.append(.binaryOp("×", 3))
                        }
                        tokens.append(.val(.rational(Rational(frac.num, frac.den))))
                    } else {
                        return nil
                    }
                } else {
                    return nil
                }

            case .fraction(_, let num, let den):
                guard let numVal = evaluate(nodes: num, angleUnit: angleUnit),
                      let denVal = evaluate(nodes: den, angleUnit: angleUnit),
                      let res = numVal / denVal else {
                    return nil
                }
                if let last = tokens.last, canImplicitMultiply(last) {
                    tokens.append(.binaryOp("×", 3))
                }
                tokens.append(.val(res))

            case .radical(_, let index, let radicand):
                guard let radVal = evaluate(nodes: radicand, angleUnit: angleUnit) else { return nil }
                if let idx = index {
                    // Exact integer nth-root
                    guard let idxVal = evaluate(nodes: idx, angleUnit: angleUnit),
                          idxVal.surdTerms.count == 1, let idxQ = idxVal.surdTerms[1], idxVal.piCoeff.isZero, idxQ.den == 1, idxQ.num >= 2 else { return nil }
                    let n = idxQ.num
                    guard radVal.surdTerms.count == 1, let q = radVal.surdTerms[1], radVal.piCoeff.isZero, q.den == 1, q.num >= 0 else { return nil }
                    let radicandInt = q.num
                    let rootDouble = pow(Double(radicandInt), 1.0 / Double(n))
                    let rootRound = Int64(round(rootDouble))
                    var check: Int64 = 1
                    for _ in 0..<n { check *= rootRound }
                    if check == radicandInt {
                        if let last = tokens.last, canImplicitMultiply(last) {
                            tokens.append(.binaryOp("×", 3))
                        }
                        tokens.append(.val(.rational(Rational(rootRound, 1))))
                    } else {
                        return nil
                    }
                } else {
                    // Square root
                    if radVal.surdTerms.count == 1, let q = radVal.surdTerms[1], radVal.piCoeff.isZero, q > .zero {
                        // sqrt(num / den) = sqrt(num * den) / den
                        let prod = q.num * q.den
                        let (outside, inside) = ExactValue.squareFreeFactor(prod)
                        let coeff = Rational(outside, q.den)
                        let res = ExactValue.surd(coeff: coeff, radicand: inside)
                        if let last = tokens.last, canImplicitMultiply(last) {
                            tokens.append(.binaryOp("×", 3))
                        }
                        tokens.append(.val(res))
                    } else {
                        return nil
                    }
                }

            case .logBase(_, let base, let arg):
                guard let bVal = evaluate(nodes: base, angleUnit: angleUnit),
                      let aVal = evaluate(nodes: arg, angleUnit: angleUnit) else { return nil }
                guard bVal.surdTerms.count == 1, let bQ = bVal.surdTerms[1], bVal.piCoeff.isZero, bQ.den == 1, bQ.num > 1,
                      aVal.surdTerms.count == 1, let aQ = aVal.surdTerms[1], aVal.piCoeff.isZero, aQ.den == 1, aQ.num >= 1 else { return nil }
                let b = bQ.num
                let a = aQ.num
                var cur: Int64 = 1
                var exp: Int64 = 0
                while cur < a && exp < 60 {
                    cur *= b
                    exp += 1
                }
                if cur == a {
                    if let last = tokens.last, canImplicitMultiply(last) {
                        tokens.append(.binaryOp("×", 3))
                    }
                    tokens.append(.val(.rational(Rational(exp, 1))))
                } else {
                    return nil
                }

            case .exponent(_, let base, let power):
                guard let bVal = evaluate(nodes: base, angleUnit: angleUnit),
                      let pVal = evaluate(nodes: power, angleUnit: angleUnit) else { return nil }
                // Only integer powers supported exactly
                guard pVal.surdTerms.count == 1, let q = pVal.surdTerms[1], pVal.piCoeff.isZero, q.den == 1 else { return nil }
                let exp = q.num
                if exp == 0 {
                    tokens.append(.val(.rational(Rational(1, 1))))
                } else if exp > 0 {
                    var res = bVal
                    for _ in 1..<exp {
                        res = res * bVal
                    }
                    tokens.append(.val(res))
                } else {
                    var res = bVal
                    for _ in 1..<abs(exp) {
                        res = res * bVal
                    }
                    guard let inv = ExactValue.rational(Rational(1, 1)) / res else { return nil }
                    tokens.append(.val(inv))
                }

            case .parens(_, let children):
                if let last = tokens.last, canImplicitMultiply(last) {
                    tokens.append(.binaryOp("×", 3))
                }
                guard let val = evaluate(nodes: children, angleUnit: angleUnit) else { return nil }
                tokens.append(.val(val))

            case .function(_, let name, let arg):
                guard let argVal = evaluate(nodes: arg, angleUnit: angleUnit) else { return nil }
                guard let res = evaluateExactFunction(name: name, arg: argVal, angleUnit: angleUnit) else { return nil }
                if let last = tokens.last, canImplicitMultiply(last) {
                    tokens.append(.binaryOp("×", 3))
                }
                tokens.append(.val(res))

            default:
                return nil
            }
            i += 1
        }

        // Shunting-Yard on exact tokens
        return evaluateExactTokens(tokens)
    }

    private static func canImplicitMultiply(_ token: ExactToken) -> Bool {
        switch token {
        case .val, .closeParen: return true
        default: return false
        }
    }

    private static func evaluateExactFunction(name: String, arg: ExactValue, angleUnit: AngleUnit) -> ExactValue? {
        // Evaluate special angle trigonometric values
        guard arg.surdTerms.count == 1, let q = arg.surdTerms[1], arg.piCoeff.isZero else { return nil }
        var deg = q.toDouble()
        switch angleUnit {
        case .deg: break
        case .rad: deg = deg * 180.0 / .pi
        case .gra: deg = deg * 180.0 / 200.0
        }

        let normDeg = Int(round(deg))
        let sign: Int64 = normDeg < 0 ? -1 : 1
        let absDeg = abs(normDeg) % 360

        switch name {
        case "sin":
            if absDeg == 0 || absDeg == 180 { return .zero }
            if absDeg == 30 { return .rational(Rational(sign * 1, 2)) }
            if absDeg == 45 { return .surd(coeff: Rational(sign * 1, 2), radicand: 2) }
            if absDeg == 60 { return .surd(coeff: Rational(sign * 1, 2), radicand: 3) }
            if absDeg == 90 { return .rational(Rational(sign * 1, 1)) }
            if absDeg == 150 { return .rational(Rational(sign * 1, 2)) }
        case "cos":
            if absDeg == 0 { return .rational(Rational(1, 1)) }
            if absDeg == 30 || absDeg == 330 { return .surd(coeff: Rational(1, 2), radicand: 3) }
            if absDeg == 45 || absDeg == 315 { return .surd(coeff: Rational(1, 2), radicand: 2) }
            if absDeg == 60 || absDeg == 300 { return .rational(Rational(1, 2)) }
            if absDeg == 90 || absDeg == 270 { return .zero }
            if absDeg == 180 { return .rational(Rational(-1, 1)) }
        case "tan":
            if absDeg == 0 || absDeg == 180 { return .zero }
            if absDeg == 30 { return .surd(coeff: Rational(sign * 1, 3), radicand: 3) }
            if absDeg == 45 { return .rational(Rational(sign * 1, 1)) }
            if absDeg == 60 { return .surd(coeff: Rational(sign * 1, 1), radicand: 3) }
        default:
            break
        }
        return nil
    }

    private static func evaluateExactTokens(_ tokens: [ExactToken]) -> ExactValue? {
        var outputQueue: [ExactToken] = []
        var opStack: [ExactToken] = []

        for token in tokens {
            switch token {
            case .val:
                outputQueue.append(token)
            case .binaryOp(_, let prec1):
                while let top = opStack.last {
                    if case .binaryOp(_, let prec2) = top, prec2 >= prec1 {
                        outputQueue.append(opStack.removeLast())
                    } else {
                        break
                    }
                }
                opStack.append(token)
            case .openParen:
                opStack.append(token)
            case .closeParen:
                while let top = opStack.last, top != .openParen {
                    outputQueue.append(opStack.removeLast())
                }
                if opStack.last == .openParen {
                    opStack.removeLast()
                }
            }
        }

        while !opStack.isEmpty {
            outputQueue.append(opStack.removeLast())
        }

        // Evaluate RPN
        var evalStack: [ExactValue] = []
        for token in outputQueue {
            switch token {
            case .val(let v):
                evalStack.append(v)
            case .binaryOp(let op, _):
                guard evalStack.count >= 2 else { return nil }
                let r = evalStack.removeLast()
                let l = evalStack.removeLast()
                switch op {
                case "+": evalStack.append(l + r)
                case "-": evalStack.append(l - r)
                case "×": evalStack.append(l * r)
                case "÷":
                    guard let res = l / r else { return nil }
                    evalStack.append(res)
                default: return nil
                }
            default:
                return nil
            }
        }

        return evalStack.count == 1 ? evalStack[0] : nil
    }
}
