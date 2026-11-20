import Foundation
#if canImport(Combine)
import Combine
public typealias ObservableObjectProtocol = ObservableObject
#else
public protocol ObservableObjectProtocol: AnyObject {}

@propertyWrapper
public struct Published<Value> {
    public var wrappedValue: Value
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
}
#endif

// MARK: - Enums & Models

public enum AngleUnit: String, CaseIterable, Sendable {
    case deg = "D"
    case rad = "R"
    case gra = "G"

    public func toRadians(_ val: Double) -> Double {
        switch self {
        case .deg: return val * .pi / 180.0
        case .rad: return val
        case .gra: return val * .pi / 200.0
        }
    }

    public func fromRadians(_ rad: Double) -> Double {
        switch self {
        case .deg: return rad * 180.0 / .pi
        case .rad: return rad
        case .gra: return rad * 200.0 / .pi
        }
    }
}

public enum DisplayFormat: Equatable, Sendable {
    case norm
    case fix(Int)
    case sci(Int)
    case eng
    case fraction
    case mixedFraction
}

// Mode, base, complex-format and menu definitions live in CalculatorModes.swift

public struct EvalResult: Sendable {
    public let value: Double?
    public let complexValue: Complex?
    public let error: String?

    public init(value: Double? = nil, complexValue: Complex? = nil, error: String? = nil) {
        self.value = value
        self.complexValue = complexValue
        self.error = error
    }
}

// Complex number type and CMPLX helpers live in ComplexMode.swift

// MARK: - Fraction Representation

public struct Fraction: Equatable, Sendable {
    public let num: Int64
    public let den: Int64

    public init(num: Int64, den: Int64) {
        guard den != 0 else {
            self.num = num
            self.den = 1
            return
        }
        let g = Fraction.gcd(abs(num), abs(den))
        let sign: Int64 = den < 0 ? -1 : 1
        self.num = (num / g) * sign
        self.den = abs(den) / g
    }

    public static func fromDouble(_ val: Double, maxDenom: Int64 = 100000) -> Fraction? {
        guard val.isFinite, !val.isNaN else { return nil }
        if abs(val) < 1e-12 { return Fraction(num: 0, den: 1) }

        var x = abs(val)
        var a = Int64(floor(x))
        var h1: Int64 = 1, h2: Int64 = 0
        var k1: Int64 = 0, k2: Int64 = 1

        var h = a * h1 + h2
        var k = a * k1 + k2

        while x - Double(a) > 1e-9 && k < maxDenom {
            x = 1.0 / (x - Double(a))
            a = Int64(floor(x))
            let hNext = a * h + h1
            let kNext = a * k + k1
            if kNext > maxDenom { break }
            h1 = h
            h2 = hNext
            k1 = k
            k2 = kNext
            h = hNext
            k = kNext
        }

        let signedNum = val < 0 ? -h : h
        let frac = Fraction(num: signedNum, den: k)
        if abs(Double(frac.num) / Double(frac.den) - val) < 1e-5 {
            return frac
        }
        return nil
    }

    private static func gcd(_ a: Int64, _ b: Int64) -> Int64 {
        var x = a, y = b
        while y != 0 {
            let t = y
            y = x % y
            x = t
        }
        return max(1, x)
    }

    public func formatImproper() -> String {
        if den == 1 { return "\(num)" }
        return "\(num)⌟\(den)"
    }

    public func formatMixed() -> String {
        if den == 1 { return "\(num)" }
        let whole = num / den
        let rem = abs(num % den)
        if whole == 0 { return "\(num)⌟\(den)" }
        return "\(whole)⌟\(rem)⌟\(den)"
    }
}

// Matrix type and MATRIX helpers live in MatrixMode.swift

// Vector3D (standalone vector math) and VectorValue live in VectorMode.swift

// MARK: - Constants & Conversions Tables

public struct CasioConstants {
    public static let items: [(code: Int, symbol: String, value: Double, unit: String)] = [
        (1, "mp", 1.672621777e-27, "kg"),
        (2, "mn", 1.674927351e-27, "kg"),
        (3, "me", 9.10938291e-31, "kg"),
        (4, "mμ", 1.883531475e-28, "kg"),
        (5, "a0", 5.29177210903e-11, "m"),
        (6, "h", 6.62606957e-34, "J·s"),
        (7, "μN", 5.05078353e-27, "J/T"),
        (8, "μB", 9.27400968e-24, "J/T"),
        (9, "ħ", 1.054571726e-34, "J·s"),
        (10, "α", 7.2973525698e-3, ""),
        (11, "re", 2.8179403267e-15, "m"),
        (12, "λc", 2.4263102367e-12, "m"),
        (13, "γp", 2.675222005e8, "s⁻¹T⁻¹"),
        (14, "λcp", 1.32140985396e-15, "m"),
        (15, "λcn", 1.31959090481e-15, "m"),
        (16, "R∞", 1.0973731568539e7, "m⁻¹"),
        (17, "u", 1.660538921e-27, "kg"),
        (18, "μp", 1.410606743e-26, "J/T"),
        (19, "μe", -9.28476430e-24, "J/T"),
        (20, "μn", -9.6623641e-27, "J/T"),
        (21, "μμ", -4.4904478e-26, "J/T"),
        (22, "F", 96485.3365, "C/mol"),
        (23, "e", 1.602176565e-19, "C"),
        (24, "NA", 6.02214129e23, "mol⁻¹"),
        (25, "k", 1.3806488e-23, "J/K"),
        (26, "Vm", 0.022413968, "m³/mol"),
        (27, "R", 8.3144621, "J/(mol·K)"),
        (28, "C0", 299792458.0, "m/s"),
        (29, "C1", 3.74177153e-16, "W·m²"),
        (30, "C2", 1.4387770e-2, "m·K"),
        (31, "σ", 5.670373e-8, "W/(m²·K⁴)"),
        (32, "ε0", 8.854187817e-12, "F/m"),
        (33, "μ0", 1.2566370614e-6, "N/A²"),
        (34, "φ0", 2.067833758e-15, "Wb"),
        (35, "g", 9.80665, "m/s²"),
        (36, "G0", 7.7480917346e-5, "S"),
        (37, "Z0", 376.730313461, "Ω"),
        (38, "t", 273.15, "K"),
        (39, "G", 6.67384e-11, "m³/(kg·s²)"),
        (40, "atm", 101325.0, "Pa")
    ]

    public static func get(_ code: Int) -> (symbol: String, value: Double)? {
        guard let item = items.first(where: { $0.code == code }) else { return nil }
        return (item.symbol, item.value)
    }
}

public struct CasioConversions {
    public static func convert(value: Double, code: Int) -> (name: String, result: Double)? {
        switch code {
        case 1: return ("in▶cm", value * 2.54)
        case 2: return ("cm▶in", value / 2.54)
        case 3: return ("ft▶m", value * 0.3048)
        case 4: return ("m▶ft", value / 0.3048)
        case 5: return ("yd▶m", value * 0.9144)
        case 6: return ("m▶yd", value / 0.9144)
        case 7: return ("mile▶km", value * 1.609344)
        case 8: return ("km▶mile", value / 1.609344)
        case 9: return ("n mile▶m", value * 1852.0)
        case 10: return ("m▶n mile", value / 1852.0)
        case 11: return ("acre▶m²", value * 4046.8564224)
        case 12: return ("m²▶acre", value / 4046.8564224)
        case 13: return ("gal(US)▶ℓ", value * 3.785411784)
        case 14: return ("ℓ▶gal(US)", value / 3.785411784)
        case 15: return ("gal(UK)▶ℓ", value * 4.54609)
        case 16: return ("ℓ▶gal(UK)", value / 4.54609)
        case 17: return ("pc▶km", value * 3.08567758149e13)
        case 18: return ("km▶pc", value / 3.08567758149e13)
        case 19: return ("km/h▶m/s", value / 3.6)
        case 20: return ("m/s▶km/h", value * 3.6)
        case 21: return ("oz▶g", value * 28.349523125)
        case 22: return ("g▶oz", value / 28.349523125)
        case 23: return ("lb▶kg", value * 0.45359237)
        case 24: return ("kg▶lb", value / 0.45359237)
        case 25: return ("atm▶Pa", value * 101325.0)
        case 26: return ("Pa▶atm", value / 101325.0)
        case 27: return ("mmHg▶Pa", value * 133.322)
        case 28: return ("Pa▶mmHg", value / 133.322)
        case 29: return ("hp▶kW", value * 0.74569987158227)
        case 30: return ("kW▶hp", value / 0.74569987158227)
        case 31: return ("kgf/cm²▶Pa", value * 98066.5)
        case 32: return ("Pa▶kgf/cm²", value / 98066.5)
        case 33: return ("kgf·m▶J", value * 9.80665)
        case 34: return ("J▶kgf·m", value / 9.80665)
        case 35: return ("lbf/in²▶kPa", value * 6.894757)
        case 36: return ("kPa▶lbf/in²", value / 6.894757)
        case 37: return ("°F▶°C", (value - 32.0) * 5.0 / 9.0)
        case 38: return ("°C▶°F", value * 9.0 / 5.0 + 32.0)
        case 39: return ("J▶cal", value / 4.184)
        case 40: return ("cal▶J", value * 4.184)
        default: return nil
        }
    }
}

// MARK: - Casio Infix Evaluator

public enum CasioEvaluator {
    private enum Token: Equatable {
        case number(Double)
        case complex(Complex)
        case identifier(String)
        case binaryOp(String, Int, Bool) // symbol, precedence, rightAssociative
        case prefixFunc(String)
        case postfixOp(String)
        case openParen
        case closeParen
        case comma
    }

