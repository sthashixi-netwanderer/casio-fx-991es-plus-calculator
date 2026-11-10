import Foundation

@main
struct CasioEvaluatorTests {
    static func assertEqual(_ actual: Double, _ expected: Double, accuracy: Double = 1e-6, _ message: String = "") {
        if abs(actual - expected) > accuracy {
            fatalError("FAIL: \(actual) != \(expected). \(message)")
        }
    }

    static func assertStringEqual(_ actual: String, _ expected: String, _ message: String = "") {
        if actual != expected {
            fatalError("FAIL: '\(actual)' != '\(expected)'. \(message)")
        }
    }

    static func main() {
        print("Running CasioEvaluator tests...")

        // Test 1: Arithmetic precedence
        let res1 = CasioEvaluator.evaluate("2+3×4", angleUnit: .deg)
        assertEqual(res1.value ?? 0, 14.0, "2+3×4 should be 14")

        // Test 2: Parentheses and powers
        let res2 = CasioEvaluator.evaluate("(2+3)²", angleUnit: .deg)
        assertEqual(res2.value ?? 0, 25.0, "(2+3)² should be 25")

        // Test 3: Trigonometry in Deg, Rad, Gra
        let resDeg = CasioEvaluator.evaluate("sin(30)", angleUnit: .deg)
        assertEqual(resDeg.value ?? 0, 0.5, "sin(30 deg) should be 0.5")

        let resRad = CasioEvaluator.evaluate("sin(π÷6)", angleUnit: .rad)
        assertEqual(resRad.value ?? 0, 0.5, "sin(π/6 rad) should be 0.5")

        let resGra = CasioEvaluator.evaluate("sin(50)", angleUnit: .gra)
        assertEqual(resGra.value ?? 0, Foundation.sqrt(0.5), "sin(50 gra) = sin(45 deg) should be sqrt(0.5)")

        // Test 4: Division by zero
        let resDivZero = CasioEvaluator.evaluate("5÷0", angleUnit: .deg)
        assertStringEqual(resDivZero.error ?? "", "Math ERROR", "5÷0 should produce Math ERROR")

        // Test 5: Scientific functions
        let resSqrt = CasioEvaluator.evaluate("√(16)+log(100)+ln(e)", angleUnit: .deg)
        assertEqual(resSqrt.value ?? 0, 4.0 + 2.0 + 1.0, "√(16)+log(100)+ln(e) should be 7")

        // Test 6: Engine state machine and editing
        let engine = CalculatorEngine()
        engine.insert("12")
        engine.insert("+")
        engine.insert("8")
        engine.evaluate()
        assertStringEqual(engine.result, "20", "12+8 should evaluate to 20")

        engine.delete() // clears or deletes
        engine.clearAll()
        assertStringEqual(engine.result, "0", "clearAll sets result to 0")

        print("All CasioEvaluator tests passed successfully!")
    }
}
