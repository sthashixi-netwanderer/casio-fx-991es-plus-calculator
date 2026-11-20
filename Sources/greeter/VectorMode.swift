import Foundation

// MARK: - Standalone 3D vector math (used by COMP examples)

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

// MARK: - Vector Value (VECTOR mode, manual §10)

/// A 2D or 3D vector. The component count is the vector's dimension.
public struct VectorValue: Equatable, Sendable {
    public var components: [Double]

    public init(_ components: [Double]) {
        self.components = Array(components.prefix(3))
    }

    public var dim: Int { components.count }
    public var magnitude: Double {
        Foundation.sqrt(components.reduce(0) { $0 + $1 * $1 })
    }

    public subscript(index: Int) -> Double {
        get { components[index] }
        set { components[index] = newValue }
    }

    public static func + (lhs: VectorValue, rhs: VectorValue) -> VectorValue? {
        guard lhs.dim == rhs.dim else { return nil }
        return VectorValue(zip(lhs.components, rhs.components).map { $0 + $1 })
    }

    public static func - (lhs: VectorValue, rhs: VectorValue) -> VectorValue? {
        guard lhs.dim == rhs.dim else { return nil }
        return VectorValue(zip(lhs.components, rhs.components).map { $0 - $1 })
    }

    public static func * (lhs: VectorValue, rhs: VectorValue) -> VectorValue? {
        // The × key between two vectors is the cross product. Casio always
        // returns three components (manual §10.9).
        let a = lhs.components + Array(repeating: 0.0, count: max(0, 3 - lhs.dim))
        let b = rhs.components + Array(repeating: 0.0, count: max(0, 3 - rhs.dim))
        let cx = a[1] * b[2] - a[2] * b[1]
        let cy = a[2] * b[0] - a[0] * b[2]
        let cz = a[0] * b[1] - a[1] * b[0]
        return VectorValue([cx, cy, cz])
    }

    public static func * (vector: VectorValue, scalar: Double) -> VectorValue {
        VectorValue(vector.components.map { $0 * scalar })
    }

    public static func dot(_ lhs: VectorValue, _ rhs: VectorValue) -> Double? {
        guard lhs.dim == rhs.dim else { return nil }
        return zip(lhs.components, rhs.components).map { $0 * $1 }.reduce(0, +)
    }

    public var linearString: String {
        "(" + components.map { CasioEvaluator.format($0, format: .norm) }.joined(separator: ",") + ")"
    }
}

// MARK: - Vector Expression Evaluation

public enum VectorEvalValue: Equatable, Sendable {
    case scalar(Double)
    case vector(VectorValue)
}

public struct VectorEvalResult: Sendable {
    public let value: VectorEvalValue?
    public let error: String?
    public init(value: VectorEvalValue? = nil, error: String? = nil) {
        self.value = value
        self.error = error
    }
}

public enum VectorEvaluator {
    private enum Token: Equatable {
        case number(Double)
        case vectorRef(String)
        case function(String)
        case binaryOp(Character)
        case dot
        case comma
        case openParen
        case closeParen
    }

    private enum EvalError: Error {
        case syntax, dim, math
        var message: String {
            switch self {
            case .syntax: return "Syntax ERROR"
            case .dim: return "Dim ERROR"
            case .math: return "Math ERROR"
            }
        }
    }

    private static let names = ["VctA", "VctB", "VctC", "VctAns"]