    public static func evaluate(
        _ expr: String,
        angleUnit: AngleUnit = .deg,
        variables: [Character: Double] = [:],
        lastAnswer: Double = 0,
        isCmplx: Bool = false
    ) -> EvalResult {
        let trimmed = expr.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return EvalResult(value: 0)
        }

        // Multi-statement ':' separator support: evaluate each in order, return last result
        if trimmed.contains(":") {
            let statements = trimmed.components(separatedBy: ":")
            var currentAns = lastAnswer
            let currentVars = variables
            for stmt in statements {
                let trimmedStmt = stmt.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedStmt.isEmpty { continue }
                let res = evaluate(trimmedStmt, angleUnit: angleUnit, variables: currentVars, lastAnswer: currentAns, isCmplx: isCmplx)
                if res.error != nil { return res }
                if let val = res.value {
                    currentAns = val
                }
            }
            return EvalResult(value: currentAns)
        }

        // Auto-close any unclosed open brackets (authentic Casio / standard calculator behavior)
        var balanced = trimmed
        var openCount = 0
        for char in balanced {
            if char == "(" {
                openCount += 1
            } else if char == ")" {
                if openCount > 0 {
                    openCount -= 1
                }
            }
        }
        if openCount > 0 {
            balanced.append(String(repeating: ")", count: openCount))
        }

        // Check for equation with '=' (not solve mode)
        if balanced.contains("=") && !balanced.starts(with: "d/dx") && !balanced.starts(with: "∫") {
            let parts = balanced.components(separatedBy: "=")
            if parts.count == 2 {
                let leftRes = evaluate(parts[0], angleUnit: angleUnit, variables: variables, lastAnswer: lastAnswer, isCmplx: isCmplx)
                let rightRes = evaluate(parts[1], angleUnit: angleUnit, variables: variables, lastAnswer: lastAnswer, isCmplx: isCmplx)
                if let err = leftRes.error { return EvalResult(error: err) }
                if let err = rightRes.error { return EvalResult(error: err) }
                let diff = (leftRes.value ?? 0) - (rightRes.value ?? 0)
                return EvalResult(value: diff)
            }
        }

        // Calculus: Numerical derivative d/dx(f(x), a)
        if balanced.starts(with: "d/dx(") && balanced.hasSuffix(")") {
            return evaluateDerivative(balanced, angleUnit: angleUnit, variables: variables)
        }

        // Calculus: Numerical integral ∫(f(x), a, b)
        if (balanced.starts(with: "∫(") || balanced.starts(with: "int(")) && balanced.hasSuffix(")") {
            return evaluateIntegral(balanced, angleUnit: angleUnit, variables: variables)
        }

        // Summation: Σ(f(x), x, a, b)
        if (balanced.starts(with: "Σ(") || balanced.starts(with: "sum(")) && balanced.hasSuffix(")") {
            return evaluateSummation(balanced, angleUnit: angleUnit, variables: variables)
        }

        let tokens: [Token]
        do {
            tokens = try tokenize(balanced, variables: variables, lastAnswer: lastAnswer, isCmplx: isCmplx)
        } catch {
            return EvalResult(error: "Syntax ERROR")
        }

        let rpn: [Token]
        do {
            rpn = try shuntingYard(tokens)
        } catch {
            return EvalResult(error: "Syntax ERROR")
        }

