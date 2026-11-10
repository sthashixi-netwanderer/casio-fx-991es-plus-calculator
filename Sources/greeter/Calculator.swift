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

public enum CalcMode: String, CaseIterable, Sendable {
    case comp = "COMP"
    case cmplx = "CMPLX"
    case stat = "STAT"
    case baseN = "BASE-N"
    case eqn = "EQN"
    case matrix = "MATRIX"
    case table = "TABLE"
    case vector = "VECTOR"
}

public enum BaseNType: String, CaseIterable, Sendable {
    case dec = "d"
    case hex = "H"
    case bin = "b"
    case oct = "o"
}

public enum MenuState: Equatable, Sendable {
    case none
    case modeMenu
    case setupMenu(page: Int)
    case mthIOMenu
    case fixPrompt
    case sciPrompt
    case clrPrompt
    case constPrompt
    case convPrompt
    case statTypeMenu
    case statSubMenu
    case cmplxMenu
    case eqnTypeMenu
    case eqnCoeffPrompt(type: Int, coeffName: String, coeffIndex: Int)
    case eqnSolutionView(solutions: [String], index: Int)
    case matrixMenu
    case vectorMenu
    case tablePrompt(step: Int)
    case calcPrompt(varName: Character, remainingVars: [Character])
    case solvePrompt(initialGuess: Double)
    case solveResult(root: Double, residual: Double)
    case authenticityView
}

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

// MARK: - Complex Number Representation

public struct Complex: Equatable, CustomStringConvertible, Sendable {
    public var real: Double
    public var imag: Double

    public init(real: Double, imag: Double = 0) {
        self.real = real
        self.imag = imag
    }

    public static let zero = Complex(real: 0, imag: 0)
    public static let i = Complex(real: 0, imag: 1)

    public var magnitude: Double {
        Foundation.sqrt(real * real + imag * imag)
    }

    public func argument(angleUnit: AngleUnit = .deg) -> Double {
        let rad = Foundation.atan2(imag, real)
        return angleUnit.fromRadians(rad)
    }

    public var conjugate: Complex {
        Complex(real: real, imag: -imag)
    }

    public static func + (lhs: Complex, rhs: Complex) -> Complex {
        Complex(real: lhs.real + rhs.real, imag: lhs.imag + rhs.imag)
    }

    public static func - (lhs: Complex, rhs: Complex) -> Complex {
        Complex(real: lhs.real - rhs.real, imag: lhs.imag - rhs.imag)
    }

    public static func * (lhs: Complex, rhs: Complex) -> Complex {
        Complex(
            real: lhs.real * rhs.real - lhs.imag * rhs.imag,
            imag: lhs.real * rhs.imag + lhs.imag * rhs.real
        )
    }

    public static func / (lhs: Complex, rhs: Complex) -> Complex? {
        let denom = rhs.real * rhs.real + rhs.imag * rhs.imag
        guard denom != 0 else { return nil }
        return Complex(
            real: (lhs.real * rhs.real + lhs.imag * rhs.imag) / denom,
            imag: (lhs.imag * rhs.real - lhs.real * rhs.imag) / denom
        )
    }

    public var description: String {
        formatRectangular()
    }

    public func formatRectangular() -> String {
        if abs(imag) < 1e-12 {
            return CasioEvaluator.format(real, format: .norm)
        }
        if abs(real) < 1e-12 {
            let iStr = abs(imag - 1.0) < 1e-12 ? "i" : (abs(imag + 1.0) < 1e-12 ? "-i" : "\(CasioEvaluator.format(imag, format: .norm))i")
            return iStr
        }
        let sign = imag >= 0 ? "+" : "−"
        let absImag = abs(imag)
        let imagPart = abs(absImag - 1.0) < 1e-12 ? "i" : "\(CasioEvaluator.format(absImag, format: .norm))i"
        return "\(CasioEvaluator.format(real, format: .norm))\(sign)\(imagPart)"
    }

