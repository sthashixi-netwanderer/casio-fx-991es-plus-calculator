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

        // 0. 2D Math AST insertion and cursor navigation
        var mgr = MathASTManager()
        mgr.insertText("2")
        mgr.insertFraction()
        assertTrue(mgr.cursor.slot != .root, "Cursor should be inside fraction denominator")
        mgr.insertText("3")
        mgr.moveRight() // Exit fraction
        mgr.insertText("+")
        mgr.insertRadical()
        mgr.insertText("2")
        let linear = mgr.toLinearString()
        assertStringEqual(linear, "(2)/(3)+√(2)")

        // 0.1 Exact Multi-Term Symbolic Engine
        let s18 = ExactValue.surd(radicand: 18)
        assertEqual(s18.toDouble(), Foundation.sqrt(18.0), accuracy: 1e-6, "sqrt(18) should equal sqrt(18)")
        let halfSqrt2 = ExactValue.surd(coeff: Rational(1, 2), radicand: 2)
        let thirdSqrt2 = ExactValue.surd(coeff: Rational(1, 3), radicand: 2)
        let sumSurd = halfSqrt2 + thirdSqrt2
        assertEqual(sumSurd.toDouble(), Foundation.sqrt(2.0) * 5.0 / 6.0, accuracy: 1e-6, "sqrt(2)/2 + sqrt(2)/3 should be 5*sqrt(2)/6")
        let nodes = sumSurd.toMathNodes()
        assertTrue(!nodes.isEmpty, "toMathNodes() should not be empty")

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
        engine.selectMenuOption(7) // TABLE (fx-991ES PLUS layout)
        assertTrue(engine.activeMode == .table, "Active mode should be TABLE")
        assertTrue(engine.menuState == .tablePrompt(step: 0), "Menu should transition to TABLE prompt")

        engine.openSetupMenu()
        assertTrue(engine.menuState == .setupMenu(page: 1), "Menu state should be setupMenu")
        engine.selectMenuOption(4) // Rad
        assertTrue(engine.angleUnit == .rad, "Angle unit should be RAD")
        assertTrue(engine.menuState == .none, "Menu should close after selection")

        engine.openSetupMenu()
        engine.selectMenuOption(6) // Fix prompt
        assertTrue(engine.menuState == .fixPrompt, "Menu state should be fixPrompt")
        engine.selectMenuOption(2) // Fix 2
        assertTrue(engine.displayFormat == .fix(2), "Display format should be Fix 2")

        // 10. Multi-statement evaluation
        let resMulti = CasioEvaluator.evaluate("3+3 : Ans×4", angleUnit: .deg)
        assertEqual(resMulti.value ?? 0, 24.0, "3+3 : Ans×4 should be 24")

        // 11. Hyperbolic functions
        let resSinh = CasioEvaluator.evaluate("sinh(0)", angleUnit: .deg)
        assertEqual(resSinh.value ?? 0, 0.0, "sinh(0) should be 0")
        let resCosh = CasioEvaluator.evaluate("cosh(0)", angleUnit: .deg)
        assertEqual(resCosh.value ?? 0, 1.0, "cosh(0) should be 1")

        // 12. Permutations & Combinations
        let resNPr = CasioEvaluator.evaluate("5 nPr 2", angleUnit: .deg)
        assertEqual(resNPr.value ?? 0, 20.0, "5 nPr 2 should be 20")
        let resNCr = CasioEvaluator.evaluate("5 nCr 2", angleUnit: .deg)
        assertEqual(resNCr.value ?? 0, 10.0, "5 nCr 2 should be 10")

        // 13. Complex numbers
        let c1 = Complex(real: 3, imag: 4)
        assertEqual(c1.magnitude, 5.0, "Magnitude of 3+4i should be 5")
        let c2 = Complex(real: 1, imag: -2)
        let cSum = c1 + c2
        assertEqual(cSum.real, 4.0)
        assertEqual(cSum.imag, 2.0)
        let cDiv = (c1 / c2)!
        assertEqual(cDiv.real, -1.0)
        assertEqual(cDiv.imag, 2.0)

        // 14. Matrix operations
        let mat = Matrix(elements: [[1, 2], [3, 4]])
        assertEqual(mat.determinant() ?? 0, -2.0, "det([[1,2],[3,4]]) should be -2")
        let inv = mat.inverse()!
        assertEqual(inv.elements[0][0], -2.0)
        assertEqual(inv.elements[0][1], 1.0)
        assertEqual(inv.elements[1][0], 1.5)
        assertEqual(inv.elements[1][1], -0.5)

        // 15. Vector operations
        let v1 = Vector3D(x: 1, y: 2, z: 3)
        let v2 = Vector3D(x: 4, y: 5, z: 6)
        assertEqual(Vector3D.dot(v1, v2), 32.0, "Dot product should be 32")
        let cross = Vector3D.cross(v1, v2)
        assertEqual(cross.x, -3.0)
        assertEqual(cross.y, 6.0)
        assertEqual(cross.z, -3.0)

        // 16. Numerical Calculus: Derivative, Integral, Summation
        let resDeriv = CasioEvaluator.evaluate("d/dx(X^3, 2)", angleUnit: .deg)
        assertEqual(resDeriv.value ?? 0, 12.0, accuracy: 1e-4, "d/dx(x^3, 2) should be 12")

        let resInt = CasioEvaluator.evaluate("∫(X^2, 0, 3)", angleUnit: .deg)
        assertEqual(resInt.value ?? 0, 9.0, accuracy: 1e-4, "∫(x^2, 0, 3) should be 9")

        let resSum = CasioEvaluator.evaluate("Σ(X, 1, 5)", angleUnit: .deg)
        assertEqual(resSum.value ?? 0, 15.0, accuracy: 1e-4, "Σ(x, 1, 5) should be 15")

        // 17. Prime Factorization & Fractions
        let fact72 = CasioEvaluator.primeFactorization(72)
        assertStringEqual(fact72 ?? "", "2³×3²", "72 should factor to 2³×3²")

        let frac = Fraction.fromDouble(0.75)!
        assertStringEqual(frac.formatImproper(), "3⌟4", "0.75 as fraction should be 3⌟4")

        let fracMixed = Fraction.fromDouble(1.5)!
        assertStringEqual(fracMixed.formatMixed(), "1⌟1⌟2", "1.5 as mixed fraction should be 1⌟1⌟2")

        // 18. Constants and Unit Conversions
        let cG = CasioConstants.get(39)! // Gravitational constant G
        assertStringEqual(cG.symbol, "G")
        assertEqual(cG.value, 6.67384e-11)

        let convInCm = CasioConversions.convert(value: 5, code: 1)! // in -> cm
        assertStringEqual(convInCm.name, "in▶cm")
        assertEqual(convInCm.result, 12.7)

        let convKmH = CasioConversions.convert(value: 36, code: 19)! // km/h -> m/s
        assertStringEqual(convKmH.name, "km/h▶m/s")
        assertEqual(convKmH.result, 10.0)

        // 19. Base-N bitwise logic
        let resBitwise = CasioEvaluator.evaluate("12 and 10", angleUnit: .deg)
        assertEqual(resBitwise.value ?? 0, 8.0, "12 and 10 should be 8")

        // 20. Variable storage and retrieval
        engine.clearAll()
        engine.insert("42")
        engine.evaluate()
        engine.storeToVariable("A")
        assertEqual(engine.variables["A"] ?? 0, 42.0, "Variable A should be 42")

        engine.clearAll()
        engine.insert("A×2")
        engine.evaluate()
        assertEqual(engine.lastAnswer, 84.0, "A×2 should be 84")

        // 21. Power states and Off mode
        engine.turnOff()
        assertTrue(engine.isOff, "Engine should be OFF after turnOff")
        engine.turnOn()
        assertTrue(!engine.isOff, "Engine should be ON after turnOn")

        // 22. Integer functions (Int, Intg) and DMS
        let resTrunc = CasioEvaluator.evaluate("Int(5.89)", angleUnit: .deg)
        assertEqual(resTrunc.value ?? 0, 5.0, "Int(5.89) should truncate to 5")

        let resIntg = CasioEvaluator.evaluate("Intg(-2.3)", angleUnit: .deg)
        assertEqual(resIntg.value ?? 0, -3.0, "Intg(-2.3) should floor to -3")

        let dmsStr = CasioEvaluator.toDMS(1.5)
        assertTrue(dmsStr.contains("1°30′"), "1.5 should convert to 1°30′")

        // 23. Full reset
        engine.variables["B"] = 99
        engine.resetAll()
        assertEqual(engine.variables["B"] ?? 0, 0.0, "ResetAll should zero out variables")
        assertTrue(engine.angleUnit == .deg, "ResetAll should reset angle unit to Deg")

        // 24. Auto-closing brackets for unclosed parentheses (normal calculator behavior)
        let resSinNoClose = CasioEvaluator.evaluate("sin(30", angleUnit: .deg)
        assertEqual(resSinNoClose.value ?? 0, 0.5, "sin(30 without closing paren should evaluate to 0.5")

        let resSqrtNoClose = CasioEvaluator.evaluate("√(16", angleUnit: .deg)
        assertEqual(resSqrtNoClose.value ?? 0, 4.0, "√(16 without closing paren should evaluate to 4")

        let resMulNoClose = CasioEvaluator.evaluate("2×(3+4", angleUnit: .deg)
        assertEqual(resMulNoClose.value ?? 0, 14.0, "2×(3+4 without closing paren should evaluate to 14")

        let resNestedNoClose = CasioEvaluator.evaluate("(2+(3×(4+1", angleUnit: .deg)
        assertEqual(resNestedNoClose.value ?? 0, 17.0, "(2+(3×(4+1 with 3 unclosed parens should evaluate to 17")

        let resLogNoClose = CasioEvaluator.evaluate("log(100", angleUnit: .deg)
        assertEqual(resLogNoClose.value ?? 0, 2.0, "log(100 without closing paren should evaluate to 2")

        let resDerivNoClose = CasioEvaluator.evaluate("d/dx(X^2, 2", angleUnit: .deg)
        assertEqual(resDerivNoClose.value ?? 0, 4.0, accuracy: 1e-4, "d/dx(X^2, 2 without closing paren should evaluate to 4")

        let resIntegralNoClose = CasioEvaluator.evaluate("∫(X^2, 0, 3", angleUnit: .deg)
        assertEqual(resIntegralNoClose.value ?? 0, 9.0, accuracy: 1e-4, "∫(X^2, 0, 3 without closing paren should evaluate to 9")

        // 25. Equation Solvers, Table, CALC, SOLVE, and Authenticity (fx-991ES PLUS Manual)
        // Quadratic: x² - 5x + 6 = 0 -> X1=3, X2=2
        let qRoots = CasioEvaluator.solveQuadratic(a: 1, b: -5, c: 6)
        assertTrue(qRoots.contains("X1=3") || qRoots.contains("X=3"), "Quadratic roots should include 3")

        // Simultaneous 2 unknowns: x + 2y = 3, 2x + 3y = 4 -> X = -1, Y = 2
        let sim2 = CasioEvaluator.solveSimultaneous2(a1: 1, b1: 2, c1: 3, a2: 2, b2: 3, c2: 4)
        assertTrue(sim2[0] == "X=-1" && sim2[1] == "Y=2", "Simultaneous 2 unknowns should be X=-1, Y=2")

        // Newton's method SOLVE: X^2 - 4 = 0 with guess 1 -> root 2
        let solveRes = CasioEvaluator.solveEquation("X^2 - 4", initialGuess: 1.0, angleUnit: .deg, variables: [:])
        assertEqual(solveRes?.root ?? 0, 2.0, accuracy: 1e-5, "Solve X^2-4 should yield 2")

        // Authenticity Verification Mode (MODE 0)
        engine.clearAll()
        engine.openModeMenu()
        engine.selectMenuOption(0)
        assertTrue(engine.menuState == .authenticityView, "MODE 0 should open authenticityView")

        // TABLE Mode generation
        engine.clearAll()
        engine.expression = "X^2"
        engine.startTable()
        engine.advanceTablePrompt() // to start
        engine.advanceTablePrompt(val: 0) // start = 0
        engine.advanceTablePrompt(val: 2) // end = 2
        engine.advanceTablePrompt(val: 1) // step = 1
        assertEqual(Double(engine.tableRows.count), 3.0, "Table 0 to 2 step 1 should produce 3 rows")
        assertEqual(engine.tableRows[0].fx, 0.0)
        assertEqual(engine.tableRows[1].fx, 1.0)
        assertEqual(engine.tableRows[2].fx, 4.0)

        print("All CasioEvaluator tests passed successfully!")
    }
}
