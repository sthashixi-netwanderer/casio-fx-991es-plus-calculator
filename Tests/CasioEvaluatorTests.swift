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

        // 0.2 CalculatorEngine 2D AST Evaluation & S<=>D Toggle
        let testEng = CalculatorEngine()
        testEng.insertASTText("1")
        testEng.insertASTFraction()
        testEng.insertASTText("2")
        testEng.moveCursorRight()
        testEng.insertASTText("+")
        testEng.insertASTText("1")
        testEng.insertASTFraction()
        testEng.insertASTText("3")
        testEng.evaluate()
        assertTrue(testEng.exactResult != nil, "testEng.exactResult should be set")
        assertEqual(testEng.exactResult?.toDouble() ?? 0, 5.0 / 6.0, accuracy: 1e-6, "1/2 + 1/3 should be 5/6")
        assertTrue(!testEng.isShowingDecimal, "Initially in MthIO, exact result should be shown")
        testEng.toggleSD()
        assertTrue(testEng.isShowingDecimal, "Pressing S<=>D should toggle to decimal")

        // 0.3 Arbitrary Base Logarithm: log_2(8) = 3
        let logEng = CalculatorEngine()
        logEng.insertASTLogBase()
        logEng.insertASTText("2")
        logEng.moveCursorRight()
        logEng.insertASTText("8")
        logEng.evaluate()
        assertEqual(Double(logEng.result) ?? (logEng.exactResult?.toDouble() ?? 0), 3.0, accuracy: 1e-6, "log_2(8) should evaluate to 3")

        // 0.4 Nth Root: 3√8 = 2
        let rootEng = CalculatorEngine()
        rootEng.insertASTNthRoot()
        rootEng.insertASTText("3")
        rootEng.moveCursorRight()
        rootEng.insertASTText("8")
        rootEng.evaluate()
        assertEqual(Double(rootEng.result) ?? (rootEng.exactResult?.toDouble() ?? 0), 2.0, accuracy: 1e-6, "3√8 should evaluate to 2")

        // 0.5 Template Deletion Without Trap
        let trapEng = CalculatorEngine()
        trapEng.insertASTFraction()
        assertTrue(!trapEng.astManager.root.isEmpty, "Fraction should be created")
        trapEng.delete()
        assertTrue(trapEng.astManager.root.isEmpty, "Empty fraction should be deleted without getting trapped")

        let captureEng = CalculatorEngine()
        captureEng.insertASTText("5")
        captureEng.insertASTFraction()
        captureEng.delete()
        assertStringEqual(captureEng.astManager.toLinearString(), "5", "Deleting empty denominator should restore numerator")

        // 0.6 Transcendental Non-Coercion (1 / (2π) must not coerce to 113/710)
        let piEng = CalculatorEngine()
        piEng.insert("1÷(2×π)")
        piEng.evaluate()
        assertTrue(!piEng.result.contains("113"), "1/(2π) should display decimal, not 113/710")
        assertEqual(Double(piEng.result) ?? 0, 1.0 / (2.0 * Double.pi), accuracy: 1e-6, "1/(2π) should equal 0.159155")

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
        assertStringEqual(engine.result, "", "Result line should be blank while no calculation is shown (authentic Casio)")

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
        assertTrue(dmsStr.contains("1°30'"), "1.5 should convert to 1°30'0\" (Casio glyphs)")

        // 22b. Authentic sexagesimal formatting (Casio glyph style: ° ' ")
        assertStringEqual(CasioEvaluator.formatSexagesimal(2.255), "2°15'18\"", "2.255 should format as 2°15'18\"")
        assertStringEqual(CasioEvaluator.formatSexagesimal(3.0), "3°0'0\"", "3.0 should format as 3°0'0\"")
        assertStringEqual(CasioEvaluator.toDMS(1.5), "1°30'0\"", "1.5 should convert to 1°30'0\"")

        // 26. Post-= state machine: digit starts a FRESH calculation (fx-991ES behavior)
        let freshEng = CalculatorEngine()
        freshEng.insertASTText("15"); freshEng.insertASTText("÷"); freshEng.insertASTText("3")
        freshEng.evaluate()
        assertTrue(freshEng.isShowingResult, "Engine should be in result-shown state after =")
        freshEng.insertASTText("45"); freshEng.insertASTText("÷"); freshEng.insertASTText("3")
        assertStringEqual(freshEng.expression, "45÷3", "Typing digits after = must start a fresh expression")
        freshEng.evaluate()
        assertEqual(freshEng.lastAnswer, 15.0, "45÷3 after a previous 15÷3= should be 15, not glued into old expression")

        // 27. Operator (+ − × ÷) right after = auto-inserts the Ans command (manual E-25)
        let ansEng = CalculatorEngine()
        ansEng.insertASTText("7"); ansEng.insertASTText("×"); ansEng.insertASTText("6")
        ansEng.evaluate()
        ansEng.insertASTText("÷"); ansEng.insertASTText("2")
        assertTrue(ansEng.expression.hasPrefix("Ans"), "÷ after = should auto-insert Ans, got '\(ansEng.expression)'")
        ansEng.evaluate()
        assertEqual(ansEng.lastAnswer, 21.0, "Ans÷2 with Ans=42 should be 21")

        // 28. Ans participates in exact evaluation (Ans÷2 with Ans=5 -> exact 5/2)
        let ansExactEng = CalculatorEngine()
        ansExactEng.insertASTText("15"); ansExactEng.insertASTText("÷"); ansExactEng.insertASTText("3")
        ansExactEng.evaluate()
        ansExactEng.insertASTText("÷"); ansExactEng.insertASTText("2")
        ansExactEng.evaluate()
        assertEqual(ansExactEng.exactResult?.toDouble() ?? 0, 2.5, accuracy: 1e-9, "Ans÷2 with Ans=5 should be exact 5/2")

        // 29. DMS input inserts markers and evaluates sexagesimally (manual p.22: 2°20'30" + 0°39'30" = 3°0'0")
        let dmsEng = CalculatorEngine()
        dmsEng.insertASTText("2"); dmsEng.insertDMSMark()
        dmsEng.insertASTText("20"); dmsEng.insertDMSMark()
        dmsEng.insertASTText("30"); dmsEng.insertDMSMark()
        dmsEng.insertASTText("+")
        dmsEng.insertASTText("0"); dmsEng.insertDMSMark()
        dmsEng.insertASTText("39"); dmsEng.insertDMSMark()
        dmsEng.insertASTText("30"); dmsEng.insertDMSMark()
        assertStringEqual(dmsEng.expression, "2°20'30\"+0°39'30\"", "DMS markers should render positionally as °, ', \"")
        dmsEng.evaluate()
        assertStringEqual(dmsEng.result, "3°0'0\"", "DMS arithmetic must display a sexagesimal result")
        assertTrue(dmsEng.isShowingDMS, "DMS result should be flagged as sexagesimal")

        // 30. DMS × decimal also displays sexagesimal (manual p.22)
        let dmsMulEng = CalculatorEngine()
        dmsMulEng.insertASTText("2"); dmsMulEng.insertDMSMark()
        dmsMulEng.insertASTText("30"); dmsMulEng.insertDMSMark()
        dmsMulEng.insertASTText("×"); dmsMulEng.insertASTText("2")
        dmsMulEng.evaluate()
        assertStringEqual(dmsMulEng.result, "5°0'0\"", "2°30'×2 should be 5°0'0\"")

        // 31. °'" on a displayed result toggles decimal ⇔ sexagesimal (manual p.23)
        let dmsToggleEng = CalculatorEngine()
        dmsToggleEng.insertASTText("2.255")
        dmsToggleEng.evaluate()
        dmsToggleEng.insertDMSMark() // on result: toggle
        assertStringEqual(dmsToggleEng.result, "2°15'18\"", "°'\" on result should toggle to 2°15'18\"")
        assertEqual(dmsToggleEng.lastAnswer, 2.255, accuracy: 1e-9, "Toggle must not change the underlying Ans value")
        dmsToggleEng.insertDMSMark()
        assertTrue(!dmsToggleEng.isShowingDMS, "Second °'\" press should toggle back to decimal form")

        // 32. Malformed DMS input (adjacent markers, no minutes) is a Syntax ERROR
        let dmsBad = CasioEvaluator.evaluate("45°'17\"", angleUnit: .deg)
        assertStringEqual(dmsBad.error ?? "", "Syntax ERROR", "45°'17\" (missing minutes) should be Syntax ERROR")

        // 33. Mixed fraction template (SHIFT + a b/c): 2[integer] 1/3 -> 7/3
        let mixedEng = CalculatorEngine()
        mixedEng.insertASTText("2")
        mixedEng.insertASTMixedFraction()
        mixedEng.insertASTText("1")
        mixedEng.moveCursorDown() // numerator -> denominator
        mixedEng.insertASTText("3")
        assertStringEqual(mixedEng.expression, "(2+(1)/(3))", "Mixed template linear form")
        mixedEng.evaluate()
        assertEqual(mixedEng.exactResult?.toDouble() ?? 0, 7.0 / 3.0, accuracy: 1e-9, "Mixed 2 and 1/3 should be 7/3")

        // 34. Fraction template must not grab operator as numerator
        let grabEng = CalculatorEngine()
        grabEng.insertASTText("15"); grabEng.insertASTText("÷")
        grabEng.insertASTFraction()
        grabEng.insertASTText("3")
        assertStringEqual(grabEng.expression, "15÷(3)/()", "a b/c after an operator must NOT grab ÷ as numerator")
        grabEng.moveCursorDown()
        grabEng.insertASTText("4")
        grabEng.evaluate()
        assertEqual(grabEng.lastAnswer, 20.0, "15÷(3/4) should be 20")

        // 35. ENG key shifts decimal in multiples of 3 (manual p.24)
        let engEng = CalculatorEngine()
        engEng.insertASTText("12345")
        engEng.evaluate()
        engEng.shiftEng(left: false)
        assertStringEqual(engEng.result, "12.345×10^3", "ENG should shift to 12.345×10^3")
        engEng.shiftEng(left: false)
        assertStringEqual(engEng.result, "0.012345×10^6", "Second ENG press should shift to 0.012345×10^6")
        engEng.shiftEng(left: true)
        assertStringEqual(engEng.result, "12.345×10^3", "SHIFT+ENG (←) should shift back")

        // 36. DRG▶ (SHIFT+Ans) converts the displayed result between angle units
        let drgEng = CalculatorEngine()
        drgEng.angleUnit = .rad
        drgEng.insertASTText("π"); drgEng.insertASTText("÷"); drgEng.insertASTText("6")
        drgEng.evaluate()
        drgEng.convertResultAngleUnit() // rad -> gra? cycle order deg->rad->gra: rad->gra... assert deg step below
        // cycle: deg(0) -> rad(1) -> gra(2). Current unit rad(1): first press -> gra(2)
        let graVal = 0.5235987755982988 * 200.0 / Double.pi
        assertEqual(Double(drgEng.result.replacingOccurrences(of: "×10^", with: "e")) ?? -999, graVal, accuracy: 1e-6, "DRG▶ from rad should show grads")

        // 37. Rnd (SHIFT+0) rounds the displayed value (manual p.24)
        let rndEng = CalculatorEngine()
        rndEng.insertASTText("2"); rndEng.insertASTText("÷"); rndEng.insertASTText("3")
        rndEng.evaluate()
        rndEng.roundDisplayed()
        assertEqual(rndEng.lastAnswer, 0.6666666667, accuracy: 1e-12, "Rnd should round Ans to display digits (0.6666666667)")

        // 38. RCL recalls a stored variable value into the input
        let rclEng = CalculatorEngine()
        rclEng.insertASTText("42"); rclEng.evaluate()
        rclEng.waitingForSto = true
        rclEng.handleVariableSelection("A")
        assertEqual(rclEng.variables["A"] ?? 0, 42.0, "STO A should store 42")
        rclEng.clearAll()
        rclEng.waitingForRcl = true
        rclEng.handleVariableSelection("A")
        assertStringEqual(rclEng.expression, "42", "RCL A should insert the stored value")

        // 39. nPr displayed as P must tokenize (5P2 = 20, authentic display glyph)
        let pRes = CasioEvaluator.evaluate("5P2", angleUnit: .deg)
        assertEqual(pRes.value ?? 0, 20.0, "5P2 (nPr shown as P) should be 20")
        let cRes = CasioEvaluator.evaluate("5C2", angleUnit: .deg)
        assertEqual(cRes.value ?? 0, 10.0, "5C2 (nCr shown as C) should be 10")

        // 40. SHIFT+S⇔D (a b/c ⇔ d/c) renders mixed fractions in exact results
        let mixDispEng = CalculatorEngine()
        mixDispEng.insertASTText("7"); mixDispEng.insertASTText("÷"); mixDispEng.insertASTText("3")
        mixDispEng.evaluate()
        mixDispEng.toggleImproperMixed()
        assertTrue(mixDispEng.displayFormat == .mixedFraction, "SHIFT+S⇔D should switch to mixed display")

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

        // 41. Decimal-keyed input stays decimal; S⇔D reveals the fraction form
        let decEng = CalculatorEngine()
        decEng.insertASTText("2.255")
        decEng.evaluate()
        assertStringEqual(decEng.result, "2.255", "Decimal input must display decimal, not auto-fractionize")
        assertTrue(decEng.isShowingDecimal, "Decimal result should be flagged decimal")
        decEng.toggleSD()
        assertTrue(decEng.result.contains("451"), "S⇔D should reveal the fraction form 451/200")

        // 42. Pure rational arithmetic still auto-fractionizes (1÷3 = 1⌸3)
        let divEng = CalculatorEngine()
        divEng.insertASTText("1"); divEng.insertASTText("÷"); divEng.insertASTText("3")
        divEng.evaluate()
        assertTrue(divEng.exactResult != nil, "1÷3 should keep an exact fraction result")

        // 43. Matrix Mode (fx-991ES PLUS manual pp.44-47)
        // 43a. MatrixEvaluator: addition, multiplication, scalar, det, Trn
        let mA = Matrix(elements: [[1, 2], [3, 4]])
        let mB = Matrix(elements: [[5, 6], [7, 8]])
        let matDict = ["MatA": mA, "MatB": mB, "MatAns": Matrix(rows: 2, cols: 2)]

        if case .matrix(let sum)? = MatrixEvaluator.evaluate("MatA+MatB", matrices: matDict).value {
            assertEqual(sum.elements[0][0], 6.0, "MatA+MatB [0][0]")
            assertEqual(sum.elements[1][1], 12.0, "MatA+MatB [1][1]")
        } else {
            fatalError("FAIL: MatA+MatB should produce a matrix")
        }

        if case .matrix(let prod)? = MatrixEvaluator.evaluate("MatA×MatB", matrices: matDict).value {
            assertEqual(prod.elements[0][0], 19.0, "MatA×MatB [0][0] should be 19")
            assertEqual(prod.elements[1][1], 50.0, "MatA×MatB [1][1] should be 50")
        } else {
            fatalError("FAIL: MatA×MatB should produce a matrix")
        }

        if case .matrix(let scaled)? = MatrixEvaluator.evaluate("3×MatA", matrices: matDict).value {
            assertEqual(scaled.elements[0][0], 3.0, "3×MatA scaling")
            assertEqual(scaled.elements[1][0], 9.0, "3×MatA scaling")
        } else {
            fatalError("FAIL: 3×MatA should produce a matrix")
        }

        if case .scalar(let det)? = MatrixEvaluator.evaluate("det(MatA)", matrices: matDict).value {
            assertEqual(det, -2.0, "det(MatA) should be -2")
        } else {
            fatalError("FAIL: det(MatA) should produce a scalar")
        }

        if case .matrix(let trn)? = MatrixEvaluator.evaluate("Trn(MatA)", matrices: matDict).value {
            assertEqual(trn.elements[0][1], 3.0, "Trn(MatA) transposes")
            assertEqual(trn.elements[1][0], 2.0, "Trn(MatA) transposes")
        } else {
            fatalError("FAIL: Trn(MatA) should produce a matrix")
        }

        // 43b. Postfix inverse and square (as inserted by x⁻¹ and x² keys)
        if case .matrix(let inv)? = MatrixEvaluator.evaluate("(MatA)^(-1)", matrices: matDict).value {
            assertEqual(inv.elements[0][0], -2.0, "MatA⁻¹ [0][0]")
            assertEqual(inv.elements[0][1], 1.0, "MatA⁻¹ [0][1]")
            assertEqual(inv.elements[1][0], 1.5, "MatA⁻¹ [1][0]")
        } else {
            fatalError("FAIL: (MatA)^(-1) should produce the inverse matrix")
        }

        if case .matrix(let sq)? = MatrixEvaluator.evaluate("MatA²", matrices: matDict).value {
            assertEqual(sq.elements[0][0], 7.0, "MatA² [0][0] should be 7")
            assertEqual(sq.elements[1][1], 22.0, "MatA² [1][1] should be 22")
        } else {
            fatalError("FAIL: MatA² should produce a matrix")
        }

        // 43c. Scalar results continue in expressions; unary minus works
        if case .scalar(let mixed)? = MatrixEvaluator.evaluate("det(MatA)+1", matrices: matDict).value {
            assertEqual(mixed, -1.0, "det(MatA)+1 should be -1")
        } else {
            fatalError("FAIL: det(MatA)+1 should produce a scalar")
        }
        if case .scalar(let negDet)? = MatrixEvaluator.evaluate("-det(MatA)", matrices: matDict).value {
            assertEqual(negDet, 2.0, "-det(MatA) should be 2")
        } else {
            fatalError("FAIL: -det(MatA) should produce a scalar")
        }

        // 43d. Errors: dimension mismatch, undefined matrix, singular inverse
        let m23 = Matrix(elements: [[1, 2, 3], [4, 5, 6]])
        let badDict = ["MatA": mA, "MatC": m23]
        assertStringEqual(MatrixEvaluator.evaluate("MatA+MatC", matrices: badDict).error ?? "", "Dim ERROR",
                          "2×2 + 2×3 must report Dim ERROR")
        assertStringEqual(MatrixEvaluator.evaluate("MatB", matrices: badDict).error ?? "", "Dim ERROR",
                          "Undefined matrix must report Dim ERROR")
        let singular = Matrix(elements: [[1, 2], [2, 4]])
        let singDict = ["MatA": singular]
        assertStringEqual(MatrixEvaluator.evaluate("(MatA)^(-1)", matrices: singDict).error ?? "", "Math ERROR",
                          "Singular inverse must report Math ERROR")

        // 43e. Engine Dim/Data flow: dim prompt → cell editor → row-major fill
        let matEng = CalculatorEngine()
        matEng.menuState = .matrixDimSelect
        matEng.selectMenuOption(1)
        guard case .matrixDimPrompt(let dimName) = matEng.menuState else {
            fatalError("FAIL: Dim → MatA should open the dimension prompt")
        }
        assertStringEqual(dimName, "MatA", "Dim target should be MatA")
        matEng.confirmMatrixDim(buffer: "2×2")
        guard case .matrixCellEditor(let editName, let er, let ec) = matEng.menuState, editName == "MatA", er == 1, ec == 1 else {
            fatalError("FAIL: Confirming 2×2 should open the cell editor at [1,1]")
        }
        let cellValues: [Double] = [1, 2, 3, 4]
        for v in cellValues { matEng.commitMatrixCell(val: v) }
        assertTrue(matEng.menuState == .none, "Editing the last cell should return to the calc screen")
        assertEqual(matEng.matA.elements[0][0], 1.0, "MatA[1,1] = 1")
        assertEqual(matEng.matA.elements[0][1], 2.0, "MatA[1,2] = 2")
        assertEqual(matEng.matA.elements[1][0], 3.0, "MatA[2,1] = 3")
        assertEqual(matEng.matA.elements[1][1], 4.0, "MatA[2,2] = 4")
        assertTrue(matEng.definedMatrices.contains("MatA"), "Defining dims marks MatA defined")

        // Cell cursor navigation wraps like the real grid editor
        matEng.menuState = .matrixCellEditor(name: "MatA", row: 1, col: 1)
        matEng.moveMatrixCell(dx: -1, dy: 0)
        guard case .matrixCellEditor(_, let wr, let wc) = matEng.menuState else {
            fatalError("FAIL: cell editor should remain active after navigation")
        }
        assertTrue(wr == 1 && wc == 2, "Left from [1,1] wraps to [1,2]")

        // 43f. Matrix menu inserts tokens into the expression
        let tokEng = CalculatorEngine()
        tokEng.menuState = .matrixMenu
        tokEng.selectMenuOption(3) // MatA
        assertTrue(tokEng.astManager.toLinearString().contains("MatA"), "3:MatA inserts MatA")
        tokEng.menuState = .matrixMenu
        tokEng.selectMenuOption(7) // det(
        assertTrue(tokEng.astManager.toLinearString().contains("det("), "7:det inserts det(")
        tokEng.menuState = .matrixMenu
        tokEng.selectMenuOption(8) // Trn(
        assertTrue(tokEng.astManager.toLinearString().contains("Trn("), "8:Trn inserts Trn(")
        tokEng.menuState = .matrixMenu
        tokEng.selectMenuOption(6) // MatAns
        assertTrue(tokEng.astManager.toLinearString().contains("MatAns"), "6:MatAns inserts MatAns")

        // 43g. Engine evaluates MatA+MatB and stores the result in MatAns
        let evalEng = CalculatorEngine()
        evalEng.matA = mA
        evalEng.matB = mB
        evalEng.definedMatrices = ["MatA", "MatB"]
        evalEng.insert("MatA+MatB")
        evalEng.evaluate()
        assertTrue(evalEng.matrixResult != nil, "Matrix result should be flagged for grid display")
        assertEqual(evalEng.matAns.elements[0][0], 6.0, "MatAns[1,1] should be 6 after MatA+MatB")
        assertEqual(evalEng.matAns.elements[1][1], 12.0, "MatAns[2,2] should be 12 after MatA+MatB")

        // det() result is a scalar: lastAnswer set, MatAns not overwritten
        evalEng.clearAll()
        evalEng.insert("det(MatA)")
        evalEng.evaluate()
        assertEqual(evalEng.lastAnswer, -2.0, accuracy: 1e-9, "det(MatA) via engine should set lastAnswer")
        assertTrue(evalEng.matrixResult == nil, "Scalar result must not display as a matrix grid")

        // 43h. Using an undefined matrix reports Dim ERROR
        let undefEng = CalculatorEngine()
        undefEng.insert("MatA×2")
        undefEng.evaluate()
        assertStringEqual(undefEng.result, "Dim ERROR", "Undefined MatA in a calculation must report Dim ERROR")

        // 43i. Invalid dimensions are rejected with Syntax ERROR
        let badDimEng = CalculatorEngine()
        badDimEng.menuState = .matrixDimPrompt(name: "MatA")
        badDimEng.confirmMatrixDim(buffer: "9×9")
        assertTrue(badDimEng.isError && badDimEng.result == "Syntax ERROR", "9×9 exceeds the 3×3 limit → Syntax ERROR")

        // 43j. "=" on the untouched dim prompt accepts the prefilled dimensions
        let preDimEng = CalculatorEngine()
        preDimEng.menuState = .matrixDimPrompt(name: "MatA")
        preDimEng.confirmMatrixDim(buffer: "")
        assertTrue(!preDimEng.isError, "Empty dim entry should accept the current 3×3")
        assertTrue(preDimEng.definedMatrices.contains("MatA"), "Prefilled confirm marks MatA defined")

        // 43k. Matrix powers — manual §13 / quick reference (A = [[2,1],[1,1]])
        let powA = Matrix(elements: [[2, 1], [1, 1]])
        let absB = Matrix(elements: [[2, -1], [-1, 2]]) // manual §14
        let powDict = ["MatA": powA, "MatB": absB]

        if case .matrix(let sq)? = MatrixEvaluator.evaluate("(MatA)^(2)", matrices: powDict).value {
            assertEqual(sq.elements[0][0], 5.0, "A² [0][0] should be 5")
            assertEqual(sq.elements[1][1], 2.0, "A² [1][1] should be 2")
        } else {
            fatalError("FAIL: (MatA)^(2) should produce A²")
        }

        if case .matrix(let cub)? = MatrixEvaluator.evaluate("(MatA)^(3)", matrices: powDict).value {
            assertEqual(cub.elements[0][0], 13.0, "A³ [0][0] should be 13")
            assertEqual(cub.elements[0][1], 8.0, "A³ [0][1] should be 8")
            assertEqual(cub.elements[1][0], 8.0, "A³ [1][0] should be 8")
            assertEqual(cub.elements[1][1], 5.0, "A³ [1][1] should be 5")
        } else {
            fatalError("FAIL: (MatA)^(3) should produce A³")
        }

        // The LineIO x³ key inserts the literal cube glyph
        if case .matrix(let cub)? = MatrixEvaluator.evaluate("MatA³", matrices: powDict).value {
            assertEqual(cub.elements[0][0], 13.0, "MatA³ (LineIO) [0][0] should be 13")
        } else {
            fatalError("FAIL: MatA³ should produce A³")
        }

        // x² / x³ / x⁻¹ keys must grab MatA as the exponent base in MthIO
        for (power, expected) in [("2", "(MatA)^(2)"), ("3", "(MatA)^(3)"), ("-1", "(MatA)^(-1)")] {
            let keyEng = CalculatorEngine()
            keyEng.insertASTText("MatA")
            keyEng.insertASTExponent()
            keyEng.insertASTText(power)
            keyEng.moveCursorRight()
            assertStringEqual(keyEng.astManager.toLinearString(), expected, "Exponent key \(power) on MatA")
            assertTrue(MatrixEvaluator.evaluate(expected, matrices: powDict).error == nil,
                       "\(expected) must evaluate without error")
        }

        // ×10ˣ key builds a real exponent template in MthIO (no caret in the LCD)
        let pow10Eng = CalculatorEngine()
        pow10Eng.insertASTText("5")
        pow10Eng.insertASTText("×")
        pow10Eng.insertASTText("10")
        pow10Eng.insertASTExponent()
        pow10Eng.insertASTText("3")
        pow10Eng.moveCursorRight()
        assertStringEqual(pow10Eng.astManager.toLinearString(), "5×(10)^(3)", "×10ˣ key should use an exponent node")
        pow10Eng.evaluate()
        assertEqual(pow10Eng.lastAnswer, 5000.0, accuracy: 1e-6, "5 × 10³ should be 5000")

        // Powers require a square matrix
        let rectDict = ["MatC": Matrix(elements: [[1, 2, 3], [4, 5, 6]])]
        assertStringEqual(MatrixEvaluator.evaluate("(MatC)^(3)", matrices: rectDict).error ?? "", "Dim ERROR",
                          "Cube of a rectangular matrix should be Dim ERROR")

        // End-to-end: cube key sequence evaluates and updates MatAns
        let cubeEng = CalculatorEngine()
        cubeEng.matA = powA
        cubeEng.definedMatrices = ["MatA"]
        cubeEng.insertASTText("MatA")
        cubeEng.insertASTExponent()
        cubeEng.insertASTText("3")
        cubeEng.moveCursorRight()
        cubeEng.evaluate()
        assertTrue(cubeEng.matrixResult != nil, "A³ via keys should display a matrix grid")
        assertEqual(cubeEng.matAns.elements[0][0], 13.0, "MatAns[1,1] after A³ should be 13")

        // 43l. Abs( returns element-wise absolute value — manual §14 (not a determinant)
        if case .matrix(let absMat)? = MatrixEvaluator.evaluate("Abs(MatB)", matrices: powDict).value {
            assertEqual(absMat.elements[0][0], 2.0, "Abs(B) [0][0]")
            assertEqual(absMat.elements[0][1], 1.0, "Abs(B) [0][1]")
            assertEqual(absMat.elements[1][0], 1.0, "Abs(B) [1][0]")
            assertEqual(absMat.elements[1][1], 2.0, "Abs(B) [1][1]")
        } else {
            fatalError("FAIL: Abs(MatB) should produce element-wise absolute values")
        }

        if case .matrix(let absMat)? = MatrixEvaluator.evaluate("abs(MatB)", matrices: powDict).value {
            assertEqual(absMat.elements[0][1], 1.0, "abs(MatB) LineIO form")
        } else {
            fatalError("FAIL: abs(MatB) LineIO form should work")
        }

        if case .scalar(let absDet)? = MatrixEvaluator.evaluate("Abs(det(MatA))", matrices: powDict).value {
            assertEqual(absDet, 1.0, "Abs of a scalar result")
        } else {
            fatalError("FAIL: Abs(det(MatA)) should produce a scalar")
        }

        // SHIFT + hyp inserts Abs, then the matrix token goes into its argument
        let absKeyEng = CalculatorEngine()
        absKeyEng.insertASTFunction("Abs")
        absKeyEng.insertASTText("MatB")
        absKeyEng.moveCursorRight()
        assertStringEqual(absKeyEng.astManager.toLinearString(), "Abs(MatB)", "Abs key path")

        // 43m. Manual §17 errors and all nine supported dimension shapes.
        // The guide's "six shapes" claim is inaccurate — the classic ES PLUS
        // dimension menu is 1:3×3 … 9:1×1 (confirmed against Casio's own page and
        // two independent fx-991ES PLUS emulators).
        assertStringEqual(MatrixEvaluator.evaluate("det(MatC)", matrices: rectDict).error ?? "", "Math ERROR",
                          "det of a non-square matrix should be Math ERROR")

        let validDims = ["3×3", "3×2", "3×1", "2×3", "2×2", "2×1", "1×3", "1×2", "1×1"]
        for dim in validDims {
            let dEng = CalculatorEngine()
            dEng.menuState = .matrixDimPrompt(name: "MatA")
            dEng.confirmMatrixDim(buffer: dim)
            assertTrue(!dEng.isError && dEng.dimsString(for: "MatA") == dim,
                       "Dimension \(dim) should be accepted and applied")
        }
        let tooBig = CalculatorEngine()
        tooBig.menuState = .matrixDimPrompt(name: "MatA")
        tooBig.confirmMatrixDim(buffer: "4×4")
        assertTrue(tooBig.isError && tooBig.result == "Syntax ERROR", "4×4 exceeds the 3×3 limit")

        // A 1-row matrix must work end-to-end, including transpose to a column
        let rowEng = CalculatorEngine()
        rowEng.menuState = .matrixDimPrompt(name: "MatA")
        rowEng.confirmMatrixDim(buffer: "1×3")
        for v in [1.0, 2.0, 3.0] { rowEng.commitMatrixCell(val: v) }
        assertEqual(Double(rowEng.matA.rows), 1.0, "MatA should have 1 row")
        assertEqual(Double(rowEng.matA.cols), 3.0, "MatA should have 3 columns")
        rowEng.insert("MatA")
        rowEng.evaluate()
        assertTrue(rowEng.matrixResult != nil, "A 1×3 matrix should evaluate and display")
        rowEng.clearAll()
        rowEng.insert("Trn(MatA)")
        rowEng.evaluate()
        if let trn = rowEng.matrixResult {
            assertEqual(Double(trn.rows), 3.0, "Transpose of 1×3 should have 3 rows")
            assertEqual(Double(trn.cols), 1.0, "Transpose of 1×3 should have 1 column")
        } else {
            fatalError("FAIL: Trn of a 1×3 matrix should produce a 3×1 matrix")
        }

        // 44. Held-key safety: a key that fires hundreds of times (e.g. a held
        // √ key) must not make the app unresponsive. Input is bounded like the
        // real fx-991ES expression buffer, and DEL / AC still recover.
        let holdEng = CalculatorEngine()
        let holdStart = Date()
        for _ in 0..<5000 { holdEng.insertASTRadical() }
        let holdElapsed = Date().timeIntervalSince(holdStart)
        assertTrue(holdElapsed < 5.0, "5000 rapid key actions must stay responsive (took \(holdElapsed)s)")
        assertTrue(holdEng.astManager.nodeCount <= MathASTManager.maxNodes,
                   "AST node count must stay at or below the cap")
        assertTrue(holdEng.astManager.expressionDepth <= MathASTManager.maxDepth,
                   "AST nesting depth must stay at or below the cap")
        assertTrue(holdEng.astManager.isAtCapacity, "Repeated input should eventually hit the buffer cap")

        // Capacity never traps the user: deletion and a fresh expression work.
        holdEng.delete()
        holdEng.clearAll()
        holdEng.insertASTText("1")
        assertStringEqual(holdEng.astManager.toLinearString(), "1", "Input should resume after AC at capacity")

        // A long-but-legal expression (below the cap) still evaluates correctly.
        let nestedEng = CalculatorEngine()
        nestedEng.insertASTText("2")
        for _ in 0..<8 { nestedEng.insertASTRadical() }
        assertTrue(!nestedEng.astManager.isAtCapacity, "8 nested radicals are within the buffer limit")
        assertTrue(!nestedEng.astManager.toLinearString().isEmpty, "Nested radicals should still produce an expression")

        // 45. CMPLX mode: menu commands and polar display (manual §5)
        let cx = CalculatorEngine()
        cx.activeMode = .cmplx
        cx.menuState = .cmplxMenu
        cx.selectMenuOption(4) // ▶r∠θ
        assertStringEqual(cx.complexFormat.rawValue, "r∠θ", "CMPLX menu 4 selects polar format")
        cx.menuState = .cmplxMenu
        cx.selectMenuOption(5) // ▶a+bi
        assertStringEqual(cx.complexFormat.rawValue, "a+bi", "CMPLX menu 5 selects rectangular format")
        cx.menuState = .cmplxMenu
        cx.selectMenuOption(3) // Conjg(
        assertTrue(cx.astManager.toLinearString().contains("Conjg("), "CMPLX menu 3 inserts Conjg(")

        let polarEng = CalculatorEngine()
        polarEng.activeMode = .cmplx
        polarEng.complexFormat = .polar
        polarEng.insert("1+i")
        polarEng.evaluate()
        assertTrue(polarEng.result.contains("∠"), "Polar complex result should contain ∠, got \(polarEng.result)")

        // 46. STAT mode: data, summary statistics and linear regression (manual §6)
        let st = CalculatorEngine()
        st.activeMode = .stat
        st.statType = "1-VAR"
        for (i, v) in [2.0, 3.0, 5.0, 5.0, 7.0].enumerated() { st.commitStatValue(v, row: i) }
        assertEqual(st.statistic("n") ?? 0, 5.0, "STAT n")
        assertEqual(st.statistic("mean") ?? 0, 4.4, "STAT mean")
        assertEqual(st.statistic("min") ?? 0, 2.0, "STAT min")
        assertEqual(st.statistic("max") ?? 0, 7.0, "STAT max")
        assertEqual(st.statistic("sumx") ?? 0, 22.0, "STAT Σx")
        assertEqual(st.statistic("sx") ?? 0, 1.743559, accuracy: 1e-5, "STAT population σx")

        let reg = CalculatorEngine()
        reg.activeMode = .stat
        reg.statType = "A+BX"
        reg.statData = [(x: 1, y: 3, freq: 1), (x: 2, y: 5, freq: 1), (x: 3, y: 7, freq: 1)]
        assertEqual(reg.statistic("A") ?? 0, 1.0, "Linear regression A=1")
        assertEqual(reg.statistic("B") ?? 0, 2.0, "Linear regression B=2")
        assertEqual(reg.statistic("r") ?? 0, 1.0, "Linear regression r=1")

        // 47. VECTOR mode: add, dot, magnitude, cross (manual §10)
        let ve = CalculatorEngine()
        ve.vctA = VectorValue([1, 2])
        ve.vctB = VectorValue([3, 4])
        ve.definedVectors = ["VctA", "VctB"]
        ve.insert("VctA+VctB")
        ve.evaluate()
        assertStringEqual(ve.result, "(4,6)", "VctA+VctB = (4,6)")
        if let vec = ve.vectorResult {
            assertEqual(Double(vec.dim), 2.0, "Result of 2D addition stays 2D")
        } else { fatalError("FAIL: vector result should be present") }

        ve.clearAll()
        ve.insert("VctA×VctB")
        ve.evaluate()
        assertTrue(ve.result.contains("−2") || ve.result.contains("-2"),
                   "2D cross product z component should be −2, got \(ve.result)")

        ve.clearAll()
        ve.insert("VctA Dot VctB")
        ve.evaluate()
        assertEqual(Double(ve.result) ?? 0, 11.0, "VctA Dot VctB = 11")

        // The VECTOR menu inserts the Dot( function form
        ve.clearAll()
        ve.insert("Dot(VctA,VctB)")
        ve.evaluate()
        assertEqual(Double(ve.result) ?? 0, 11.0, "Dot(VctA,VctB) = 11")

        ve.clearAll()
        ve.insert("Abs(VctA)")
        ve.evaluate()
        assertEqual(Double(ve.result) ?? 0, Foundation.sqrt(5.0), accuracy: 1e-6, "|VctA| = √5")

        // 48. BASE-N: fixed widths, bit ranges, invalid digits (manual §7)
        assertStringEqual(BaseNFormatter.format(555, base: .hex), "0000022B", "555 in HEX")
        assertStringEqual(BaseNFormatter.format(555, base: .bin), "0000001000101011", "555 in BIN")
        assertStringEqual(BaseNFormatter.format(555, base: .oct), "00000001053", "555 in OCT")
        assertEqual(Double(BaseNFormatter.clamp(40000, base: .bin)), -25536.0, "BIN clamps to 16-bit signed")
        let bn = CalculatorEngine()
        bn.activeMode = .baseN
        bn.baseNType = .bin
        assertTrue(!bn.baseNAllows("2"), "Digit 2 is invalid in BIN")
        bn.baseNType = .hex
        assertTrue(bn.baseNAllows("A"), "A is valid in HEX")
        assertTrue(!bn.baseNAllows("G"), "G is invalid in HEX")

        // 49. TABLE validation (manual §9.5)
        let tv = CalculatorEngine()
        tv.expression = "X^2"
        tv.menuState = .tablePrompt(step: 0)
        tv.advanceTablePrompt()
        tv.advanceTablePrompt(val: 5)
        tv.advanceTablePrompt(val: 1)  // End < Start
        tv.advanceTablePrompt(val: 1)
        assertTrue(tv.isError && tv.result == "Math ERROR", "TABLE End < Start must be Math ERROR")

        let tv2 = CalculatorEngine()
        tv2.expression = "X^2"
        tv2.menuState = .tablePrompt(step: 0)
        tv2.advanceTablePrompt()
        tv2.advanceTablePrompt(val: 0)
        tv2.advanceTablePrompt(val: 1)
        tv2.advanceTablePrompt(val: 0)  // zero step
        assertTrue(tv2.isError, "TABLE zero step must be rejected")

        let tv3 = CalculatorEngine()
        tv3.expression = "X^2"
        tv3.menuState = .tablePrompt(step: 0)
        tv3.advanceTablePrompt()
        tv3.advanceTablePrompt(val: 1)
        tv3.advanceTablePrompt(val: 100)
        tv3.advanceTablePrompt(val: 1)
        assertTrue(tv3.isError, "TABLE more than 30 values must be rejected")

        // 50. SETUP screen 1: MthIO → MathO / LineO (guide §3)
        let su = CalculatorEngine()
        su.menuState = .setupMenu(page: 1)
        su.selectMenuOption(1) // MthIO
        assertTrue(su.menuState == .mthIOMenu, "SETUP 1 opens the MthIO submenu")
        su.selectMenuOption(2) // LineO
        assertStringEqual(su.mathOutputStyle.rawValue, "lineO", "MthIO-LineO selected")
        assertTrue(su.isMthIO, "LineO still uses natural input")
        su.menuState = .setupMenu(page: 1)
        su.selectMenuOption(1)
        su.selectMenuOption(1) // MathO
        assertStringEqual(su.mathOutputStyle.rawValue, "mathO", "MthIO-MathO selected")

        // 51. SETUP angle units and Fix / Sci (guide §5–§9)
        su.menuState = .setupMenu(page: 1)
        su.selectMenuOption(4) // Rad
        assertTrue(su.angleUnit == .rad, "SETUP Rad")
        su.menuState = .setupMenu(page: 1)
        su.selectMenuOption(6) // Fix
        su.selectMenuOption(3) // Fix 3
        if case .fix(let d) = su.displayFormat { assertEqual(Double(d), 3.0, "Fix 3") }
        else { fatalError("FAIL: Fix 3 not applied") }
        su.menuState = .setupMenu(page: 1)
        su.selectMenuOption(7) // Sci
        su.selectMenuOption(0) // Sci 0 = 10 significant digits
        assertTrue(su.formatNumber(1.0 / 7.0).contains("1.428571429"),
                   "Sci 0 should show 10 significant digits, got \(su.formatNumber(1.0 / 7.0))")

        // 52. Norm 1 / Norm 2 thresholds (guide §9, Casio SETUP)
        su.menuState = .setupMenu(page: 1)
        su.selectMenuOption(8) // Norm
        su.selectMenuOption(2) // Norm 2
        assertEqual(Double(su.normMode.rawValue), 2.0, "Norm 2 selected")
        su.displayFormat = .norm
        assertTrue(!su.formatNumber(0.005).contains("×10"),
                   "Norm 2 displays 0.005 without scientific notation")
        su.menuState = .setupMenu(page: 1)
        su.selectMenuOption(8)
        su.selectMenuOption(1) // Norm 1
        assertTrue(su.formatNumber(0.005).contains("×10"),
                   "Norm 1 displays 0.005 in scientific notation")

        // 53. SETUP screen 2: ab/c, d/c, CMPLX, STAT, Disp, CONT
        su.menuState = .setupMenu(page: 2)
        su.selectMenuOption(1) // ab/c
        assertStringEqual(su.fractionDisplay.rawValue, "ab/c", "Fraction display mixed")
        su.menuState = .setupMenu(page: 2)
        su.selectMenuOption(2) // d/c
        assertStringEqual(su.fractionDisplay.rawValue, "d/c", "Fraction display improper")
        su.menuState = .setupMenu(page: 2)
        su.selectMenuOption(4) // STAT
        su.selectMenuOption(1) // ON
        assertTrue(su.statFrequencyEnabled, "STAT FREQ ON")
        su.menuState = .setupMenu(page: 2)
        su.selectMenuOption(5) // Disp
        su.selectMenuOption(2) // Comma
        assertStringEqual(su.decimalPoint.rawValue, ",", "Comma decimal point")
        su.displayFormat = .norm
        assertTrue(su.formatNumber(12.5).contains(","), "Comma decimal point applied to result")
        su.menuState = .setupMenu(page: 2)
        su.selectMenuOption(6) // CONT
        su.selectMenuOption(7)
        assertEqual(Double(su.contrastLevel), 7.0, "Contrast level 7")

        // 54. Reset Setup restores documented defaults (guide §3.7)
        su.menuState = .clrPrompt
        su.selectMenuOption(1)
        assertTrue(su.angleUnit == .deg && su.normMode == .norm1 &&
                   su.fractionDisplay == .improper && su.decimalPoint == .dot &&
                   su.complexFormat == .rectangular && !su.statFrequencyEnabled,
                   "Reset Setup restores all defaults")

        // 55. MATRIX mode also switches to Linear Display (guide §4)
        let matMode = CalculatorEngine()
        matMode.isMthIO = true
        matMode.openModeMenu()
        matMode.selectMenuOption(6)
        assertTrue(!matMode.isMthIO, "Entering MATRIX should force Linear Display")

        // 56. SHIFT+3 (BASE-N) also forces Linear Display (reference §10)
        let baseMode = CalculatorEngine()
        baseMode.isMthIO = true
        baseMode.enterBaseNMode()
        assertTrue(!baseMode.isMthIO, "Entering BASE-N via SHIFT+3 should force Linear Display")

        // 57. Pol / Rec two-argument functions evaluate (reference §4.3)
        let pol = CasioEvaluator.evaluate("Pol(3,4)", angleUnit: .deg)
        assertEqual(pol.value ?? 0, 5.0, accuracy: 1e-6, "Pol(3,4) radius should be 5")
        let rec = CasioEvaluator.evaluate("Rec(5,0)", angleUnit: .deg)
        assertEqual(rec.value ?? 0, 5.0, accuracy: 1e-6, "Rec(5,0) x should be 5")
        let ranInt = CasioEvaluator.evaluate("RanInt#(5,5)", angleUnit: .deg)
        assertEqual(ranInt.value ?? 0, 5.0, accuracy: 1e-6, "RanInt#(5,5) should be 5")

        // 58. Multi-statement intermediate results light the Disp annunciator
        let multi = CalculatorEngine()
        multi.insert("3+3:3×3")
        multi.evaluate()
        assertEqual(multi.lastAnswer, 6.0, accuracy: 1e-6, "First '=' shows first statement")
        assertTrue(multi.isShowingIntermediate, "Disp annunciator after first statement")
        multi.evaluate()
        assertEqual(multi.lastAnswer, 9.0, accuracy: 1e-6, "Second '=' shows final statement")
        assertTrue(!multi.isShowingIntermediate, "Disp clears after final statement")

        // 59. d/dx key inserts a structured derivative template
        let deriv = CalculatorEngine()
        deriv.insertASTDerivative()
        assertStringEqual(deriv.expression, "d/dx(,)", "Derivative template has function and point fields")
        deriv.insertASTText("X²")
        _ = deriv.moveCursorDown()
        deriv.insertASTText("2")
        assertStringEqual(deriv.expression, "d/dx(X²,2)", "Derivative template fields fill correctly")
        let derivResult = CasioEvaluator.evaluate(deriv.expression, angleUnit: .deg)
        assertEqual(derivResult.value ?? 0, 4.0, accuracy: 1e-3, "d/dx(X²)|2 should be 4")

        // 60. SHIFT+DEL (INS) toggles overwrite mode in Linear Display
        let ins = CalculatorEngine()
        ins.isMthIO = false
        ins.insert("123")
        ins.toggleInsertOverwrite()
        assertTrue(ins.isOverwriteMode, "INS should enable overwrite mode")
        ins.moveCursorLeft()
        ins.insert("9")
        assertStringEqual(ins.expression, "129", "Overwrite replaces the character at the cursor")

        // 61. Right arrow walks through every field of a template (visual order)
        var fracNav = MathASTManager()
        fracNav.insertFraction()
        fracNav.insertText("1")
        fracNav.moveRight()
        if case .fractionDenominator = fracNav.cursor.slot {} else {
            fatalError("FAIL: right from numerator should enter denominator")
        }
        fracNav.insertText("2")
        fracNav.moveRight()
        assertTrue(fracNav.cursor.slot == .root, "Right from denominator should exit fraction")

        var intNav = MathASTManager()
        intNav.insertIntegral()
        if case .integralIntegrand = intNav.cursor.slot {} else { fatalError("FAIL: integral starts in integrand") }
        intNav.moveRight()
        if case .integralLower = intNav.cursor.slot {} else { fatalError("FAIL: right → integral lower") }
        intNav.moveRight()
        if case .integralUpper = intNav.cursor.slot {} else { fatalError("FAIL: right → integral upper") }
        intNav.moveRight()
        assertTrue(intNav.cursor.slot == .root, "Right after integral upper should exit")

        var sumNav = MathASTManager()
        sumNav.insertSummation()
        sumNav.moveRight()
        if case .summationLower = sumNav.cursor.slot {} else { fatalError("FAIL: right → summation lower") }
        sumNav.moveRight()
        if case .summationUpper = sumNav.cursor.slot {} else { fatalError("FAIL: right → summation upper") }
        sumNav.moveRight()
        assertTrue(sumNav.cursor.slot == .root, "Right after summation upper should exit")

        var mixNav = MathASTManager()
        mixNav.insertMixedFraction()
        mixNav.moveRight()
        if case .mixedNumerator = mixNav.cursor.slot {} else { fatalError("FAIL: right → mixed numerator") }
        mixNav.moveRight()
        if case .mixedDenominator = mixNav.cursor.slot {} else { fatalError("FAIL: right → mixed denominator") }
        mixNav.moveRight()
        assertTrue(mixNav.cursor.slot == .root, "Right after mixed denominator should exit")

        // 62. Left arrow walks the same fields in reverse
        var revNav = MathASTManager()
        revNav.insertIntegral()
        revNav.moveRight() // lower
        revNav.moveRight() // upper
        revNav.moveLeft()  // lower
        if case .integralLower = revNav.cursor.slot {} else { fatalError("FAIL: left → integral lower") }
        revNav.moveLeft()  // integrand
        if case .integralIntegrand = revNav.cursor.slot {} else { fatalError("FAIL: left → integrand") }

        // 63. Touch-to-cursor: engine moves the 2D cursor to a tapped slot
        let touchEng = CalculatorEngine()
        touchEng.insertASTFraction()
        touchEng.insertASTText("1")
        touchEng.moveCursorRight()
        if case .fractionDenominator(let tappedId) = touchEng.astManager.cursor.slot {
            touchEng.moveCursor(to: CursorPath(slot: .fractionNumerator(tappedId), index: 1))
            if case .fractionNumerator = touchEng.astManager.cursor.slot {} else {
                fatalError("FAIL: tap did not move cursor to numerator")
            }
        } else {
            fatalError("FAIL: expected denominator slot before tap")
        }

        print("All CasioEvaluator tests passed successfully!")
    }
}