        if isCmplx {
            return evaluateComplexRPN(rpn, angleUnit: angleUnit)
        } else {
            return evaluateRPN(rpn, angleUnit: angleUnit)
        }
    }

    private static func tokenize(
        _ expr: String,
        variables: [Character: Double],
        lastAnswer: Double,
        isCmplx: Bool
    ) throws -> [Token] {
        var tokens: [Token] = []
        let chars = Array(expr)
        var i = 0

        func advance() -> Character {
            let c = chars[i]
            i += 1
            return c
        }

        while i < chars.count {
            let c = chars[i]

            if c.isWhitespace {
                i += 1
                continue
            }

            // Numbers: digits and decimal point
            if (c >= "0" && c <= "9") || c == "." {
                var numStr = ""
                while i < chars.count && ((chars[i] >= "0" && chars[i] <= "9") || chars[i] == ".") {
                    numStr.append(advance())
                }
                guard let num = Double(numStr) else { throw NSError(domain: "Parse", code: 1) }

                if let last = tokens.last, canImplicitMultiplyBefore(last) {
                    tokens.append(.binaryOp("×", 3, false))
                }
                tokens.append(.number(num))
                continue
            }

            // Negative sign vs subtraction
            if c == "-" || c == "−" {
                i += 1
                let isUnary: Bool
                if let last = tokens.last {
                    switch last {
                    case .binaryOp, .openParen, .prefixFunc, .comma:
                        isUnary = true
                    default:
                        isUnary = false
                    }
                } else {
                    isUnary = true
                }

                if isUnary {
                    tokens.append(.prefixFunc("neg"))
                } else {
                    tokens.append(.binaryOp("−", 1, false))
                }
                continue
            }

            // Parentheses and Comma
            if c == "(" {
                if let last = tokens.last, canImplicitMultiplyBefore(last) {
                    tokens.append(.binaryOp("×", 3, false))
                }
                tokens.append(.openParen)
                i += 1
                continue
            }

            if c == ")" {
                tokens.append(.closeParen)
                i += 1
                continue
            }

            if c == "," {
                tokens.append(.comma)
                i += 1
                continue
            }

            // Standard Operators
            if c == "+" {
                tokens.append(.binaryOp("+", 1, false))
                i += 1
                continue
            }
            if c == "×" || c == "*" {
                tokens.append(.binaryOp("×", 2, false))
                i += 1
                continue
            }
            if c == "÷" || c == "/" {
                tokens.append(.binaryOp("÷", 2, false))
                i += 1
                continue
            }
            if c == "^" {
                tokens.append(.binaryOp("^", 4, true))
                i += 1
                continue
            }

            // Polar Angle Symbol ∠
            if c == "∠" {
                tokens.append(.binaryOp("∠", 2, false))
                i += 1
                continue
            }

            // Postfix powers and operators
            if c == "²" {
                tokens.append(.postfixOp("²"))
                i += 1
                continue
            }
            if c == "³" {
                tokens.append(.postfixOp("³"))
                i += 1
                continue
            }
            if c == "!" {
                tokens.append(.postfixOp("!"))
                i += 1
                continue
            }
            if c == "%" {
                tokens.append(.postfixOp("%"))
                i += 1
                continue
            }

            // Sexagesimal (DMS) markers: fold {d}°{m}'{s}" into one value
            // (fx-991ES input syntax; degrees + minutes/60 + seconds/3600)
            if c == "°" || c == "'" || c == "\"" {
                guard case .number(var dmsTotal)? = tokens.last else {
                    // Marker with no preceding value (e.g. 45°'17") is malformed
                    throw NSError(domain: "Parse", code: 6)
                }
                var j = i + 1
                if c == "°" {
                    // Degrees already folded (factor 1); look for minutes/seconds
                    var mStr = ""
                    while j < chars.count && ((chars[j] >= "0" && chars[j] <= "9") || chars[j] == ".") {
                        mStr.append(chars[j]); j += 1
                    }
                    if !mStr.isEmpty, j < chars.count, chars[j] == "'" {
                        guard let m = Double(mStr) else { throw NSError(domain: "Parse", code: 6) }
                        dmsTotal += m / 60.0
                        j += 1
                        var sStr = ""
                        let sStart = j
                        while j < chars.count && ((chars[j] >= "0" && chars[j] <= "9") || chars[j] == ".") {
                            sStr.append(chars[j]); j += 1
                        }
                        if !sStr.isEmpty, j < chars.count, chars[j] == "\"" {
                            guard let s = Double(sStr) else { throw NSError(domain: "Parse", code: 6) }
                            dmsTotal += s / 3600.0
                            j += 1
                        } else {
                            j = sStart // no seconds field; leave trailing digits to parse normally
                        }
                    } else {
                        j = i + 1 // no minutes field; bare d° is valid (identity)
                    }
                } else {
                    // "'" or """ marker without a ° start of group
                    throw NSError(domain: "Parse", code: 6)
                }
                tokens[tokens.count - 1] = .number(dmsTotal)
                i = j
                continue
            }

            // Roots
            if c == "√" {
                if let last = tokens.last, canImplicitMultiplyBefore(last) {
                    tokens.append(.binaryOp("×", 3, false))
                }
                tokens.append(.prefixFunc("√"))
                i += 1
                continue
            }
            if c == "∛" {
                if let last = tokens.last, canImplicitMultiplyBefore(last) {
                    tokens.append(.binaryOp("×", 3, false))
                }
                tokens.append(.prefixFunc("∛"))
                i += 1
                continue
            }

            // Special single char constants
            if c == "π" {
                if let last = tokens.last, canImplicitMultiplyBefore(last) {
                    tokens.append(.binaryOp("×", 3, false))
                }
                tokens.append(.number(.pi))
                i += 1
                continue
            }
            if c == "e" && (i + 1 == chars.count || !chars[i + 1].isLetter) {
                if let last = tokens.last, canImplicitMultiplyBefore(last) {
                    tokens.append(.binaryOp("×", 3, false))
                }
                tokens.append(.number(M_E))
                i += 1
                continue
            }
            if c == "i" && (i + 1 == chars.count || !chars[i + 1].isLetter) {
                if let last = tokens.last, canImplicitMultiplyBefore(last) {
                    tokens.append(.binaryOp("×", 3, false))
                }
                tokens.append(.complex(Complex.i))
                i += 1
                continue
            }

            // Variables (A, B, C, D, E, F, X, Y, M) — except that C between a
            // value and a digit is the nCr operator glyph (fx-991ES shows nCr as C)
            if ["A", "B", "C", "D", "E", "F", "X", "Y", "M"].contains(c) &&
                (i + 1 == chars.count || !chars[i + 1].isLetter) {
                let nextIsDigit = i + 1 < chars.count && ((chars[i + 1] >= "0" && chars[i + 1] <= "9") || chars[i + 1] == ".")
                var prevIsValue = false
                switch tokens.last {
                case .number, .complex, .closeParen, .postfixOp: prevIsValue = true
                default: prevIsValue = false
                }
                if c == "C" && prevIsValue && nextIsDigit {
                    tokens.append(.binaryOp("nCr", 2, false))
                    i += 1
                    continue
                }
                if let last = tokens.last, canImplicitMultiplyBefore(last) {
                    tokens.append(.binaryOp("×", 3, false))
                }
                let val = variables[c] ?? 0
                tokens.append(.number(val))
                i += 1
                continue
            }

            // Identifiers / Multi-character Words
            var word = ""
            while i < chars.count && (chars[i].isLetter || chars[i] == "⁻" || chars[i] == "¹" || chars[i] == "#" || chars[i] == "▶") {
                word.append(advance())
            }

            if !word.isEmpty {
                if word == "Ans" {
                    if let last = tokens.last, canImplicitMultiplyBefore(last) {
                        tokens.append(.binaryOp("×", 3, false))
                    }
                    tokens.append(.number(lastAnswer))
                } else if ["sin", "cos", "tan", "asin", "acos", "atan", "sin⁻¹", "cos⁻¹", "tan⁻¹",
                           "sinh", "cosh", "tanh", "sinh⁻¹", "cosh⁻¹", "tanh⁻¹",
                           "log", "ln", "abs", "Abs", "Int", "Intg", "arg", "Conjg", "Pol", "Rec", "Ran#"].contains(word) {
                    if let last = tokens.last, canImplicitMultiplyBefore(last) {
                        tokens.append(.binaryOp("×", 3, false))
                    }
                    tokens.append(.prefixFunc(word))
                } else if word == "P" {
                    // Authentic display glyph: nPr renders as P on the fx-991ES
                    tokens.append(.binaryOp("nPr", 2, false))
                } else if word == "C" {
                    tokens.append(.binaryOp("nCr", 2, false))
                } else if ["nPr", "nCr", "and", "or", "xor", "xnor"].contains(word) {
                    tokens.append(.binaryOp(word, 2, false))
                } else if word == "Not" {
                    tokens.append(.prefixFunc("Not"))
                } else if word == "Neg" {
                    tokens.append(.prefixFunc("Neg"))
                } else if word == "RanInt" || word == "RanInt#" {
                    tokens.append(.prefixFunc("RanInt"))
                } else {
                    tokens.append(.identifier(word))
                }
                continue
            }

            i += 1
        }

        return tokens
    }

    private static func canImplicitMultiplyBefore(_ token: Token) -> Bool {
        switch token {
        case .number, .complex, .closeParen, .postfixOp:
            return true
        default:
            return false
        }
    }

    private static func shuntingYard(_ tokens: [Token]) throws -> [Token] {
        var output: [Token] = []
        var opStack: [Token] = []

        for token in tokens {
            switch token {
            case .number, .complex:
                output.append(token)
            case .prefixFunc:
                opStack.append(token)
            case .postfixOp:
                output.append(token)
            case .binaryOp(_, let prec1, let rightAssoc1):
                while let top = opStack.last {
                    if case .binaryOp(_, let prec2, _) = top {
                        if (rightAssoc1 && prec1 < prec2) || (!rightAssoc1 && prec1 <= prec2) {
                            output.append(opStack.removeLast())
                            continue
                        }
                    } else if case .prefixFunc = top {
                        output.append(opStack.removeLast())
                        continue
                    }
                    break
                }
                opStack.append(token)
            case .openParen:
                opStack.append(token)
            case .comma:
                while let top = opStack.last, top != .openParen {
                    output.append(opStack.removeLast())
                }
            case .closeParen:
                var matched = false
                while let top = opStack.last {
                    if top == .openParen {
                        matched = true
                        _ = opStack.removeLast()
                        if let next = opStack.last, case .prefixFunc = next {
                            output.append(opStack.removeLast())
                        }
                        break
                    }
                    output.append(opStack.removeLast())
                }
                if !matched {
                    throw NSError(domain: "Parenthesis mismatch", code: 2)
                }
            case .identifier:
                throw NSError(domain: "Unknown identifier", code: 3)
            }
        }

        while let top = opStack.removeLastIfPresent() {
            if top == .openParen {
                if let next = opStack.last, case .prefixFunc = next {
                    output.append(opStack.removeLast())
                }
                continue
            }
            if top == .closeParen {
                throw NSError(domain: "Parenthesis mismatch", code: 4)
            }
            output.append(top)
        }

        return output
    }

    private static func evaluateRPN(_ rpn: [Token], angleUnit: AngleUnit) -> EvalResult {
        var stack: [Double] = []

        for token in rpn {
            switch token {
            case .number(let val):
                stack.append(val)

            case .postfixOp(let op):
                guard let val = stack.popLast() else { return EvalResult(error: "Syntax ERROR") }
                switch op {
                case "²":
                    stack.append(val * val)
                case "³":
                    stack.append(val * val * val)
                case "!":
                    guard val >= 0, val.rounded(.down) == val, val <= 69 else {
                        return EvalResult(error: "Math ERROR")
                    }
                    var fact = 1.0
                    if val > 1 {
                        for k in 2...Int(val) { fact *= Double(k) }
                    }
                    stack.append(fact)
                case "%":
                    stack.append(val / 100.0)
                default:
                    return EvalResult(error: "Syntax ERROR")
                }

            case .prefixFunc(let f):
                // Two-argument functions: Pol(x,y), Rec(r,θ), RanInt#(lo,hi).
                // Shunting-yard leaves the two operands on the stack in order.
                if f == "Pol" || f == "Rec" || f == "RanInt" {
                    guard let right = stack.popLast(), let left = stack.popLast() else {
                        return EvalResult(error: "Syntax ERROR")
                    }
                    switch f {
                    case "Pol":
                        // Rectangular (x,y) → polar radius r. (θ = atan2(y,x)
                        // in the current angle unit is the secondary result.)
                        stack.append(Foundation.sqrt(left * left + right * right))
                    case "Rec":
                        // Polar (r,θ) → rectangular x component.
                        stack.append(left * Foundation.cos(angleUnit.toRadians(right)))
                    case "RanInt":
                        let lo = Int(left.rounded()), hi = Int(right.rounded())
                        guard lo <= hi else { return EvalResult(error: "Math ERROR") }
                        stack.append(Double(Int.random(in: lo...hi)))
                    default:
                        break
                    }
                    continue
                }
                guard let val = stack.popLast() else { return EvalResult(error: "Syntax ERROR") }
                switch f {
                case "neg":
                    stack.append(-val)
                case "√":
                    guard val >= 0 else { return EvalResult(error: "Math ERROR") }
                    stack.append(Foundation.sqrt(val))
                case "∛":
                    stack.append(val < 0 ? -Foundation.pow(-val, 1.0 / 3.0) : Foundation.pow(val, 1.0 / 3.0))
                case "sin":
                    stack.append(Foundation.sin(angleUnit.toRadians(val)))
                case "cos":
                    stack.append(Foundation.cos(angleUnit.toRadians(val)))
                case "tan":
                    let rad = angleUnit.toRadians(val)
                    if abs(Foundation.cos(rad)) < 1e-14 { return EvalResult(error: "Math ERROR") }
                    stack.append(Foundation.tan(rad))
                case "asin", "sin⁻¹":
                    guard val >= -1.0 && val <= 1.0 else { return EvalResult(error: "Math ERROR") }
                    stack.append(angleUnit.fromRadians(Foundation.asin(val)))
                case "acos", "cos⁻¹":
                    guard val >= -1.0 && val <= 1.0 else { return EvalResult(error: "Math ERROR") }
                    stack.append(angleUnit.fromRadians(Foundation.acos(val)))
                case "atan", "tan⁻¹":
                    stack.append(angleUnit.fromRadians(Foundation.atan(val)))
                case "sinh":
                    stack.append(Foundation.sinh(val))
                case "cosh":
                    stack.append(Foundation.cosh(val))
                case "tanh":
                    stack.append(Foundation.tanh(val))
                case "sinh⁻¹":
                    stack.append(Foundation.asinh(val))
                case "cosh⁻¹":
                    guard val >= 1.0 else { return EvalResult(error: "Math ERROR") }
                    stack.append(Foundation.acosh(val))
                case "tanh⁻¹":
                    guard abs(val) < 1.0 else { return EvalResult(error: "Math ERROR") }
                    stack.append(Foundation.atanh(val))
                case "ln":
                    guard val > 0 else { return EvalResult(error: "Math ERROR") }
                    stack.append(Foundation.log(val))
                case "log":
                    guard val > 0 else { return EvalResult(error: "Math ERROR") }
                    stack.append(Foundation.log10(val))
                case "abs", "Abs":
                    stack.append(abs(val))
                case "Int":
                    stack.append(Foundation.trunc(val))
                case "Intg":
                    stack.append(Foundation.floor(val))
                case "Ran#":
                    stack.append(Double(Int.random(in: 0...999)) / 1000.0)
                default:
                    return EvalResult(error: "Syntax ERROR")
                }

            case .binaryOp(let op, _, _):
                guard let right = stack.popLast(), let left = stack.popLast() else {
                    return EvalResult(error: "Syntax ERROR")
                }
                switch op {
                case "+":
                    stack.append(left + right)
                case "−", "-":
                    stack.append(left - right)
                case "×", "*":
                    stack.append(left * right)
                case "÷", "/":
                    guard right != 0 else { return EvalResult(error: "Math ERROR") }
                    stack.append(left / right)
                case "^":
                    if left < 0 && right.rounded(.down) != right {
                        return EvalResult(error: "Math ERROR")
                    }
                    let r = Foundation.pow(left, right)
                    guard r.isFinite else { return EvalResult(error: "Math ERROR") }
                    stack.append(r)
                case "nPr":
                    guard left >= 0, right >= 0, left.rounded(.down) == left, right.rounded(.down) == right, left >= right else {
                        return EvalResult(error: "Math ERROR")
                    }
                    var p = 1.0
                    let n = Int(left)
                    let r = Int(right)
                    for k in 0..<r { p *= Double(n - k) }
                    stack.append(p)
                case "nCr":
                    guard left >= 0, right >= 0, left.rounded(.down) == left, right.rounded(.down) == right, left >= right else {
                        return EvalResult(error: "Math ERROR")
                    }
                    var c = 1.0
                    let n = Int(left)
                    let r = min(Int(right), n - Int(right))
                    for k in 1...max(1, r) {
                        c = c * Double(n - k + 1) / Double(k)
                    }
                    stack.append(c)
                case "and":
                    let l = Int32(truncatingIfNeeded: Int64(left))
                    let r = Int32(truncatingIfNeeded: Int64(right))
                    stack.append(Double(l & r))
                case "or":
                    let l = Int32(truncatingIfNeeded: Int64(left))
                    let r = Int32(truncatingIfNeeded: Int64(right))
                    stack.append(Double(l | r))
                case "xor":
                    let l = Int32(truncatingIfNeeded: Int64(left))
                    let r = Int32(truncatingIfNeeded: Int64(right))
                    stack.append(Double(l ^ r))
                case "xnor":
                    let l = Int32(truncatingIfNeeded: Int64(left))
                    let r = Int32(truncatingIfNeeded: Int64(right))
                    stack.append(Double(~(l ^ r)))
                default:
                    return EvalResult(error: "Syntax ERROR")
                }

            default:
                return EvalResult(error: "Syntax ERROR")
            }
        }

        guard stack.count == 1, let finalVal = stack.first, finalVal.isFinite else {
            return EvalResult(error: "Math ERROR")
        }

        return EvalResult(value: finalVal)
    }

    private static func evaluateComplexRPN(_ rpn: [Token], angleUnit: AngleUnit) -> EvalResult {
        var stack: [Complex] = []

        for token in rpn {
            switch token {
            case .number(let val):
                stack.append(Complex(real: val, imag: 0))
            case .complex(let c):
                stack.append(c)

            case .postfixOp(let op):
                guard let c = stack.popLast() else { return EvalResult(error: "Syntax ERROR") }
                switch op {
                case "²":
                    stack.append(c * c)
                case "³":
                    stack.append(c * c * c)
                default:
                    return EvalResult(error: "Syntax ERROR")
                }

            case .prefixFunc(let f):
                guard let c = stack.popLast() else { return EvalResult(error: "Syntax ERROR") }
                switch f {
                case "neg":
                    stack.append(Complex(real: -c.real, imag: -c.imag))
                case "abs", "Abs":
                    stack.append(Complex(real: c.magnitude, imag: 0))
                case "arg":
                    stack.append(Complex(real: c.argument(angleUnit: angleUnit), imag: 0))
                case "Conjg":
                    stack.append(c.conjugate)
                case "√":
                    let r = c.magnitude
                    let theta = Foundation.atan2(c.imag, c.real)
                    let sqrtR = Foundation.sqrt(r)
                    stack.append(Complex(real: sqrtR * Foundation.cos(theta / 2.0), imag: sqrtR * Foundation.sin(theta / 2.0)))
                default:
                    return EvalResult(error: "Syntax ERROR")
                }

            case .binaryOp(let op, _, _):
                guard let right = stack.popLast(), let left = stack.popLast() else {
                    return EvalResult(error: "Syntax ERROR")
                }
                switch op {
                case "+":
                    stack.append(left + right)
                case "−", "-":
                    stack.append(left - right)
                case "×", "*":
                    stack.append(left * right)
                case "÷", "/":
                    guard let div = left / right else { return EvalResult(error: "Math ERROR") }
                    stack.append(div)
                case "∠":
                    let r = left.real
                    let thetaRad = angleUnit.toRadians(right.real)
                    stack.append(Complex(real: r * Foundation.cos(thetaRad), imag: r * Foundation.sin(thetaRad)))
                default:
                    return EvalResult(error: "Syntax ERROR")
                }

            default:
                return EvalResult(error: "Syntax ERROR")
            }
        }

        guard stack.count == 1, let finalVal = stack.first else {
            return EvalResult(error: "Math ERROR")
        }

        return EvalResult(value: finalVal.real, complexValue: finalVal)
    }

    // MARK: - Numerical Calculus & Summation

    private static func evaluateDerivative(_ expr: String, angleUnit: AngleUnit, variables: [Character: Double]) -> EvalResult {
        // format: d/dx(f(x), a)
        let inside = String(expr.dropFirst(5).dropLast(1))
        let parts = inside.components(separatedBy: ",")
        guard parts.count >= 2 else { return EvalResult(error: "Argument ERROR") }
        let fExpr = parts[0]
        let aRes = evaluate(parts[1], angleUnit: angleUnit, variables: variables)
        guard let a = aRes.value else { return EvalResult(error: "Math ERROR") }

        let h = 1e-6
        var varsPlus = variables
        varsPlus["X"] = a + h
        let resPlus = evaluate(fExpr, angleUnit: angleUnit, variables: varsPlus)

        var varsMinus = variables
        varsMinus["X"] = a - h
        let resMinus = evaluate(fExpr, angleUnit: angleUnit, variables: varsMinus)

        guard let yPlus = resPlus.value, let yMinus = resMinus.value else {
            return EvalResult(error: "Math ERROR")
        }

        let deriv = (yPlus - yMinus) / (2.0 * h)
        return EvalResult(value: deriv)
    }

    private static func evaluateIntegral(_ expr: String, angleUnit: AngleUnit, variables: [Character: Double]) -> EvalResult {
        // format: ∫(f(x), a, b)
        let prefixLen = expr.starts(with: "∫(") ? 2 : 4
        let inside = String(expr.dropFirst(prefixLen).dropLast(1))
        let parts = inside.components(separatedBy: ",")
        guard parts.count >= 3 else { return EvalResult(error: "Argument ERROR") }
        let fExpr = parts[0]
        guard let a = evaluate(parts[1], angleUnit: angleUnit, variables: variables).value,
              let b = evaluate(parts[2], angleUnit: angleUnit, variables: variables).value else {
            return EvalResult(error: "Math ERROR")
        }

        // Simpson's composite rule with n = 100 intervals
        let n = 100
        let h = (b - a) / Double(n)

        var varsA = variables
        varsA["X"] = a
        guard let fa = evaluate(fExpr, angleUnit: angleUnit, variables: varsA).value else { return EvalResult(error: "Math ERROR") }

        var varsB = variables
        varsB["X"] = b
        guard let fb = evaluate(fExpr, angleUnit: angleUnit, variables: varsB).value else { return EvalResult(error: "Math ERROR") }

        var sum = fa + fb
        for k in 1..<n {
            let x = a + Double(k) * h
            var varsK = variables
            varsK["X"] = x
            guard let fx = evaluate(fExpr, angleUnit: angleUnit, variables: varsK).value else { return EvalResult(error: "Math ERROR") }
            sum += (k % 2 == 0 ? 2.0 : 4.0) * fx
        }

        let integral = sum * h / 3.0
        return EvalResult(value: integral)
    }

    private static func evaluateSummation(_ expr: String, angleUnit: AngleUnit, variables: [Character: Double]) -> EvalResult {
        // format: Σ(f(x), x, a, b) or Σ(f(x), a, b)
        let prefixLen = expr.starts(with: "Σ(") ? 2 : 4
        let inside = String(expr.dropFirst(prefixLen).dropLast(1))
        let parts = inside.components(separatedBy: ",")
        guard parts.count >= 3 else { return EvalResult(error: "Argument ERROR") }

        let fExpr = parts[0]
        let aStr = parts.count == 3 ? parts[1] : parts[2]
        let bStr = parts.count == 3 ? parts[2] : parts[3]

        guard let a = evaluate(aStr, angleUnit: angleUnit, variables: variables).value,
              let b = evaluate(bStr, angleUnit: angleUnit, variables: variables).value else {
            return EvalResult(error: "Math ERROR")
        }

        let start = Int(a.rounded())
        let end = Int(b.rounded())
        guard start <= end, (end - start) <= 1000 else { return EvalResult(error: "Argument ERROR") }

        var total = 0.0
        for k in start...end {
            var varsK = variables
            varsK["X"] = Double(k)
            guard let fk = evaluate(fExpr, angleUnit: angleUnit, variables: varsK).value else { return EvalResult(error: "Math ERROR") }
            total += fk
        }

        return EvalResult(value: total)
    }

    // MARK: - Formatters

    public static func format(_ val: Double, format: DisplayFormat) -> String {
        guard val.isFinite else { return "Math ERROR" }
        if val == 0 { return "0" }

        switch format {
        case .fix(let d):
            return String(format: "%.\(d)f", val)
        case .sci(let d):
            return String(format: "%.\(max(0, d - 1))e", val)
        case .eng:
            let exp = Int(floor(Foundation.log10(abs(val))))
            let engExp = exp >= 0 ? (exp / 3) * 3 : ((exp - 2) / 3) * 3
            let mantissa = val / Foundation.pow(10.0, Double(engExp))
            return "\(String(format: "%.6g", mantissa))×10^\(engExp)"
        case .fraction:
            if let frac = Fraction.fromDouble(val) {
                return frac.formatImproper()
            }
            return CasioEvaluator.format(val, format: .norm)
        case .mixedFraction:
            if let frac = Fraction.fromDouble(val) {
                return frac.formatMixed()
            }
            return CasioEvaluator.format(val, format: .norm)
        case .norm:
            let mag = abs(val)
            if mag >= 1e10 || mag < 1e-2 {
                return String(format: "%.6g", val)
            }
            return String(format: "%.10g", val)
        }
    }

    /// Engineering notation with an ENG/← shift level: level 0 is the plain
    /// form; each ENG press moves the decimal point three places (manual p.24).
    public static func formatEng(_ val: Double, level: Int) -> String {
        guard val.isFinite, val != 0, level > 0 else { return format(val, format: .norm) }
        let exp = Int(floor(Foundation.log10(abs(val))))
        // Base exponent: floor to a multiple of 3
        let baseExp = exp >= 0 ? (exp / 3) * 3 : ((exp - 2) / 3) * 3
        let targetExp = baseExp + 3 * (level - 1)
        let mantissa = val / Foundation.pow(10.0, Double(targetExp))
        return "\(String(format: "%.10g", mantissa))×10^\(targetExp)"
    }

    public static func primeFactorization(_ val: Int64) -> String? {
        guard val > 1 && val <= 10000000000 else { return nil }
        var n = val
        var factors: [(prime: Int64, count: Int)] = []

        var p: Int64 = 2
        while p * p <= n {
            if n % p == 0 {
                var count = 0
                while n % p == 0 {
                    count += 1
                    n /= p
                }
                factors.append((p, count))
            }
            p = (p == 2) ? 3 : (p + 2)
        }
        if n > 1 {
            factors.append((n, 1))
        }

        let superscripts: [Character: Character] = [
            "0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴",
            "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹"
        ]

        var res = ""
        for (idx, item) in factors.enumerated() {
            if idx > 0 { res.append("×") }
            res.append("\(item.prime)")
            if item.count > 1 {
                for c in "\(item.count)" {
                    res.append(superscripts[c] ?? c)
                }
            }
        }
        return res
    }

    /// Formats a decimal value as sexagesimal degrees with authentic Casio
    /// glyphs and normalized fields (0–59 minutes/seconds), e.g. 2.255 → 2°15'18".
    public static func formatSexagesimal(_ val: Double) -> String {
        guard val.isFinite else { return "Math ERROR" }
        let sign = val < 0 ? "−" : ""
        let absVal = abs(val)
        var deg = Int(floor(absVal))
        var remMin = (absVal - Double(deg)) * 60.0
        var min = Int(floor(remMin))
        var sec = (remMin - Double(min)) * 60.0

        // Carry rounding overflow (59.999…″) into the higher fields
        let secRounded = (sec * 100.0).rounded() / 100.0
        if secRounded >= 60.0 {
            sec = 0
            remMin = 0
            min += 1
            if min >= 60 {
                min = 0
                deg += 1
            }
        } else {
            sec = secRounded
        }

        let secText: String
        if abs(sec - sec.rounded()) < 1e-9 {
            secText = "\(Int(sec.rounded()))"
        } else {
            secText = "\(sec)"
        }
        return "\(sign)\(deg)°\(min)'\(secText)\""
    }

    public static func toDMS(_ val: Double) -> String {
        formatSexagesimal(val)
    }

    // MARK: - Equation Solvers & Numerical Methods

    public static func solveEquation(
        _ equation: String,
        initialGuess: Double,
        angleUnit: AngleUnit,
        variables: [Character: Double]
    ) -> (root: Double, residual: Double)? {
        let f: (Double) -> Double? = { x in
            var vars = variables
            vars["X"] = x
            let res = evaluate(equation, angleUnit: angleUnit, variables: vars)
            return res.value
        }

        var x0 = initialGuess
        let h = 1e-6
        for _ in 0..<100 {
            guard let y0 = f(x0) else { return nil }
            if abs(y0) < 1e-10 {
                return (root: x0, residual: y0)
            }
            guard let yPlus = f(x0 + h), let yMinus = f(x0 - h) else { return nil }
            let dy = (yPlus - yMinus) / (2.0 * h)
            if abs(dy) < 1e-14 {
                x0 += 0.1
                continue
            }
            let x1 = x0 - y0 / dy
            if abs(x1 - x0) < 1e-9 {
                let res = f(x1) ?? 0
                return (root: x1, residual: res)
            }
            x0 = x1
        }
        let finalRes = f(x0) ?? 0
        return (root: x0, residual: finalRes)
    }

}

