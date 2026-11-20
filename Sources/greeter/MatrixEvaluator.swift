import Foundation

// MARK: - Matrix Expression Evaluation
//
// Matrix-mode expression evaluation (fx-991ES PLUS MATRIX mode): a recursive-
// descent parser over scalar and matrix operands supporting
//   MatA MatB MatC MatAns   matrix variables
//   det( Trn( Abs(          unary matrix functions
//   + − × ÷                 arithmetic (dim-checked, scalar-mixed)
//   ²  ³  ⁻¹                postfix square / cube / inverse
// Unary minus, parentheses and plain numbers are also accepted so scalar
// expressions like det(MatA)+3 evaluate normally.

/// A value produced by a matrix-mode calculation: either a plain number or a
/// matrix (which the engine stores into MatAns).
public enum MatrixEvalValue: Equatable, Sendable {
    case scalar(Double)
    case matrix(Matrix)
}

public struct MatrixEvalResult: Sendable {
    public let value: MatrixEvalValue?
    public let error: String?

    public init(value: MatrixEvalValue? = nil, error: String? = nil) {
        self.value = value
        self.error = error
    }
}

public enum MatrixEvaluator {
    private enum Token: Equatable {
        case number(Double)
        case matrixRef(String)
        case function(String)   // det, Trn, Abs
        case binaryOp(Character) // + - * /
        case openParen
        case closeParen
        case postfixSquare      // ²
        case postfixCube        // ³
        case postfixInverse     // ⁻¹
    }

    private static let matrixNames = ["MatA", "MatB", "MatC", "MatAns"]

    public static func evaluate(_ expr: String, matrices: [String: Matrix]) -> MatrixEvalResult {
        let tokens: [Token]
        do {
            tokens = try tokenize(expr)
        } catch let e as MatrixEvalError {
            return MatrixEvalResult(error: e.message)
        } catch {
            return MatrixEvalResult(error: "Syntax ERROR")
        }

        var parser = Parser(tokens: tokens, matrices: matrices)
        do {
            let value = try parser.parseExpression()
            // Trailing garbage after a complete expression is a syntax error
            if !parser.isAtEnd {
                throw MatrixEvalError.syntax
            }
            return MatrixEvalResult(value: value)
        } catch let e as MatrixEvalError {
            return MatrixEvalResult(error: e.message)
        } catch {
            return MatrixEvalResult(error: "Syntax ERROR")
        }
    }

    // MARK: Tokenizing

    private enum MatrixEvalError: Error {
        case syntax
        case dim
        case math

        var message: String {
            switch self {
            case .syntax: return "Syntax ERROR"
            case .dim: return "Dim ERROR"
            case .math: return "Math ERROR"
            }
        }
    }

