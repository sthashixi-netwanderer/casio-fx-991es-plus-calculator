import Foundation

// MARK: - Complex Number Representation (CMPLX mode)

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

// MARK: - Engine CMPLX support

extension CalculatorEngine {
    /// Insert a function call token (arg(, Abs(, Conjg(, Dot etc.) honoring the
    /// current input mode. Shared by CMPLX, VECTOR and other mode menus.
    public func insertFunctionToken(_ name: String) {
        if isMthIO {
            insertASTFunction(name)
        } else {
            insert(name + "(")
        }
    }

    /// Format a complex result according to the SETUP complex format.
    public func formatComplex(_ c: Complex) -> String {
        switch complexFormat {
        case .polar: return c.formatPolar(angleUnit: angleUnit)
        case .rectangular: return c.formatRectangular()
        }
    }

    /// Re-render the displayed complex result after a ▶r∠θ / ▶a+bi command or a
    /// SETUP change — no re-evaluation is needed.
    public func refreshComplexResultDisplay() {
        guard isShowingResult, !isError, isShowingComplexResult else { return }
        result = formatComplex(lastComplexAnswer)
    }

    /// CMPLX menu: 1 arg  2 Abs  3 Conjg  4 ▶r∠θ  5 ▶a+bi
    /// Returns true when the number was handled.
    @discardableResult
    public func handleComplexMenuOption(_ number: Int) -> Bool {
        switch number {
        case 1: insertFunctionToken("arg")
        case 2: insertFunctionToken("Abs")
        case 3: insertFunctionToken("Conjg")
        case 4:
            complexFormat = .polar
            refreshComplexResultDisplay()
        case 5:
            complexFormat = .rectangular
            refreshComplexResultDisplay()
        default: return false
        }
        menuState = .none
        return true
    }
}