private extension Array {
    mutating func removeLastIfPresent() -> Element? {
        return isEmpty ? nil : removeLast()
    }
}

// MARK: - Calculator Engine

public final class CalculatorEngine: ObservableObjectProtocol {
    @Published public var expression: String = ""
    @Published public var cursorPosition: Int = 0
    @Published public var result: String = ""
    @Published public var angleUnit: AngleUnit = .deg
    @Published public var displayFormat: DisplayFormat = .norm
    @Published public var activeMode: CalcMode = .comp
    @Published public var menuState: MenuState = .none

    @Published public var baseNType: BaseNType = .dec
    @Published public var complexFormat: ComplexFormat = .rectangular
    @Published public var statFrequencyEnabled: Bool = false
    // SETUP preferences (manual §3, opened with SHIFT+MODE)
    @Published public var mathOutputStyle: MathOutputStyle = .mathO
    @Published public var normMode: NormMode = .norm1
    @Published public var decimalPoint: DecimalPoint = .dot
    @Published public var fractionDisplay: FractionDisplay = .improper
    @Published public var contrastLevel: Int = 3
    @Published public var shiftActive: Bool = false
    @Published public var alphaActive: Bool = false
    /// SHIFT + DEL (INS) toggles insert/overwrite mode in Linear Display.
    /// Natural Display always uses insert mode.
    @Published public var isOverwriteMode: Bool = false
    @Published public var hasMemory: Bool = false
    @Published public var isError: Bool = false
    @Published public var isOff: Bool = false