    private static func tokenize(_ expr: String) throws -> [Token] {
        var tokens: [Token] = []
        // The 2D editor renders x⁻¹ / x² / x³ as "(x)^(-1)", "(x)^(2)", "(x)^(3)"
        // and the linear editor as "x^(-1)" / "x²" / "x³". Normalize the exponent
        // forms to postfix tokens before scanning (keeping the closing paren).
        let normalized = expr
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ")^(-1)", with: "⁻¹)")
            .replacingOccurrences(of: ")^(3)", with: "³)")
            .replacingOccurrences(of: ")^(2)", with: "²)")
            .replacingOccurrences(of: "^2", with: "²")
            .replacingOccurrences(of: "^3", with: "³")
        let chars = Array(normalized)
        var i = 0
        while i < chars.count {
            let c = chars[i]
            switch c {
            case "0"..."9", ".":
                var numStr = ""
                while i < chars.count, chars[i].isNumber || chars[i] == "." {
                    numStr.append(chars[i])
                    i += 1
                }
                guard let val = Double(numStr) else { throw MatrixEvalError.syntax }
                tokens.append(.number(val))
            case "+", "-", "*", "/", "×", "÷", "−":
                tokens.append(.binaryOp(c))
                i += 1
            case "(":
                tokens.append(.openParen)
                i += 1
            case ")":
                tokens.append(.closeParen)
                i += 1
            case "²":
                tokens.append(.postfixSquare)
                i += 1
            case "³":
                tokens.append(.postfixCube)
                i += 1
            case "⁻":
                guard i + 1 < chars.count, chars[i + 1] == "¹" else { throw MatrixEvalError.syntax }
                tokens.append(.postfixInverse)
                i += 2
            case "A":
                guard matchAt("Abs(", in: chars, at: i) else { throw MatrixEvalError.syntax }
                tokens.append(.function("Abs"))
                tokens.append(.openParen)
                i += 4
            case "a":
                guard matchAt("abs(", in: chars, at: i) else { throw MatrixEvalError.syntax }
                tokens.append(.function("Abs"))
                tokens.append(.openParen)
                i += 4
            case "M":
                guard let name = matrixNames.first(where: { matchAt($0, in: chars, at: i) }) else {
                    throw MatrixEvalError.syntax
                }
                tokens.append(.matrixRef(name))
                i += name.count
            case "d":
                guard matchAt("det(", in: chars, at: i) else { throw MatrixEvalError.syntax }
                tokens.append(.function("det"))
                tokens.append(.openParen)
                i += 4
            case "T":
                guard matchAt("Trn(", in: chars, at: i) else { throw MatrixEvalError.syntax }
                tokens.append(.function("Trn"))
                tokens.append(.openParen)
                i += 4
            default:
                throw MatrixEvalError.syntax
            }
        }
        return tokens
    }

    private static func matchAt(_ pattern: String, in chars: [Character], at index: Int) -> Bool {
        let pChars = Array(pattern)
        guard index + pChars.count <= chars.count else { return false }
        return Array(chars[index..<(index + pChars.count)]) == pChars
    }

    // MARK: Parsing (recursive descent)

    private struct Parser {
        let tokens: [Token]
        let matrices: [String: Matrix]
        var pos = 0

        init(tokens: [Token], matrices: [String: Matrix]) {
            self.tokens = tokens
            self.matrices = matrices
        }

        var isAtEnd: Bool { pos >= tokens.count }

        private func peek() -> Token? { pos < tokens.count ? tokens[pos] : nil }

        private mutating func advance() -> Token? {
            guard pos < tokens.count else { return nil }
            defer { pos += 1 }
            return tokens[pos]
        }

        mutating func parseExpression() throws -> MatrixEvalValue {
            var left = try parseTerm()
            while case .binaryOp(let op)? = peek(), op == "+" || op == "-" || op == "−" {
                _ = advance()
                let right = try parseTerm()
                switch op {
                case "+": left = try MatrixEvaluator.add(left, right)
                default: left = try MatrixEvaluator.subtract(left, right)
                }
            }
            return left
        }

        private mutating func parseTerm() throws -> MatrixEvalValue {
            var left = try parsePostfix()
            while case .binaryOp(let op)? = peek(), op == "*" || op == "×" || op == "/" || op == "÷" {
                _ = advance()
                let right = try parsePostfix()
                switch op {
                case "*", "×": left = try MatrixEvaluator.multiply(left, right)
                default: left = try MatrixEvaluator.divide(left, right)
                }
            }
            return left
        }

        /// x², x³ and x⁻¹ bind tighter than × ÷ (fx-991ES: MatA², MatA³, MatA⁻¹)
        private mutating func parsePostfix() throws -> MatrixEvalValue {
            var value = try parseUnary()
            loop: while true {
                switch peek() {
                case .postfixSquare:
                    _ = advance()
                    value = try MatrixEvaluator.square(value)
                case .postfixCube:
                    _ = advance()
                    value = try MatrixEvaluator.cube(value)
                case .postfixInverse:
                    _ = advance()
                    value = try MatrixEvaluator.inverse(value)
                default:
                    break loop
                }
            }
            return value
        }

        private mutating func parseUnary() throws -> MatrixEvalValue {
            if case .binaryOp(let op)? = peek(), op == "-" || op == "−" {
                _ = advance()
                let value = try parseUnary()
                return MatrixEvaluator.negate(value)
            }
            return try parsePrimary()
        }

        private mutating func parsePrimary() throws -> MatrixEvalValue {
            guard let token = advance() else { throw MatrixEvalError.syntax }
            switch token {
            case .number(let v):
                return .scalar(v)
            case .matrixRef(let name):
                guard let m = matrices[name] else { throw MatrixEvalError.dim }
                return .matrix(m)
            case .function(let name):
                guard case .openParen? = peek() else { throw MatrixEvalError.syntax }
                _ = advance()
                let arg = try parseExpression()
                guard case .closeParen? = peek() else { throw MatrixEvalError.syntax }
                _ = advance()
                switch name {
                case "det":
                    guard case .matrix(let m) = arg else { throw MatrixEvalError.dim }
                    // A determinant is defined only for a square matrix; the manual
                    // lists Math ERROR for this case (§17).
                    guard let det = m.determinant() else { throw MatrixEvalError.math }
                    return .scalar(det)
                case "Trn":
                    guard case .matrix(let m) = arg else { throw MatrixEvalError.dim }
                    return .matrix(m.transpose())
                default: // Abs — element-wise for matrices, ordinary abs for scalars
                    return MatrixEvaluator.absValue(arg)
                }
            case .openParen:
                let value = try parseExpression()
                guard case .closeParen? = peek() else { throw MatrixEvalError.syntax }
                _ = advance()
                return value
            default:
                throw MatrixEvalError.syntax
            }
        }
    }

    // MARK: Arithmetic

    private static func add(_ lhs: MatrixEvalValue, _ rhs: MatrixEvalValue) throws -> MatrixEvalValue {
        switch (lhs, rhs) {
        case let (.scalar(a), .scalar(b)):
            return .scalar(a + b)
        case let (.matrix(a), .matrix(b)):
            guard let sum = a + b else { throw MatrixEvalError.dim }
            return .matrix(sum)
        default:
            throw MatrixEvalError.dim
        }
    }

    private static func subtract(_ lhs: MatrixEvalValue, _ rhs: MatrixEvalValue) throws -> MatrixEvalValue {
        switch (lhs, rhs) {
        case let (.scalar(a), .scalar(b)):
            return .scalar(a - b)
        case let (.matrix(a), .matrix(b)):
            guard let diff = a - b else { throw MatrixEvalError.dim }
            return .matrix(diff)
        default:
            throw MatrixEvalError.dim
        }
    }

    private static func multiply(_ lhs: MatrixEvalValue, _ rhs: MatrixEvalValue) throws -> MatrixEvalValue {
        switch (lhs, rhs) {
        case let (.scalar(a), .scalar(b)):
            return .scalar(a * b)
        case let (.scalar(a), .matrix(m)):
            return .matrix(scaled(m, by: a))
        case let (.matrix(m), .scalar(a)):
            return .matrix(scaled(m, by: a))
        case let (.matrix(a), .matrix(b)):
            guard let prod = a * b else { throw MatrixEvalError.dim }
            return .matrix(prod)
        }
    }

    private static func divide(_ lhs: MatrixEvalValue, _ rhs: MatrixEvalValue) throws -> MatrixEvalValue {
        switch (lhs, rhs) {
        case let (.scalar(a), .scalar(b)):
            guard b != 0 else { throw MatrixEvalError.math }
            return .scalar(a / b)
        case let (.matrix(m), .scalar(s)):
            guard s != 0 else { throw MatrixEvalError.math }
            return .matrix(scaled(m, by: 1.0 / s))
        default:
            throw MatrixEvalError.dim
        }
    }

    private static func negate(_ value: MatrixEvalValue) -> MatrixEvalValue {
        switch value {
        case .scalar(let a): return .scalar(-a)
        case .matrix(let m): return .matrix(scaled(m, by: -1))
        }
    }

    private static func square(_ value: MatrixEvalValue) throws -> MatrixEvalValue {
        switch value {
        case .scalar(let a): return .scalar(a * a)
        case .matrix(let m):
            guard m.rows == m.cols, let sq = m * m else { throw MatrixEvalError.dim }
            return .matrix(sq)
        }
    }

    /// Cube uses the dedicated x³ function (manual §13). Like squaring, it is
    /// only defined for a square matrix.
    private static func cube(_ value: MatrixEvalValue) throws -> MatrixEvalValue {
        switch value {
        case .scalar(let a): return .scalar(a * a * a)
        case .matrix(let m):
            guard m.rows == m.cols, let sq = m * m, let cubed = sq * m else {
                throw MatrixEvalError.dim
            }
            return .matrix(cubed)
        }
    }

    /// Abs( on a matrix returns the absolute value of every element (manual §14);
    /// it is neither a determinant nor a matrix norm.
    private static func absValue(_ value: MatrixEvalValue) -> MatrixEvalValue {
        switch value {
        case .scalar(let a): return .scalar(abs(a))
        case .matrix(let m):
            var result = m
            for r in 0..<m.rows {
                for c in 0..<m.cols {
                    result.elements[r][c] = abs(m.elements[r][c])
                }
            }
            return .matrix(result)
        }
    }

    private static func inverse(_ value: MatrixEvalValue) throws -> MatrixEvalValue {
        switch value {
        case .scalar(let a):
            guard a != 0 else { throw MatrixEvalError.math }
            return .scalar(1.0 / a)
        case .matrix(let m):
            guard let inv = m.inverse() else { throw MatrixEvalError.math }
            return .matrix(inv)
        }
    }

    private static func scaled(_ m: Matrix, by factor: Double) -> Matrix {
        var result = m
        for r in 0..<m.rows {
            for c in 0..<m.cols {
                result.elements[r][c] = m.elements[r][c] * factor
            }
        }
        return result
    }
}

// MARK: - Matrix Display

extension Matrix {
    /// Linear form used for history entries: [[1,2][3,4]]
    public func toLinearString() -> String {
        let rowStrings = elements.prefix(rows).map { row in
            "[" + row.prefix(cols).map { CasioEvaluator.format($0, format: .norm) }.joined(separator: ",") + "]"
        }
        return "[" + rowStrings.joined() + "]"
    }
}
