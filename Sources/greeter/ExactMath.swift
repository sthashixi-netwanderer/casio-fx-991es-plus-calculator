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