    // Natural-V.P.A.M. 2D AST & Exact Symbolic State
    @Published public var astManager: MathASTManager = MathASTManager()
    @Published public var exactResult: ExactValue? = nil
    @Published public var isShowingDecimal: Bool = false
    @Published public var isMthIO: Bool = true

    /// True while a completed calculation (result or error) is on the display.
    /// Drives the authentic fx-991ES continuation behavior: a digit starts a
    /// fresh calculation, while + − × ÷ auto-insert the Ans command (manual E-25).
    @Published public var isShowingResult: Bool = false
    /// True while an intermediate result of a multi-statement (`:`) calculation
    /// is shown — lights the `Disp` annunciator on the LCD.
    @Published public var isShowingIntermediate: Bool = false
    /// Remaining statements of a multi-statement calculation, shown one per `=`.
    private var pendingStatements: [String] = []
    /// True while the result line shows a sexagesimal (degree-minute-second) value.
    @Published public var isShowingDMS: Bool = false
    // Key-capture states (STO / RCL / hyp wait for the next key, like the real key flow)
    @Published public var waitingForSto: Bool = false
    @Published public var waitingForRcl: Bool = false
    @Published public var waitingForHyp: Bool = false
    // ENG decimal-shift level and DRG▶ cycle step applied to the displayed result
    public var engLevel: Int = 0
    public var drgCycle: Int = 0

    // History
    public var history: [String] = []
    public var historyIndex: Int = -1

    // Variables: A, B, C, D, E, F, X, Y, M
    public var variables: [Character: Double] = [
        "A": 0, "B": 0, "C": 0, "D": 0, "E": 0, "F": 0, "X": 0, "Y": 0, "M": 0
    ] {
        didSet {
            hasMemory = (variables["M"] ?? 0) != 0
        }
    }
    public var lastAnswer: Double = 0
    public var lastComplexAnswer: Complex = .zero
    /// True while the display shows the last complex result (so ▶r∠θ / ▶a+bi
    /// commands and the SETUP complex format can reformat it without recomputing).
    @Published public var isShowingComplexResult: Bool = false

    // Specialized Mode Data
    public var matA = Matrix(rows: 3, cols: 3)
    public var matB = Matrix(rows: 3, cols: 3)
    public var matC = Matrix(rows: 3, cols: 3)
    public var matAns = Matrix(rows: 3, cols: 3)
    /// Matrices whose dimensions the user has confirmed (fx-991ES: an undefined
    /// matrix cannot be used in a calculation until Dim is set)
    public var definedMatrices: Set<String> = []
    /// Last matrix result, rendered as a grid on the LCD and stored in MatAns
    public var matrixResult: Matrix?

    public var vctA = VectorValue([0, 0, 0])
    public var vctB = VectorValue([0, 0, 0])
    public var vctC = VectorValue([0, 0, 0])
    public var vctAns = VectorValue([0, 0, 0])
    public var definedVectors: Set<String> = []
    public var vectorResult: VectorValue?

    public var statData: [(x: Double, y: Double, freq: Double)] = []
    public var statType: String = "1-VAR"

    public var tableRows: [(x: Double, fx: Double)] = []
    public var tableStartVal: Double = 1
    public var tableEndVal: Double = 5
    public var tableStepVal: Double = 1
    public var tableFormula: String = "X²"

    // EQN Mode Data
    public var eqnType: Int = 1
    public var eqnCoeffs: [Double] = []
    public var eqnSolutions: [String] = []
    public var eqnSolutionIndex: Int = 0

    public init() {}

    // MARK: - Power & Reset

    public func turnOn() {
        isOff = false
        clearAll()
    }

    public func turnOff() {
        isOff = true
    }