    public static func evaluate(_ expr: String, vectors: [String: VectorValue]) -> VectorEvalResult {
        let chars = Array(expr.replacingOccurrences(of: " ", with: ""))
        var tokens: [Token] = []
        var i = 0
        do {
            while i < chars.count {
                let c = chars[i]
                switch c {
                case "0"..."9", ".":
                    var s = ""
                    while i < chars.count, chars[i].isNumber || chars[i] == "." {
                        s.append(chars[i]); i += 1
                    }
                    guard let v = Double(s) else { throw EvalError.syntax }
                    tokens.append(.number(v))
                case "+", "-", "−", "*", "×", "/", "÷":
                    tokens.append(.binaryOp(c)); i += 1
                case "(":
                    tokens.append(.openParen); i += 1
                case ")":
                    tokens.append(.closeParen); i += 1
                case ",":
                    tokens.append(.comma); i += 1
                case "V":
                    guard let name = names.first(where: { match($0, chars, i) }) else { throw EvalError.syntax }
                    tokens.append(.vectorRef(name)); i += name.count
                case "A":
                    if match("Abs(", chars, i) {
                        tokens.append(.function("Abs")); tokens.append(.openParen); i += 4
                    } else { throw EvalError.syntax }
                case "D":
                    if match("Dot(", chars, i) {
                        tokens.append(.function("Dot")); tokens.append(.openParen); i += 4
                    } else if match("Dot", chars, i) {
                        tokens.append(.dot); i += 3
                    } else { throw EvalError.syntax }
                default:
                    throw EvalError.syntax
                }
            }
            var parser = Parser(tokens: tokens, vectors: vectors)
            let value = try parser.parseExpression()
            guard parser.isAtEnd else { throw EvalError.syntax }
            return VectorEvalResult(value: value)
        } catch let e as EvalError {
            return VectorEvalResult(error: e.message)
        } catch {
            return VectorEvalResult(error: "Syntax ERROR")
        }
    }

    private static func match(_ pattern: String, _ chars: [Character], _ at: Int) -> Bool {
        let p = Array(pattern)
        guard at + p.count <= chars.count else { return false }
        return Array(chars[at..<(at + p.count)]) == p
    }

    private struct Parser {
        let tokens: [Token]
        let vectors: [String: VectorValue]
        var pos = 0
        var isAtEnd: Bool { pos >= tokens.count }
        private func peek() -> Token? { pos < tokens.count ? tokens[pos] : nil }
        private mutating func advance() -> Token? {
            guard pos < tokens.count else { return nil }
            defer { pos += 1 }
            return tokens[pos]
        }

        mutating func parseExpression() throws -> VectorEvalValue {
            var left = try parseTerm()
            while case .binaryOp(let op)? = peek(), op == "+" || op == "-" || op == "−" {
                _ = advance()
                let right = try parseTerm()
                switch op {
                case "+": left = try add(left, right)
                default: left = try subtract(left, right)
                }
            }
            return left
        }

        private mutating func parseTerm() throws -> VectorEvalValue {
            var left = try parseUnary()
            while true {
                switch peek() {
                case .binaryOp(let op) where op == "*" || op == "×" || op == "/" || op == "÷":
                    _ = advance()
                    left = try multiply(left, try parseUnary(), divide: op == "/" || op == "÷")
                case .dot:
                    _ = advance()
                    left = try dot(left, try parseUnary())
                default:
                    return left
                }
            }
        }

        private mutating func parseUnary() throws -> VectorEvalValue {
            if case .binaryOp(let op)? = peek(), op == "-" || op == "−" {
                _ = advance()
                return try negate(parseUnary())
            }
            return try parsePrimary()
        }

        private mutating func parsePrimary() throws -> VectorEvalValue {
            guard let token = advance() else { throw EvalError.syntax }
            switch token {
            case .number(let v): return .scalar(v)
            case .vectorRef(let name):
                guard let v = vectors[name] else { throw EvalError.dim }
                return .vector(v)
            case .openParen:
                let value = try parseExpression()
                guard case .closeParen? = peek() else { throw EvalError.syntax }
                _ = advance()
                return value
            case .function(let name):
                guard case .openParen? = peek() else { throw EvalError.syntax }
                _ = advance()
                if name == "Abs" {
                    let value = try parseExpression()
                    guard case .closeParen? = peek() else { throw EvalError.syntax }
                    _ = advance()
                    guard case .vector(let v) = value else { throw EvalError.dim }
                    return .scalar(v.magnitude)
                }
                // Dot(v1, v2) function form
                let lhs = try parseExpression()
                guard case .vector(let a) = lhs, case .comma? = peek() else { throw EvalError.syntax }
                _ = advance()
                let rhs = try parseExpression()
                guard case .closeParen? = peek() else { throw EvalError.syntax }
                _ = advance()
                guard case .vector(let b) = rhs, let d = VectorValue.dot(a, b) else { throw EvalError.dim }
                return .scalar(d)
            default: throw EvalError.syntax
            }
        }

