import Foundation

// MARK: - CALC & SOLVE helpers (COMP mode, manual §4.29 / §4.30)

extension CalculatorEngine {
    /// Enter a formula with variables, then supply each variable's value.
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

    /// SHIFT+SOLVE: start Newton's-method solving with X's current value as guess.
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
}
