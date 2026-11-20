import Foundation

// MARK: - TABLE mode (manual §9)

extension CalculatorEngine {
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
            // Manual §9.5: End > Start, Step nonzero, at most 30 X-values.
            guard tableEndVal > tableStartVal, tableStepVal > 0 else {
                isError = true
                result = "Math ERROR"
                menuState = .none
                return
            }
            let estimated = Int(Foundation.floor((tableEndVal - tableStartVal) / tableStepVal)) + 1
            guard estimated <= 30 else {
                isError = true
                result = "Math ERROR"
                menuState = .none
                return
            }
            tableRows.removeAll()
            var x = tableStartVal
            while x <= tableEndVal + 1e-9 && tableRows.count < 30 {
                var vars = variables
                vars["X"] = x
                let res = CasioEvaluator.evaluate(tableFormula, angleUnit: angleUnit, variables: vars)
                tableRows.append((x: x, fx: res.value ?? 0))
                x += tableStepVal
            }
            menuState = .tablePrompt(step: 4)
        default:
            menuState = .tablePrompt(step: 0)
        }
    }
}