    public func formatPolar(angleUnit: AngleUnit) -> String {
        let r = magnitude
        let theta = argument(angleUnit: angleUnit)
        return "\(CasioEvaluator.format(r, format: .norm))∠\(CasioEvaluator.format(theta, format: .norm))"
    }
}

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

// MARK: - Matrix & Vector Types

public struct Matrix: Equatable, Sendable {
    public var rows: Int
    public var cols: Int
    public var elements: [[Double]]

    public init(rows: Int, cols: Int, initial: Double = 0) {
        self.rows = max(1, min(3, rows))
        self.cols = max(1, min(3, cols))
        self.elements = Array(repeating: Array(repeating: initial, count: self.cols), count: self.rows)
    }

    public init(elements: [[Double]]) {
        self.rows = elements.count
        self.cols = elements.first?.count ?? 0
        self.elements = elements
    }

    public func determinant() -> Double? {
        guard rows == cols else { return nil }
        if rows == 1 { return elements[0][0] }
        if rows == 2 {
            return elements[0][0] * elements[1][1] - elements[0][1] * elements[1][0]
        }
        if rows == 3 {
            let a = elements[0][0], b = elements[0][1], c = elements[0][2]
            let d = elements[1][0], e = elements[1][1], f = elements[1][2]
            let g = elements[2][0], h = elements[2][1], i = elements[2][2]
            return a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g)
        }
        return nil
    }

    public func transpose() -> Matrix {
        var result = Matrix(rows: cols, cols: rows)
        for r in 0..<rows {
            for c in 0..<cols {
                result.elements[c][r] = elements[r][c]
            }
        }
        return result
    }

    public func inverse() -> Matrix? {
        guard rows == cols, let det = determinant(), abs(det) > 1e-12 else { return nil }
        if rows == 1 {
            return Matrix(elements: [[1.0 / det]])
        }
        if rows == 2 {
            return Matrix(elements: [
                [elements[1][1] / det, -elements[0][1] / det],
                [-elements[1][0] / det, elements[0][0] / det]
            ])
        }
        if rows == 3 {
            let a = elements[0][0], b = elements[0][1], c = elements[0][2]
            let d = elements[1][0], e = elements[1][1], f = elements[1][2]
            let g = elements[2][0], h = elements[2][1], i = elements[2][2]

            let inv: [[Double]] = [
                [(e * i - f * h) / det, (c * h - b * i) / det, (b * f - c * e) / det],
                [(f * g - d * i) / det, (a * i - c * g) / det, (c * d - a * f) / det],
                [(d * h - e * g) / det, (g * b - a * h) / det, (a * e - b * d) / det]
            ]
            return Matrix(elements: inv)
        }
        return nil
    }

    public static func + (lhs: Matrix, rhs: Matrix) -> Matrix? {
        guard lhs.rows == rhs.rows && lhs.cols == rhs.cols else { return nil }
        var res = Matrix(rows: lhs.rows, cols: lhs.cols)
        for r in 0..<lhs.rows {
            for c in 0..<lhs.cols {
                res.elements[r][c] = lhs.elements[r][c] + rhs.elements[r][c]
            }
        }
        return res
    }

    public static func - (lhs: Matrix, rhs: Matrix) -> Matrix? {
        guard lhs.rows == rhs.rows && lhs.cols == rhs.cols else { return nil }
        var res = Matrix(rows: lhs.rows, cols: lhs.cols)
        for r in 0..<lhs.rows {
            for c in 0..<lhs.cols {
                res.elements[r][c] = lhs.elements[r][c] - rhs.elements[r][c]
            }
        }
        return res
    }

    public static func * (lhs: Matrix, rhs: Matrix) -> Matrix? {
        guard lhs.cols == rhs.rows else { return nil }
        var res = Matrix(rows: lhs.rows, cols: rhs.cols)
        for r in 0..<lhs.rows {
            for c in 0..<rhs.cols {
                var sum = 0.0
                for k in 0..<lhs.cols {
                    sum += lhs.elements[r][k] * rhs.elements[k][c]
                }
                res.elements[r][c] = sum
            }
        }
        return res
    }
}

