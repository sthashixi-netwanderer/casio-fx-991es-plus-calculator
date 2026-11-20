import Foundation

// MARK: - Equation solvers (EQN mode, manual §8)

extension CasioEvaluator {
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

    public static func solveSimultaneous2(
        a1: Double, b1: Double, c1: Double,
        a2: Double, b2: Double, c2: Double
    ) -> [String] {
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
        let matDx = Matrix(elements: [[d1, b1, c1], [d2, b2, c2], [d3, b3, c3]])
        let matDy = Matrix(elements: [[a1, d1, c1], [a2, d2, c2], [a3, d3, c3]])
        let matDz = Matrix(elements: [[a1, b1, d1], [a2, b2, d2], [a3, b3, d3]])
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

// MARK: - Engine EQN helpers

extension CalculatorEngine {
    public func coeffNamesForEqn(type: Int) -> [String] {
        switch type {
        case 1: return ["a1", "b1", "c1", "a2", "b2", "c2"]
        case 2: return ["a1", "b1", "c1", "d1", "a2", "b2", "c2", "d2", "a3", "b3", "c3", "d3"]
        case 3: return ["a", "b", "c"]
        case 4: return ["a", "b", "c", "d"]
        default: return []
        }
    }

    public func startEqn(type: Int) {
        eqnType = type
        eqnCoeffs = []
        eqnSolutions = []
        eqnSolutionIndex = 0
        if let first = coeffNamesForEqn(type: type).first {
            menuState = .eqnCoeffPrompt(type: type, coeffName: first, coeffIndex: 0)
        }
    }

    public func advanceEqnCoeff(val: Double) {
        eqnCoeffs.append(val)
        let names = coeffNamesForEqn(type: eqnType)
        if eqnCoeffs.count < names.count {
            let next = eqnCoeffs.count
            menuState = .eqnCoeffPrompt(type: eqnType, coeffName: names[next], coeffIndex: next)
            return
        }
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
            eqnSolutions = CasioEvaluator.solveQuadratic(a: eqnCoeffs[0], b: eqnCoeffs[1], c: eqnCoeffs[2])
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