    public func clearAll() {
        expression = ""
        cursorPosition = 0
        astManager = MathASTManager()
        exactResult = nil
        matrixResult = nil
        vectorResult = nil
        isShowingComplexResult = false
        isShowingDecimal = false
        result = ""
        isError = false
        menuState = .none
        shiftActive = false
        alphaActive = false
        isShowingResult = false
        isShowingIntermediate = false
        pendingStatements = []
        isShowingDMS = false
        waitingForSto = false
        waitingForRcl = false
        waitingForHyp = false
        engLevel = 0
        drgCycle = 0
    }

    // MARK: - Result-State Transition (authentic fx-991ES continuation)

    /// Called before any input while a completed calculation is on the display.
    /// Digits/functions start a fresh calculation; + − × ÷ continue with the
    /// Ans command (fx-991ES manual E-25: "Pressing ÷ automatically inputs the
    /// 'Ans' command"). The stale result line is cleared like on the real LCD.
    private func beginInputIfShowingResult(autoAns: Bool = false) {
        guard isShowingResult else { return }
        isShowingResult = false
        isShowingIntermediate = false
        pendingStatements = []
        isShowingDMS = false
        astManager = MathASTManager()
        expression = ""
        cursorPosition = 0
        result = ""
        exactResult = nil
        matrixResult = nil
        vectorResult = nil
        isShowingComplexResult = false
        isShowingDecimal = false
        engLevel = 0
        drgCycle = 0
        if autoAns {
            astManager.insertText("Ans")
            expression = "Ans"
            cursorPosition = 3
        }
    }

    /// The four binary operator glyphs that continue from Ans after `=`.
    private static let ansContinuationOps: Set<String> = ["+", "−", "×", "÷"]

    public func resetAll() {
        clearAll()
        applySetupDefaults()
        activeMode = .comp
        baseNType = .dec
        variables = ["A": 0, "B": 0, "C": 0, "D": 0, "E": 0, "F": 0, "X": 0, "Y": 0, "M": 0]
        lastAnswer = 0
        lastComplexAnswer = .zero
        matA = Matrix(rows: 3, cols: 3)
        matB = Matrix(rows: 3, cols: 3)
        matC = Matrix(rows: 3, cols: 3)
        matAns = Matrix(rows: 3, cols: 3)
        definedMatrices = []
        matrixResult = nil
        vectorResult = nil
        isShowingComplexResult = false
        vctA = VectorValue([0, 0, 0])
        vctB = VectorValue([0, 0, 0])
        vctC = VectorValue([0, 0, 0])
        vctAns = VectorValue([0, 0, 0])
        definedVectors = []
        vectorResult = nil
        statData.removeAll()
        tableRows.removeAll()
        history.removeAll()
        historyIndex = -1
    }

    // MARK: - 2D AST Editing & Cursor Operations

    public func insertASTText(_ text: String) {
        guard baseNAllows(text) else { return }
        if isError {
            clearAll()
        }
        // fx-991ES: a bare + − × ÷ right after `=` continues from the answer
        beginInputIfShowingResult(autoAns: CalculatorEngine.ansContinuationOps.contains(text))
        astManager.insertText(text)
        expression = astManager.toLinearString()
        cursorPosition = expression.count
    }

    public func insertASTFraction() {
        if isError {
            clearAll()
        }
        beginInputIfShowingResult()
        astManager.insertFraction()
        expression = astManager.toLinearString()
        cursorPosition = expression.count
    }

    /// Mixed fraction template (SHIFT + a b/c on the fx-991ES).
    public func insertASTMixedFraction() {
        if isError {
            clearAll()
        }
        beginInputIfShowingResult()
        astManager.insertMixedFraction()
        expression = astManager.toLinearString()
        cursorPosition = expression.count
    }

    /// ° ' " key. During input: inserts one sexagesimal marker (d°m's" syntax —
    /// nothing is converted yet). On a displayed result: toggles the display
    /// between decimal and sexagesimal form (manual p.23) without changing Ans.
    public func insertDMSMark() {
        if isShowingResult {
            toggleResultDMS()
            return
        }
        if isError {
            clearAll()
        }
        astManager.insertDMSMark()
        expression = astManager.toLinearString()
        cursorPosition = expression.count
    }

    public func insertASTRadical() {
        if isError {
            clearAll()
        }
        beginInputIfShowingResult()
        astManager.insertRadical()
        expression = astManager.toLinearString()
        cursorPosition = expression.count
    }

    public func insertASTNthRoot() {
        if isError {
            clearAll()
        }
        beginInputIfShowingResult()
        astManager.insertNthRoot()
        expression = astManager.toLinearString()
        cursorPosition = expression.count
    }

    public func insertASTCubeRoot() {
        if isError {
            clearAll()
        }
        beginInputIfShowingResult()
        astManager.insertCubeRoot()
        expression = astManager.toLinearString()
        cursorPosition = expression.count
    }

    public func insertASTExponent() {
        if isError {
            clearAll()
        }
        beginInputIfShowingResult()
        astManager.insertExponent()
        expression = astManager.toLinearString()
        cursorPosition = expression.count
    }

    public func insertASTDerivative() {
        if isError {
            clearAll()
        }
        beginInputIfShowingResult()
        astManager.insertDerivative()
        expression = astManager.toLinearString()
        cursorPosition = expression.count
    }

    public func insertASTIntegral() {
        if isError {
            clearAll()
        }
        beginInputIfShowingResult()
        astManager.insertIntegral()
        expression = astManager.toLinearString()
        cursorPosition = expression.count
    }

    public func insertASTSummation() {
        if isError {
            clearAll()
        }
        beginInputIfShowingResult()
        astManager.insertSummation()
        expression = astManager.toLinearString()
        cursorPosition = expression.count
    }

    public func insertASTLogBase() {
        if isError {
            clearAll()
        }
        beginInputIfShowingResult()
        astManager.insertLogBase()
        expression = astManager.toLinearString()
        cursorPosition = expression.count
    }

    public func insertASTParens() {
        if isError {
            clearAll()
        }
        beginInputIfShowingResult()
        astManager.insertParens()
        expression = astManager.toLinearString()
        cursorPosition = expression.count
    }

    public func insertASTFunction(_ name: String) {
        if isError {
            clearAll()
        }
        beginInputIfShowingResult()
        astManager.insertFunction(name)
        expression = astManager.toLinearString()
        cursorPosition = expression.count
    }

    // MARK: - Backward-Compatible Linear Editing

    public func insert(_ text: String) {
        // Ignore further typing once the expression buffer is full, so a key
        // that fires repeatedly (e.g. held down) can never freeze the app.
        guard !astManager.isAtCapacity else { return }
        guard baseNAllows(text) else { return }
        if isError {
            isError = false
            expression = ""
            cursorPosition = 0
            astManager = MathASTManager()
            isShowingResult = false
        }
        // Same continuation rules as the 2D path: ops continue from Ans
        let firstOp = text.first.map { String($0) } ?? ""
        beginInputIfShowingResult(autoAns: CalculatorEngine.ansContinuationOps.contains(firstOp) && text.count == 1)

        // SHIFT+DEL (INS) overwrite mode: replace characters at the cursor
        // instead of inserting them (Linear Display only).
        if isOverwriteMode && !isMthIO {
            let chars = Array(expression)
            let pos = min(max(0, cursorPosition), chars.count)
            var newChars = chars
            for (offset, ch) in text.enumerated() {
                let idx = pos + offset
                if idx < newChars.count { newChars[idx] = ch } else { newChars.append(ch) }
            }
            expression = String(newChars)
            cursorPosition = min(pos + text.count, newChars.count)
            var fresh = MathASTManager()
            for ch in newChars { fresh.insertText(String(ch)) }
            astManager = fresh
            return
        }

        for char in text {
            astManager.insertText(String(char))
        }

        let chars = Array(expression)
        let pos = min(max(0, cursorPosition), chars.count)
        let prefix = String(chars[0..<pos])
        let suffix = String(chars[pos..<chars.count])

        expression = prefix + text + suffix
        cursorPosition = pos + text.count
    }

    public func delete() {
        if isError {
            clearAll()
            return
        }

        // DEL after `=` edits the previous expression (Replay, manual p.24)
        isShowingResult = false
        isShowingDMS = false

        if isMthIO && !astManager.root.isEmpty {
            astManager.delete()
            expression = astManager.toLinearString()
            cursorPosition = expression.count
            return
        }

        let chars = Array(expression)
        guard cursorPosition > 0 && !chars.isEmpty else { return }

        let pos = min(cursorPosition, chars.count)
        var newChars = chars
        newChars.remove(at: pos - 1)
        expression = String(newChars)
        cursorPosition = pos - 1
    }

    public func moveCursorLeft() {
        // ◄ after `=` replays/edits the previous expression (manual p.24)
        isShowingResult = false
        isShowingDMS = false
        astManager.moveLeft()
        if cursorPosition > 0 {
            cursorPosition -= 1
        }
    }

    public func moveCursorRight() {
        isShowingResult = false
        isShowingDMS = false
        astManager.moveRight()
        if cursorPosition < expression.count {
            cursorPosition += 1
        }
    }

    /// Move the linear (LineIO) insertion cursor to a tapped character index.
    public func setLinearCursorPosition(_ index: Int) {
        isShowingResult = false
        isShowingDMS = false
        cursorPosition = min(max(0, index), expression.count)
    }

    /// Move the 2D insertion cursor to a tapped position in the expression.
    public func moveCursor(to path: CursorPath) {
        isShowingResult = false
        isShowingDMS = false
        astManager.cursor = path
        cursorPosition = astManager.toLinearString().count
    }

    @discardableResult
    public func moveCursorUp() -> Bool {
        let oldSlot = astManager.cursor.slot
        let oldIndex = astManager.cursor.index
        astManager.moveUp()
        return astManager.cursor.slot != oldSlot || astManager.cursor.index != oldIndex
    }