        private func add(_ l: VectorEvalValue, _ r: VectorEvalValue) throws -> VectorEvalValue {
            switch (l, r) {
            case (.scalar(let a), .scalar(let b)): return .scalar(a + b)
            case (.vector(let a), .vector(let b)):
                guard let sum = a + b else { throw EvalError.dim }
                return .vector(sum)
            default: throw EvalError.dim
            }
        }

        private func subtract(_ l: VectorEvalValue, _ r: VectorEvalValue) throws -> VectorEvalValue {
            switch (l, r) {
            case (.scalar(let a), .scalar(let b)): return .scalar(a - b)
            case (.vector(let a), .vector(let b)):
                guard let diff = a - b else { throw EvalError.dim }
                return .vector(diff)
            default: throw EvalError.dim
            }
        }

        private func multiply(_ l: VectorEvalValue, _ r: VectorEvalValue, divide: Bool) throws -> VectorEvalValue {
            if divide {
                guard case .vector(let v) = l, case .scalar(let s) = r, s != 0 else { throw EvalError.math }
                return .vector(v * (1.0 / s))
            }
            switch (l, r) {
            case (.scalar(let a), .scalar(let b)): return .scalar(a * b)
            case (.scalar(let s), .vector(let v)), (.vector(let v), .scalar(let s)): return .vector(v * s)
            case (.vector(let a), .vector(let b)):
                guard let cross = a * b else { throw EvalError.dim }
                return .vector(cross)
            }
        }

        private func dot(_ l: VectorEvalValue, _ r: VectorEvalValue) throws -> VectorEvalValue {
            guard case .vector(let a) = l, case .vector(let b) = r, let value = VectorValue.dot(a, b) else {
                throw EvalError.dim
            }
            return .scalar(value)
        }

        private func negate(_ value: VectorEvalValue) throws -> VectorEvalValue {
            switch value {
            case .scalar(let a): return .scalar(-a)
            case .vector(let v): return .vector(v * -1)
            }
        }
    }
}

// MARK: - Engine VECTOR support

extension CalculatorEngine {
    /// Vector menu: 1 Dim  2 Data  3 VctA  4 VctB  5 VctC  6 VctAns  7 Dot
    @discardableResult
    public func handleVectorMenuOption(_ number: Int) -> Bool {
        switch number {
        case 1: menuState = .vectorDimSelect
        case 2: menuState = .vectorDataSelect
        case 3: insertVectorToken("VctA")
        case 4: insertVectorToken("VctB")
        case 5: insertVectorToken("VctC")
        case 6: insertVectorToken("VctAns")
        case 7: insertFunctionToken("Dot")
        default: return false
        }
        return true
    }

    public func insertVectorToken(_ token: String) {
        if isMthIO { insertASTText(token) } else { insert(token) }
        menuState = .none
    }

    public func vectorValue(for name: String) -> VectorValue {
        switch name {
        case "VctB": return vctB
        case "VctC": return vctC
        case "VctAns": return vctAns
        default: return vctA
        }
    }

    func setVector(_ name: String, to value: VectorValue) {
        switch name {
        case "VctB": vctB = value
        case "VctC": vctC = value
        case "VctAns": vctAns = value
        default: vctA = value
        }
    }

    public func openVectorNamed(_ name: String, dataMode: Bool = false) {
        if dataMode && definedVectors.contains(name) {
            menuState = .vectorComponentEditor(name: name, index: 0)
        } else {
            menuState = .vectorDimPrompt(name: name)
        }
    }

    public func confirmVectorDim(_ name: String, dim: Int) {
        guard dim == 2 || dim == 3 else {
            isError = true
            result = "Dim ERROR"
            menuState = .none
            return
        }
        setVector(name, to: VectorValue(Array(repeating: 0, count: dim).map { Double($0) }))
        definedVectors.insert(name)
        menuState = .vectorComponentEditor(name: name, index: 0)
    }

    public func commitVectorComponent(_ value: Double) {
        guard case .vectorComponentEditor(let name, let index) = menuState else { return }
        var v = vectorValue(for: name)
        guard index >= 0, index < v.dim else { menuState = .none; return }
        v[index] = value
        setVector(name, to: v)
        definedVectors.insert(name)
        if index + 1 < v.dim {
            menuState = .vectorComponentEditor(name: name, index: index + 1)
        } else {
            menuState = .none
        }
    }
}
