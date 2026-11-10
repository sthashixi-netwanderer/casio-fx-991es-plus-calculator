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

    static func assertTrue(_ condition: Bool, _ message: String = "") {
        if !condition {
            fatalError("FAIL: condition was false. \(message)")
        }
    }

    static func main() {
        print("Running CasioEvaluator tests...")

        // 1. Arithmetic precedence
        let res1 = CasioEvaluator.evaluate("2+3×4", angleUnit: .deg)
        assertEqual(res1.value ?? 0, 14.0, "2+3×4 should be 14")

        // 2. Parentheses, powers, factorials
        let res2 = CasioEvaluator.evaluate("(2+3)²", angleUnit: .deg)
        assertEqual(res2.value ?? 0, 25.0, "(2+3)² should be 25")

        let resFact = CasioEvaluator.evaluate("5!", angleUnit: .deg)
        assertEqual(resFact.value ?? 0, 120.0, "5! should be 120")

        // 3. Trigonometry across all angle modes (Deg, Rad, Gra)
        let resDeg = CasioEvaluator.evaluate("sin(30)", angleUnit: .deg)
        assertEqual(resDeg.value ?? 0, 0.5, "sin(30 deg) should be 0.5")

        let resRad = CasioEvaluator.evaluate("sin(π÷6)", angleUnit: .rad)
        assertEqual(resRad.value ?? 0, 0.5, "sin(π/6 rad) should be 0.5")

        let resGra = CasioEvaluator.evaluate("sin(50)", angleUnit: .gra)
        assertEqual(resGra.value ?? 0, Foundation.sqrt(0.5), "sin(50 gra) should be sqrt(0.5)")

        // 4. Inverse trigonometry
        let resAsin = CasioEvaluator.evaluate("sin⁻¹(0.5)", angleUnit: .deg)
        assertEqual(resAsin.value ?? 0, 30.0, "sin⁻¹(0.5) in deg should be 30")

        // 5. Domain & Math Errors
        let resDivZero = CasioEvaluator.evaluate("5÷0", angleUnit: .deg)
        assertStringEqual(resDivZero.error ?? "", "Math ERROR", "5÷0 should produce Math ERROR")

        let resSqrtNeg = CasioEvaluator.evaluate("√(-4)", angleUnit: .deg)
        assertStringEqual(resSqrtNeg.error ?? "", "Math ERROR", "√(-4) should produce Math ERROR")

        let resLnZero = CasioEvaluator.evaluate("ln(0)", angleUnit: .deg)
        assertStringEqual(resLnZero.error ?? "", "Math ERROR", "ln(0) should produce Math ERROR")

        // 6. Scientific functions & constants
        let resSci = CasioEvaluator.evaluate("√(16)+log(100)+ln(e)", angleUnit: .deg)
        assertEqual(resSci.value ?? 0, 4.0 + 2.0 + 1.0, "√(16)+log(100)+ln(e) should be 7")

        // 7. Engine state, cursor editing, and DEL / AC
        let engine = CalculatorEngine()
        engine.insert("123")
        assertStringEqual(engine.expression, "123")
        assertEqual(Double(engine.cursorPosition), 3)

        engine.delete()
        assertStringEqual(engine.expression, "12")
        assertEqual(Double(engine.cursorPosition), 2)

        engine.moveCursorLeft()
        assertEqual(Double(engine.cursorPosition), 1)
        engine.insert("9")
        assertStringEqual(engine.expression, "192")

        engine.clearAll()
        assertStringEqual(engine.expression, "")
        assertStringEqual(engine.result, "0")

        // 8. SHIFT & ALPHA modifiers
        engine.toggleShift()
        assertTrue(engine.shiftActive, "SHIFT should be active")
        assertTrue(!engine.alphaActive, "ALPHA should not be active when SHIFT is toggled")

        engine.toggleAlpha()
        assertTrue(engine.alphaActive, "ALPHA should be active")
        assertTrue(!engine.shiftActive, "SHIFT should be deactivated when ALPHA is toggled")

        engine.clearAll()

        // 9. MODE & SETUP Menus
        engine.openModeMenu()
        assertTrue(engine.menuState == .modeMenu, "Menu state should be modeMenu")
        engine.selectMenuOption(3) // TABLE
        assertTrue(engine.activeMode == .table, "Active mode should be TABLE")
        assertTrue(engine.menuState == .none, "Menu should close after selection")

        engine.openSetupMenu()
        assertTrue(engine.menuState == .setupMenu, "Menu state should be setupMenu")
        engine.selectMenuOption(4) // Rad
        assertTrue(engine.angleUnit == .rad, "Angle unit should be RAD")
        assertTrue(engine.menuState == .none, "Menu should close after selection")

        engine.openSetupMenu()
        engine.selectMenuOption(6) // Fix prompt
        assertTrue(engine.menuState == .fixPrompt, "Menu state should be fixPrompt")
        engine.selectMenuOption(2) // Fix 2
        assertTrue(engine.displayFormat == .fix(2), "Display format should be Fix 2")

        print("All CasioEvaluator tests passed successfully!")
    }
}