    @discardableResult
    public func moveCursorDown() -> Bool {
        let oldSlot = astManager.cursor.slot
        let oldIndex = astManager.cursor.index
        astManager.moveDown()
        return astManager.cursor.slot != oldSlot || astManager.cursor.index != oldIndex
    }

    public func moveHistoryUp() {
        guard !history.isEmpty else { return }
        isShowingResult = false
        isShowingDMS = false
        if historyIndex == -1 {
            historyIndex = history.count - 1
        } else if historyIndex > 0 {
            historyIndex -= 1
        }
        expression = history[historyIndex]
        cursorPosition = expression.count
        astManager = MathASTManager()
        astManager.insertText(expression)
    }

    public func moveHistoryDown() {
        guard !history.isEmpty && historyIndex >= 0 else { return }
        isShowingResult = false
        isShowingDMS = false
        if historyIndex < history.count - 1 {
            historyIndex += 1
            expression = history[historyIndex]
            cursorPosition = expression.count
            astManager = MathASTManager()
            astManager.insertText(expression)
        } else {
            historyIndex = -1
            expression = ""
            cursorPosition = 0
            astManager = MathASTManager()
        }
    }

    // MARK: - Evaluation

    public func evaluate() {
        let fullExpression = astManager.root.isEmpty ? expression : astManager.toLinearString()
        guard !fullExpression.isEmpty else { return }

        // Multi-statement (`:`) calculations: each `=` reveals the next
        // intermediate result while the `Disp` annunciator is lit (ref §8.3).
        if !pendingStatements.isEmpty {
            let next = pendingStatements.removeFirst()
            evaluateSingle(next)
            isShowingIntermediate = !pendingStatements.isEmpty
            return
        }
        if fullExpression.contains(":") {
            let statements = fullExpression.components(separatedBy: ":").filter { !$0.isEmpty }
            if statements.count > 1 {
                pendingStatements = Array(statements.dropFirst())
                evaluateSingle(statements[0])
                isShowingIntermediate = true
                return
            }
        }

        isShowingIntermediate = false
        evaluateSingle(fullExpression)
    }

    /// Evaluate a single (already separated) expression and render its result.
    private func evaluateSingle(_ linear: String) {
        guard !linear.isEmpty else { return }

        // Append to history
        if history.last != linear {
            history.append(linear)
        }
        historyIndex = -1

        // A completed calculation (result or error) is now on the display
        isShowingResult = true
        isShowingDMS = false
        engLevel = 0
        drgCycle = 0

        // Expressions containing ° ' " markers display their result sexagesimally
        // (manual p.22: arithmetic involving sexagesimal values → sexagesimal result)
        let expressionHadDMS = linear.contains("°")
        // Decimal-keyed input stays decimal (manual p.21: mixing fractions and
        // decimal values → decimal result; only pure rational arithmetic
        // auto-fractionizes, e.g. 2.255 = shows 2.255, 1÷3 = shows 1⌸3)
        let expressionHadDecimal = linear.contains(".")

        if activeMode == .baseN {
            evaluateBaseN()
            shiftActive = false
            alphaActive = false
            return
        }

        // 0b. Vector-mode expressions (VctA, VctB, VctC, VctAns, Dot, Abs, ×)
        // are handled by the dedicated vector evaluator (manual §10).
        if linear.contains("Vct") {
            var vectors: [String: VectorValue] = [:]
            for name in ["VctA", "VctB", "VctC", "VctAns"] where definedVectors.contains(name) {
                vectors[name] = vectorValue(for: name)
            }
            let vEval = VectorEvaluator.evaluate(linear, vectors: vectors)
            isError = false
            if let err = vEval.error {
                isError = true
                exactResult = nil
                vectorResult = nil
                result = err
            } else if case .vector(let v)? = vEval.value {
                exactResult = nil
                vctAns = v
                definedVectors.insert("VctAns")
                vectorResult = v
                result = v.linearString
            } else if case .scalar(let s)? = vEval.value {
                exactResult = nil
                lastAnswer = s
                isShowingDecimal = true
                result = formatNumber(s)
            }
            shiftActive = false
            alphaActive = false
            return
        }

        // 0. Matrix-mode expressions (MatA, MatB, MatC, MatAns, det(, Trn()
        // cannot be evaluated by the numeric/exact engines. Undefined matrices
        // are left out of the lookup so using them reports Dim ERROR (manual p.47).
        if linear.contains("Mat") {
            var matrices: [String: Matrix] = [:]
            for name in ["MatA", "MatB", "MatC", "MatAns"] where definedMatrices.contains(name) {
                matrices[name] = matrixValue(for: name)
            }
            let mEval = MatrixEvaluator.evaluate(linear, matrices: matrices)
            isError = false
            if let err = mEval.error {
                isError = true
                exactResult = nil
                matrixResult = nil
                vectorResult = nil
                isShowingComplexResult = false
                result = err
            } else if case .matrix(let m)? = mEval.value {
                // Matrix results are stored in MatAns and shown as a grid
                exactResult = nil
                matAns = m
                definedMatrices.insert("MatAns")
                matrixResult = m
                result = m.toLinearString()
            } else if case .scalar(let s)? = mEval.value {
                // Scalar results (e.g. det(MatA)) behave like normal numbers
                exactResult = nil
                matrixResult = nil
                vectorResult = nil
                isShowingComplexResult = false
                lastAnswer = s
                isShowingDecimal = true
                result = formatNumber(s)
            }
            shiftActive = false
            alphaActive = false
            return
        }

        // Any non-matrix calculation supersedes a previous matrix result
        matrixResult = nil
        vectorResult = nil
        isShowingComplexResult = false

        // 1. Try Exact Symbolic Evaluation (Natural-V.P.A.M.)
        if !astManager.root.isEmpty,
           let exactVal = ExactEvaluator.evaluate(nodes: astManager.root, angleUnit: angleUnit, ans: lastAnswer, variables: variables) {
            exactResult = exactVal
            lastAnswer = exactVal.toDouble()
            isShowingDecimal = !isMthIO
            isError = false
            if expressionHadDMS {
                isShowingDMS = true
                result = CasioEvaluator.formatSexagesimal(lastAnswer)
            } else if expressionHadDecimal {
                isShowingDecimal = true
                result = formatNumber(exactVal.toDouble())
            } else {
                result = isShowingDecimal ? formatNumber(exactVal.toDouble()) : exactVal.toLinearString()
            }
            shiftActive = false
            alphaActive = false
            return
        }

        // 2. Numerical / Floating Point / Complex Evaluation
        let eval = CasioEvaluator.evaluate(
            linear,
            angleUnit: angleUnit,
            variables: variables,
            lastAnswer: lastAnswer,
            isCmplx: activeMode == .cmplx
        )

        if let err = eval.error {
            isError = true
            exactResult = nil
            result = err
        } else if let cVal = eval.complexValue, activeMode == .cmplx {
            isError = false
            exactResult = nil
            lastComplexAnswer = cVal
            lastAnswer = cVal.real
            isShowingComplexResult = true
            result = formatComplex(cVal)
        } else if let val = eval.value {
            isError = false
            lastAnswer = val
            // Check if can be represented as an exact fraction in MthIO mode (skip if transcendental pi or e present)
            let hasTranscendental = linear.contains("π") || linear.contains("e")
            if expressionHadDMS {
                exactResult = nil
                isShowingDMS = true
                result = CasioEvaluator.formatSexagesimal(val)
            } else if !hasTranscendental, !expressionHadDecimal, let frac = Fraction.fromDouble(val), frac.den > 1 && frac.den <= 10000 && isMthIO {
                let exactFrac = ExactValue.rational(Rational(frac.num, frac.den))
                exactResult = exactFrac
                isShowingDecimal = false
                result = exactFrac.toLinearString()
            } else {
                exactResult = nil
                isShowingDecimal = true
                result = formatNumber(val)
            }
        }

        shiftActive = false
        alphaActive = false
    }

    // BASE-N implementation lives in BaseNMode.swift

    // MARK: - Modifiers

    public func toggleShift() {
        shiftActive.toggle()
        if shiftActive { alphaActive = false }
    }

    public func toggleAlpha() {
        alphaActive.toggle()
        if alphaActive { shiftActive = false }
    }

    /// SHIFT + DEL (INS): toggle insert/overwrite editing in Linear Display.
    /// Natural Display is always insert mode, so the flag is ignored there.
    public func toggleInsertOverwrite() {
        guard !isMthIO else { return }
        isOverwriteMode.toggle()
    }

    // MARK: - Menus & Modes

    public func openModeMenu() {
        menuState = (menuState == .modeMenu) ? .none : .modeMenu
    }

    public func openSetupMenu(page: Int = 1) {
        menuState = .setupMenu(page: page)
    }