public struct Vector3D: Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var z: Double

    public init(x: Double = 0, y: Double = 0, z: Double = 0) {
        self.x = x
        self.y = y
        self.z = z
    }

    public var magnitude: Double {
        Foundation.sqrt(x * x + y * y + z * z)
    }

    public static func + (lhs: Vector3D, rhs: Vector3D) -> Vector3D {
        Vector3D(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
    }

    public static func - (lhs: Vector3D, rhs: Vector3D) -> Vector3D {
        Vector3D(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
    }

    public static func dot(_ lhs: Vector3D, _ rhs: Vector3D) -> Double {
        lhs.x * rhs.x + lhs.y * rhs.y + lhs.z * rhs.z
    }

    public static func cross(_ lhs: Vector3D, _ rhs: Vector3D) -> Vector3D {
        Vector3D(
            x: lhs.y * rhs.z - lhs.z * rhs.y,
            y: lhs.z * rhs.x - lhs.x * rhs.z,
            z: lhs.x * rhs.y - lhs.y * rhs.x
        )
    }
}

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
            if c == "°" {
                tokens.append(.postfixOp("°"))
                i += 1
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

            // Variables (A, B, C, D, E, F, X, Y, M)
            if ["A", "B", "C", "D", "E", "F", "X", "Y", "M"].contains(c) &&
                (i + 1 == chars.count || !chars[i + 1].isLetter) {
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
                } else if ["nPr", "nCr", "and", "or", "xor", "xnor"].contains(word) {
                    tokens.append(.binaryOp(word, 2, false))
                } else if word == "Not" {
                    tokens.append(.prefixFunc("Not"))
                } else if word == "Neg" {
                    tokens.append(.prefixFunc("Neg"))
                } else if word == "RanInt" {
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
                case "°":
                    stack.append(angleUnit.toRadians(val))
                default:
                    return EvalResult(error: "Syntax ERROR")
                }

            case .prefixFunc(let f):
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

    public static func toDMS(_ val: Double) -> String {
        let absVal = abs(val)
        let deg = Int(floor(absVal))
        let remMin = (absVal - Double(deg)) * 60.0
        let min = Int(floor(remMin))
        let sec = (remMin - Double(min)) * 60.0
        let sign = val < 0 ? "−" : ""
        return "\(sign)\(deg)°\(min)′\(String(format: "%.2g", sec))″"
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

    public static func solveQuadratic(a: Double, b: Double, c: Double) -> [String] {
        guard a != 0 else {
            if b != 0 {
                return ["X=\(format(-c / b, format: .norm))"]
            }
            return ["No Solution"]
        }
        let disc = b * b - 4 * a * c
        if disc >= 0 {
            let sqrtD = Foundation.sqrt(disc)
            let x1 = (-b + sqrtD) / (2 * a)
            let x2 = (-b - sqrtD) / (2 * a)
            if abs(disc) < 1e-12 {
                return ["X=\(format(x1, format: .norm))"]
            }
            return [
                "X1=\(format(x1, format: .norm))",
                "X2=\(format(x2, format: .norm))"
            ]
        } else {
            let realPart = -b / (2 * a)
            let imagPart = Foundation.sqrt(-disc) / (2 * a)
            let c1 = Complex(real: realPart, imag: imagPart)
            let c2 = Complex(real: realPart, imag: -imagPart)
            return [
                "X1=\(c1.formatRectangular())",
                "X2=\(c2.formatRectangular())"
            ]
        }
    }

    public static func solveSimultaneous2(a1: Double, b1: Double, c1: Double, a2: Double, b2: Double, c2: Double) -> [String] {
        let d = a1 * b2 - a2 * b1
        guard abs(d) > 1e-12 else {
            return ["Infinite/No Sol"]
        }
        let x = (c1 * b2 - c2 * b1) / d
        let y = (a1 * c2 - a2 * c1) / d
        return [
            "X=\(format(x, format: .norm))",
            "Y=\(format(y, format: .norm))"
        ]
    }

    public static func solveSimultaneous3(
        a1: Double, b1: Double, c1: Double, d1: Double,
        a2: Double, b2: Double, c2: Double, d2: Double,
        a3: Double, b3: Double, c3: Double, d3: Double
    ) -> [String] {
        let matA = Matrix(elements: [
            [a1, b1, c1],
            [a2, b2, c2],
            [a3, b3, c3]
        ])
        guard let det = matA.determinant(), abs(det) > 1e-12 else {
            return ["Infinite/No Sol"]
        }
        let matDx = Matrix(elements: [
            [d1, b1, c1],
            [d2, b2, c2],
            [d3, b3, c3]
        ])
        let matDy = Matrix(elements: [
            [a1, d1, c1],
            [a2, d2, c2],
            [a3, d3, c3]
        ])
        let matDz = Matrix(elements: [
            [a1, b1, d1],
            [a2, b2, d2],
            [a3, b3, d3]
        ])
        let x = (matDx.determinant() ?? 0) / det
        let y = (matDy.determinant() ?? 0) / det
        let z = (matDz.determinant() ?? 0) / det
        return [
            "X=\(format(x, format: .norm))",
            "Y=\(format(y, format: .norm))",
            "Z=\(format(z, format: .norm))"
        ]
    }

    public static func solveCubic(a: Double, b: Double, c: Double, d: Double) -> [String] {
        guard a != 0 else {
            return solveQuadratic(a: b, b: c, c: d)
        }
        var x0 = 0.0
        for trial in [-10.0, -1.0, 0.0, 1.0, 10.0] {
            var x = trial
            for _ in 0..<50 {
                let fx = a * x * x * x + b * x * x + c * x + d
                let dfx = 3 * a * x * x + 2 * b * x + c
                if abs(dfx) < 1e-12 { break }
                let xNext = x - fx / dfx
                if abs(xNext - x) < 1e-9 {
                    x0 = xNext
                    break
                }
                x = xNext
            }
            if abs(a * x0 * x0 * x0 + b * x0 * x0 + c * x0 + d) < 1e-5 {
                break
            }
        }
        let a2 = a
        let b2 = b + a2 * x0
        let c2 = c + b2 * x0
        let quadRoots = solveQuadratic(a: a2, b: b2, c: c2)
        return ["X1=\(format(x0, format: .norm))"] + quadRoots.enumerated().map { (idx, rootStr) in
            let num = idx + 2
            let val = rootStr.components(separatedBy: "=").last ?? rootStr
            return "X\(num)=\(val)"
        }
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
    @Published public var result: String = "0"
    @Published public var angleUnit: AngleUnit = .deg
    @Published public var displayFormat: DisplayFormat = .norm
    @Published public var activeMode: CalcMode = .comp
    @Published public var menuState: MenuState = .none

    @Published public var baseNType: BaseNType = .dec
    @Published public var shiftActive: Bool = false
    @Published public var alphaActive: Bool = false
    @Published public var hasMemory: Bool = false
    @Published public var isError: Bool = false
    @Published public var isOff: Bool = false

    // Natural-V.P.A.M. 2D AST & Exact Symbolic State
    @Published public var astManager: MathASTManager = MathASTManager()
    @Published public var exactResult: ExactValue? = nil
    @Published public var isShowingDecimal: Bool = false
    @Published public var isMthIO: Bool = true

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

    // Specialized Mode Data
    public var matA = Matrix(rows: 3, cols: 3)
    public var matB = Matrix(rows: 3, cols: 3)
    public var matC = Matrix(rows: 3, cols: 3)
    public var matAns = Matrix(rows: 3, cols: 3)

    public var vctA = Vector3D()
    public var vctB = Vector3D()
    public var vctC = Vector3D()
    public var vctAns = Vector3D()

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
        isShowingDecimal = false
        result = "0"
        isError = false
        menuState = .none
        shiftActive = false
        alphaActive = false
    }

    public func resetAll() {
        clearAll()
        angleUnit = .deg
        displayFormat = .norm
        activeMode = .comp
        baseNType = .dec
        isMthIO = true
        variables = ["A": 0, "B": 0, "C": 0, "D": 0, "E": 0, "F": 0, "X": 0, "Y": 0, "M": 0]
        lastAnswer = 0
        lastComplexAnswer = .zero
        statData.removeAll()
        tableRows.removeAll()
        history.removeAll()
        historyIndex = -1
    }

    // MARK: - 2D AST Editing & Cursor Operations

    public func insertASTText(_ text: String) {
        if isError {
            clearAll()
        }
        astManager.insertText(text)
        expression = astManager.toLinearString()
        cursorPosition = astManager.cursor.index
    }

    public func insertASTFraction() {
        if isError {
            clearAll()
        }
        astManager.insertFraction()
        expression = astManager.toLinearString()
        cursorPosition = astManager.cursor.index
    }

    public func insertASTRadical() {
        if isError {
            clearAll()
        }
        astManager.insertRadical()
        expression = astManager.toLinearString()
        cursorPosition = astManager.cursor.index
    }

    public func insertASTExponent() {
        if isError {
            clearAll()
        }
        astManager.insertExponent()
        expression = astManager.toLinearString()
        cursorPosition = astManager.cursor.index
    }

    public func insertASTIntegral() {
        if isError {
            clearAll()
        }
        astManager.insertIntegral()
        expression = astManager.toLinearString()
        cursorPosition = astManager.cursor.index
    }

    public func insertASTSummation() {
        if isError {
            clearAll()
        }
        astManager.insertSummation()
        expression = astManager.toLinearString()
        cursorPosition = astManager.cursor.index
    }

    public func insertASTLogBase() {
        if isError {
            clearAll()
        }
        astManager.insertLogBase()
        expression = astManager.toLinearString()
        cursorPosition = astManager.cursor.index
    }

    public func insertASTParens() {
        if isError {
            clearAll()
        }
        astManager.insertParens()
        expression = astManager.toLinearString()
        cursorPosition = astManager.cursor.index
    }

    public func insertASTFunction(_ name: String) {
        if isError {
            clearAll()
        }
        astManager.insertFunction(name)
        expression = astManager.toLinearString()
        cursorPosition = astManager.cursor.index
    }

    // MARK: - Backward-Compatible Linear Editing

    public func insert(_ text: String) {
        if isError {
            isError = false
            expression = ""
            cursorPosition = 0
            astManager = MathASTManager()
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

        if !astManager.root.isEmpty {
            astManager.delete()
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
        astManager.moveLeft()
        if cursorPosition > 0 {
            cursorPosition -= 1
        }
    }

    public func moveCursorRight() {
        astManager.moveRight()
        if cursorPosition < expression.count {
            cursorPosition += 1
        }
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
        let linear = astManager.root.isEmpty ? expression : astManager.toLinearString()
        guard !linear.isEmpty else { return }

        // Append to history
        if history.last != linear {
            history.append(linear)
        }
        historyIndex = -1

        if activeMode == .baseN {
            evaluateBaseN()
            shiftActive = false
            alphaActive = false
            return
        }

        // 1. Try Exact Symbolic Evaluation (Natural-V.P.A.M.)
        if !astManager.root.isEmpty, let exactVal = ExactEvaluator.evaluate(nodes: astManager.root, angleUnit: angleUnit) {
            exactResult = exactVal
            lastAnswer = exactVal.toDouble()
            isShowingDecimal = !isMthIO
            result = isShowingDecimal ? CasioEvaluator.format(exactVal.toDouble(), format: displayFormat) : exactVal.toLinearString()
            isError = false
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
            result = cVal.formatRectangular()
        } else if let val = eval.value {
            isError = false
            lastAnswer = val
            // Check if can be represented as an exact fraction in MthIO mode
            if let frac = Fraction.fromDouble(val), frac.den > 1 && frac.den <= 10000 && isMthIO {
                let exactFrac = ExactValue.rational(Rational(frac.num, frac.den))
                exactResult = exactFrac
                isShowingDecimal = false
                result = exactFrac.toLinearString()
            } else {
                exactResult = nil
                isShowingDecimal = true
                result = CasioEvaluator.format(val, format: displayFormat)
            }
        }

        shiftActive = false
        alphaActive = false
    }

    private func evaluateBaseN() {
        // Base-N evaluation: convert input according to baseNType
        let eval = CasioEvaluator.evaluate(expression, angleUnit: .deg, variables: [:], lastAnswer: lastAnswer)
        if let err = eval.error {
            isError = true
            result = err
            return
        }
        guard let val = eval.value else {
            isError = true
            result = "Syntax ERROR"
            return
        }
        let intVal = Int32(truncatingIfNeeded: Int64(val))
        lastAnswer = Double(intVal)
        isError = false
        result = formatBaseN(intVal, base: baseNType)
    }

    public func formatBaseN(_ val: Int32, base: BaseNType) -> String {
        switch base {
        case .dec:
            return "\(val)"
        case .hex:
            return String(UInt32(bitPattern: val), radix: 16, uppercase: true)
        case .bin:
            return String(UInt32(bitPattern: val), radix: 2)
        case .oct:
            return String(UInt32(bitPattern: val), radix: 8)
        }
    }

    public func setBaseN(_ base: BaseNType) {
        baseNType = base
        if !isError, let val = Double(result) {
            let intVal = Int32(truncatingIfNeeded: Int64(val))
            result = formatBaseN(intVal, base: base)
        }
    }

    // MARK: - Modifiers

    public func toggleShift() {
        shiftActive.toggle()
        if shiftActive { alphaActive = false }
    }

    public func toggleAlpha() {
        alphaActive.toggle()
        if alphaActive { shiftActive = false }
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
            case 3: activeMode = .stat; openStatTypeMenu()
            case 4: activeMode = .baseN
            case 5: activeMode = .eqn; openEqnTypeMenu()
            case 6: activeMode = .matrix; openMatrixMenu()
            case 7: activeMode = .table; startTable()
            case 8: activeMode = .vector; openVectorMenu()
            default: break
            }
            if menuState == .modeMenu { menuState = .none }

        case .setupMenu(let page):
            if page == 1 {
                switch number {
                case 1:
                    isMthIO = true
                    menuState = .mthIOMenu
                case 2:
                    isMthIO = false
                    menuState = .none // LineIO
                case 3: angleUnit = .deg; menuState = .none
                case 4: angleUnit = .rad; menuState = .none
                case 5: angleUnit = .gra; menuState = .none
                case 6: menuState = .fixPrompt
                case 7: menuState = .sciPrompt
                case 8: displayFormat = .norm; menuState = .none
                default: break
                }
            } else if page == 2 {
                switch number {
                case 1: displayFormat = .mixedFraction; menuState = .none
                case 2: displayFormat = .fraction; menuState = .none
                case 3: menuState = .none
                case 4: menuState = .none
                case 5: menuState = .none
                default: break
                }
            }

        case .mthIOMenu:
            isMthIO = true
            menuState = .none

        case .eqnTypeMenu:
            startEqn(type: number)

        case .fixPrompt:
            let d = min(max(0, number), 9)
            displayFormat = .fix(d)
            menuState = .none
            if !isError, let val = Double(result.replacingOccurrences(of: "×10^", with: "e")) {
                result = CasioEvaluator.format(val, format: displayFormat)
            }

        case .sciPrompt:
            let d = min(max(0, number), 9)
            displayFormat = .sci(d)
            menuState = .none
            if !isError, let val = Double(result.replacingOccurrences(of: "×10^", with: "e")) {
                result = CasioEvaluator.format(val, format: displayFormat)
            }

        case .clrPrompt:
            switch number {
            case 1: // Reset Setup
                angleUnit = .deg
                displayFormat = .norm
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
            menuState = .none


        default:
            menuState = .none
        }
    }

    // MARK: - Memory Operations

    public func storeToVariable(_ varName: Character) {
        if let val = Double(result.replacingOccurrences(of: "×10^", with: "e")) {
            variables[varName] = val
            result = "\(varName)=\(CasioEvaluator.format(val, format: displayFormat))"
        }
    }

    public func recallVariable(_ varName: Character) {
        let val = variables[varName] ?? 0
        insert(CasioEvaluator.format(val, format: displayFormat))
    }

    public func addMemory() {
        if let val = Double(result.replacingOccurrences(of: "×10^", with: "e")) {
            variables["M"] = (variables["M"] ?? 0) + val
        }
    }

    public func subtractMemory() {
        if let val = Double(result.replacingOccurrences(of: "×10^", with: "e")) {
            variables["M"] = (variables["M"] ?? 0) - val
        }
    }

    // MARK: - Specialized Function Actions

    public func toggleSD() {
        if let exact = exactResult {
            isShowingDecimal.toggle()
            if isShowingDecimal {
                result = CasioEvaluator.format(exact.toDouble(), format: displayFormat)
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
            result = CasioEvaluator.format(val, format: displayFormat)
        }
    }

    public func cycleEng() {
        displayFormat = (displayFormat == .eng) ? .norm : .eng
        if !isError, let val = Double(result.replacingOccurrences(of: "×10^", with: "e")) {
            result = CasioEvaluator.format(val, format: displayFormat)
        }
    }

    public func primeFactorize() {
        if let val = Double(result), val > 1, val <= 10000000000, val.rounded() == val {
            if let fact = CasioEvaluator.primeFactorization(Int64(val)) {
                result = fact
            }
        }
    }

    public func convertToDMS() {
        if let val = Double(result) {
            result = CasioEvaluator.toDMS(val)
        }
    }

    public func insertConstant(code: Int) {
        if let c = CasioConstants.get(code) {
            insert("\(c.value)")
        }
    }

    public func applyConversion(code: Int) {
        if let val = Double(result), let conv = CasioConversions.convert(value: val, code: code) {
            result = CasioEvaluator.format(conv.result, format: displayFormat)
        }
    }

    // MARK: - EQN Mode Helpers

    public func startEqn(type: Int) {
        eqnType = type
        eqnCoeffs = []
        eqnSolutions = []
        eqnSolutionIndex = 0
        let names = coeffNamesForEqn(type: type)
        if let first = names.first {
            menuState = .eqnCoeffPrompt(type: type, coeffName: first, coeffIndex: 0)
        }
    }

    public func coeffNamesForEqn(type: Int) -> [String] {
        switch type {
        case 1: return ["a1", "b1", "c1", "a2", "b2", "c2"]
        case 2: return ["a1", "b1", "c1", "d1", "a2", "b2", "c2", "d2", "a3", "b3", "c3", "d3"]
        case 3: return ["a", "b", "c"]
        case 4: return ["a", "b", "c", "d"]
        default: return []
        }
    }

    public func advanceEqnCoeff(val: Double) {
        eqnCoeffs.append(val)
        let names = coeffNamesForEqn(type: eqnType)
        if eqnCoeffs.count < names.count {
            let nextIndex = eqnCoeffs.count
            menuState = .eqnCoeffPrompt(type: eqnType, coeffName: names[nextIndex], coeffIndex: nextIndex)
        } else {
            // Solve!
            switch eqnType {
            case 1:
                eqnSolutions = CasioEvaluator.solveSimultaneous2(
                    a1: eqnCoeffs[0], b1: eqnCoeffs[1], c1: eqnCoeffs[2],
                    a2: eqnCoeffs[3], b2: eqnCoeffs[4], c2: eqnCoeffs[5]
                )
            case 2:
                eqnSolutions = CasioEvaluator.solveSimultaneous3(
                    a1: eqnCoeffs[0], b1: eqnCoeffs[1], c1: eqnCoeffs[2], d1: eqnCoeffs[3],
                    a2: eqnCoeffs[4], b2: eqnCoeffs[5], c2: eqnCoeffs[6], d2: eqnCoeffs[7],
                    a3: eqnCoeffs[8], b3: eqnCoeffs[9], c3: eqnCoeffs[10], d3: eqnCoeffs[11]
                )
            case 3:
                eqnSolutions = CasioEvaluator.solveQuadratic(
                    a: eqnCoeffs[0], b: eqnCoeffs[1], c: eqnCoeffs[2]
                )
            case 4:
                eqnSolutions = CasioEvaluator.solveCubic(
                    a: eqnCoeffs[0], b: eqnCoeffs[1], c: eqnCoeffs[2], d: eqnCoeffs[3]
                )
            default: break
            }
            eqnSolutionIndex = 0
            menuState = .eqnSolutionView(solutions: eqnSolutions, index: 0)
        }
    }

    // MARK: - Table Mode Helpers

    public func startTable() {
        tableFormula = expression.isEmpty ? "X²" : expression
        expression = tableFormula
        menuState = .tablePrompt(step: 0)
    }

    public func advanceTablePrompt(val: Double? = nil) {
        guard case .tablePrompt(let step) = menuState else { return }
        switch step {
        case 0:
            tableFormula = expression.isEmpty ? "X²" : expression
            menuState = .tablePrompt(step: 1)
        case 1:
            tableStartVal = val ?? tableStartVal
            menuState = .tablePrompt(step: 2)
        case 2:
            tableEndVal = val ?? tableEndVal
            menuState = .tablePrompt(step: 3)
        case 3:
            tableStepVal = val ?? tableStepVal
            tableRows.removeAll()
            var x = tableStartVal
            let end = tableEndVal
            let s = max(0.0001, tableStepVal)
            while x <= end + 1e-9 && tableRows.count < 30 {
                var vars = variables
                vars["X"] = x
                let res = CasioEvaluator.evaluate(tableFormula, angleUnit: angleUnit, variables: vars)
                tableRows.append((x: x, fx: res.value ?? 0))
                x += s
            }
            menuState = .tablePrompt(step: 4)
        default:
            menuState = .tablePrompt(step: 0)
        }
    }

    // MARK: - CALC & SOLVE Helpers

    public func startCalc() {
        let varsInExpr = ["A", "B", "C", "D", "E", "F", "X", "Y"].filter { char in
            expression.contains(char)
        }.map { Character($0) }

        if let first = varsInExpr.first {
            menuState = .calcPrompt(varName: first, remainingVars: Array(varsInExpr.dropFirst()))
        } else {
            evaluate()
        }
    }

    public func advanceCalc(val: Double) {
        guard case .calcPrompt(let varName, let remaining) = menuState else { return }
        variables[varName] = val
        if let next = remaining.first {
            menuState = .calcPrompt(varName: next, remainingVars: Array(remaining.dropFirst()))
        } else {
            menuState = .none
            evaluate()
        }
    }

    public func startSolve() {
        let guess = variables["X"] ?? 0
        menuState = .solvePrompt(initialGuess: guess)
    }

    public func executeSolve(guess: Double) {
        if let res = CasioEvaluator.solveEquation(expression, initialGuess: guess, angleUnit: angleUnit, variables: variables) {
            variables["X"] = res.root
            lastAnswer = res.root
            menuState = .solveResult(root: res.root, residual: res.residual)
        } else {
            isError = true
            result = "Can't Solve"
            menuState = .none
        }
    }

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