    public func selectMenuOption(_ number: Int) {
        switch menuState {
        case .modeMenu:
            switch number {
            case 0:
                menuState = .authenticityView
                return
            case 1: activeMode = .comp
            case 2: activeMode = .cmplx
            case 3: activeMode = .stat; isMthIO = false; openStatTypeMenu()
            case 4: activeMode = .baseN; isMthIO = false
            case 5: activeMode = .eqn; openEqnTypeMenu()
            case 6: activeMode = .matrix; isMthIO = false; openMatrixMenu()
            case 7: activeMode = .table; startTable()
            case 8: activeMode = .vector; isMthIO = false; openVectorMenu()
            default: break
            }
            if menuState == .modeMenu { menuState = .none }

        case .setupMenu, .mthIOMenu, .fixPrompt, .sciPrompt, .normPrompt,
             .dispFormatMenu, .statFreqMenu, .contrastPrompt, .cmplxFormatMenu:
            handleSetupSelection(number)

        case .eqnTypeMenu:
            startEqn(type: number)

        case .clrPrompt:
            switch number {
            case 1: // Reset Setup — restore all SETUP preferences (guide §3.7)
                applySetupDefaults()
            case 2: // Reset Memory
                variables = ["A": 0, "B": 0, "C": 0, "D": 0, "E": 0, "F": 0, "X": 0, "Y": 0, "M": 0]
                lastAnswer = 0
            case 3: // Reset All
                resetAll()
            default: break
            }
            menuState = .none

        case .statTypeMenu:
            switch number {
            case 1: statType = "1-VAR"
            case 2: statType = "A+BX"
            case 3: statType = "_+CX²"
            case 4: statType = "ln X"
            case 5: statType = "e^X"
            case 6: statType = "A·B^X"
            case 7: statType = "A·X^B"
            case 8: statType = "1/X"
            default: break
            }
            statData.removeAll()
            openStatEditor()   // the statistics editor opens after choosing a type (manual §6.2)

        case .statSubMenu:
            handleStatMenuOption(number)

        case .cmplxMenu:
            handleComplexMenuOption(number)

        case .matrixMenu:
            switch number {
            case 1: menuState = .matrixDimSelect
            case 2: menuState = .matrixDataSelect
            case 3: insertMatrixToken("MatA"); menuState = .none
            case 4: insertMatrixToken("MatB"); menuState = .none
            case 5: insertMatrixToken("MatC"); menuState = .none
            case 6: insertMatrixToken("MatAns"); menuState = .none
            case 7: insertMatrixToken("det("); menuState = .none
            case 8: insertMatrixToken("Trn("); menuState = .none
            default: break
            }

        case .matrixDimSelect:
            switch number {
            case 1: openMatrixNamed("MatA")
            case 2: openMatrixNamed("MatB")
            case 3: openMatrixNamed("MatC")
            default: menuState = .none
            }

        case .matrixDataSelect:
            switch number {
            case 1: openMatrixNamed("MatA", dataMode: true)
            case 2: openMatrixNamed("MatB", dataMode: true)
            case 3: openMatrixNamed("MatC", dataMode: true)
            default: menuState = .none
            }

        case .vectorMenu:
            handleVectorMenuOption(number)

        case .vectorDimSelect:
            switch number {
            case 1: openVectorNamed("VctA")
            case 2: openVectorNamed("VctB")
            case 3: openVectorNamed("VctC")
            default: menuState = .none
            }

        case .vectorDataSelect:
            switch number {
            case 1: openVectorNamed("VctA", dataMode: true)
            case 2: openVectorNamed("VctB", dataMode: true)
            case 3: openVectorNamed("VctC", dataMode: true)
            default: menuState = .none
            }

        default:
            menuState = .none
        }
    }

    // MARK: - Memory Operations

    public func storeToVariable(_ varName: Character) {
        // Store the actual calculated value (the display may hold a fraction or
        // sexagesimal form that doesn't parse back as a number)
        let val = lastAnswer
        variables[varName] = val
        result = "\(varName)=\(formatNumber(val))"
    }

    public func recallVariable(_ varName: Character) {
        let val = variables[varName] ?? 0
        insert(CasioEvaluator.format(val, format: .norm))
    }

    public func addMemory() {
        variables["M"] = (variables["M"] ?? 0) + lastAnswer
    }

    public func subtractMemory() {
        variables["M"] = (variables["M"] ?? 0) - lastAnswer
    }

    /// STO / RCL / variable key flow: with a capture state active the next
    /// variable key stores or recalls instead of typing its letter (the real
    /// key flow — no ALPHA press needed).
    public func handleVariableSelection(_ varName: Character) {
        if waitingForSto {
            waitingForSto = false
            storeToVariable(varName)
        } else if waitingForRcl {
            waitingForRcl = false
            recallVariable(varName)
        } else {
            if isMthIO {
                insertASTText(String(varName))
            } else {
                insert(String(varName))
            }
        }
    }

    // MARK: - Specialized Function Actions

    public func toggleSD() {
        if isShowingDMS {
            // S⇔D also clears the sexagesimal display back to decimal/exact
            isShowingDMS = false
        }
        if let exact = exactResult {
            isShowingDecimal.toggle()
            if isShowingDecimal {
                result = formatNumber(exact.toDouble())
            } else {
                result = exact.toLinearString()
            }
            return
        }

        switch displayFormat {
        case .norm:
            displayFormat = .fraction
        case .fraction:
            displayFormat = .mixedFraction
        case .mixedFraction:
            displayFormat = .norm
        default:
            displayFormat = .norm
        }
        if !isError, let val = Double(result.replacingOccurrences(of: "×10^", with: "e")) {
            result = formatNumber(val)
        }
    }

    /// SHIFT + fraction key (d/c): apply the improper-fraction result format
    /// command. Converts a mixed fraction result to its improper d/c form.
    public func applyImproperFractionFormat() {
        guard isShowingResult, !isError else { return }
        fractionDisplay = .improper
        if let exact = exactResult {
            isShowingDecimal = false
            result = exact.toLinearString()
        } else if let val = Double(result.replacingOccurrences(of: "×10^", with: "e")) {
            result = CasioEvaluator.format(val, format: .fraction)
        }
    }

    /// SHIFT + S⇔D (a b/c ⇔ d/c): toggles the displayed fraction between
    /// improper and mixed form (manual p.21).
    public func toggleImproperMixed() {
        guard isShowingResult, !isError else { return }
        displayFormat = (displayFormat == .mixedFraction) ? .fraction : .mixedFraction
        if let exact = exactResult, !isShowingDecimal, isMthIO {
            // Exact 2D render picks up the mixed flag in the view; also refresh
            // the linear fallback string
            result = exact.toLinearString()
        } else if let val = Double(result.replacingOccurrences(of: "×10^", with: "e")) {
            result = formatNumber(val)
        }
    }

    /// ° ' " on a displayed result: toggles decimal ⇔ sexagesimal display.
    /// The underlying value (Ans) is never modified (manual p.23).
    public func toggleResultDMS() {
        guard isShowingResult, !isError, activeMode != .cmplx else { return }
        isShowingDMS.toggle()
        if isShowingDMS {
            result = CasioEvaluator.formatSexagesimal(lastAnswer)
        } else if let exact = exactResult, isMthIO, !isShowingDecimal {
            result = exact.toLinearString()
        } else {
            result = formatNumber(lastAnswer)
        }
    }

    /// ENG key: shifts the decimal point of the displayed result three places
    /// (engineering notation); SHIFT+ENG (←) shifts back (manual p.24).
    public func shiftEng(left: Bool) {
        guard isShowingResult, !isError, lastAnswer != 0, lastAnswer.isFinite else { return }
        if left {
            engLevel = max(0, engLevel - 1)
        } else {
            engLevel += 1
        }
        result = CasioEvaluator.formatEng(lastAnswer, level: engLevel)
    }

    /// DRG▶ (SHIFT+Ans): converts the displayed result into the next angle unit
    /// (Deg → Rad → Gra → Deg) without changing the calculator's angle unit.
    public func convertResultAngleUnit() {
        guard isShowingResult, !isError, lastAnswer.isFinite else { return }
        let units: [AngleUnit] = [.deg, .rad, .gra]
        guard let currentIdx = units.firstIndex(of: angleUnit) else { return }
        drgCycle += 1
        let target = units[(currentIdx + drgCycle) % 3]
        let converted = target.fromRadians(angleUnit.toRadians(lastAnswer))
        result = formatNumber(converted)
    }

    /// Rnd (SHIFT+0): rounds the displayed value to the display's digit capacity,
    /// so subsequent calculations use exactly what is shown (manual p.24).
    public func roundDisplayed() {
        guard isShowingResult, !isError, lastAnswer.isFinite else { return }
        let rounded: Double
        switch displayFormat {
        case .fix(let d):
            let factor = Foundation.pow(10.0, Double(d))
            rounded = (lastAnswer * factor).rounded() / factor
        case .sci(let d):
            let digits = max(1, d)
            let exp = Foundation.floor(Foundation.log10(abs(lastAnswer)))
            let factor = Foundation.pow(10.0, Double(digits - 1) - exp)
            rounded = (lastAnswer * factor).rounded() / factor
        default:
            let factor = Foundation.pow(10.0, 9.0 - Foundation.floor(Foundation.log10(abs(lastAnswer))))
            rounded = (lastAnswer * factor).rounded() / factor
        }
        lastAnswer = rounded
        result = formatNumber(rounded)
    }

    /// SHIFT + 3 (BASE-N): enters BASE-N mode with decimal base. BASE-N always
    /// uses Linear Display (reference §10).
    public func enterBaseNMode() {
        activeMode = .baseN
        baseNType = .dec
        isMthIO = false
    }

    public func primeFactorize() {
        let val = lastAnswer
        if val > 1, val <= 10000000000, val.rounded() == val {
            if let fact = CasioEvaluator.primeFactorization(Int64(val)) {
                isShowingDMS = false
                exactResult = nil
                result = fact
            }
        }
    }

    public func insertConstant(code: Int) {
        if let c = CasioConstants.get(code) {
            insert("\(c.value)")
        }
    }

    public func applyConversion(code: Int) {
        guard lastAnswer.isFinite else { return }
        if let conv = CasioConversions.convert(value: lastAnswer, code: code) {
            lastAnswer = conv.result
            isShowingDMS = false
            exactResult = nil
            result = formatNumber(conv.result)
        }
    }

    // EQN helpers live in EquationMode.swift

    // MATRIX helpers live in MatrixMode.swift

    // TABLE helpers live in TableMode.swift

    private func openStatTypeMenu() {
        menuState = .statTypeMenu
    }

    private func openEqnTypeMenu() {
        menuState = .eqnTypeMenu
    }

    private func openMatrixMenu() {
        menuState = .matrixMenu
    }

    private func openVectorMenu() {
        menuState = .vectorMenu
    }
}
