# Casio fx-991ES PLUS Natural-V.P.A.M. Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the calculator into an authentic Casio fx-991ES PLUS (2nd Edition) with full Natural-V.P.A.M. 2D math input and rendering, 4-way D-pad navigation across sub-blocks, exact multi-term symbolic calculation ($\frac{5\sqrt{2}}{6}$, $\frac{1}{2}$, $\pi$), and dual MthIO/LineIO display output.

**Architecture:** A 2D Abstract Syntax Tree (`MathNode`) with slot-based cursor addressability (`CursorPath`) rendered recursively in SwiftUI (`MathASTView`, `FractionNodeView`, `RadicalNodeView`, `ExponentNodeView`), evaluated by an exact symbolic engine (`ExactValue`) with fallback to numerical algorithms (Simpson's rule integration, Newton-Raphson), housed in the authentic Casio 3-tier hardware shell.

**Tech Stack:** Swift 6, SwiftUI, cross-compiled for iOS using `xtool dev build`.

**Spec:** docs/superpowers/specs/2026-11-10-natural-vpam-architecture-design.md

## Global Constraints
- Target platform: iOS via `xtool` (`xtool dev build`).
- Build command must complete cleanly with exit code 0 (`xtool dev build`).
- Tests must pass via `swift Sources/greeter/*.swift Tests/CasioEvaluatorTests.swift`.
- Exact surds ($\sqrt{2}$, $\frac{5\sqrt{2}}{6}$), fractions ($\frac{1}{2}$), and $\pi$ multiples must render as 2D natural textbook math on the LCD.
- Strict implicit multiplication precedence: $1 / 2\pi = \frac{1}{2\pi}$.

## Review Focus
1. Cursor navigation into and out of nested 2D structures (e.g., numerator $\to$ denominator $\to$ exit fraction) without getting stuck or crashing.
2. Deleting tokens and templates (`DEL`) at slot boundaries without indexing crashes.
3. Exact symbolic evaluation and simplification: $\frac{\sqrt{2}}{2} + \frac{\sqrt{2}}{3} \to \frac{5\sqrt{2}}{6}$ and $\sqrt{18} \to 3\sqrt{2}$.
4. Toggling `S<=>D` between exact 2D natural fraction/surd/pi output and floating-point decimal representation.
5. Mathematical error handling (`Math ERROR`, `Syntax ERROR`) cleanly handled on division by zero, domain errors, and malformed empty slots.

---

### Task 1: 2D Math AST and Cursor Navigation Engine

**Files:**
- Create: `Sources/greeter/MathAST.swift`
- Test: `Tests/CasioEvaluatorTests.swift`

**Interfaces:**
- Produces:
  - `enum MathSlotID: Equatable, Hashable, Sendable`
  - `indirect enum MathNode: Identifiable, Equatable, Sendable`
  - `struct CursorPath: Equatable, Sendable`
  - `struct MathASTManager: Sendable`
    - `var root: [MathNode]`
    - `var cursor: CursorPath`
    - `mutating func insertText(_ text: String)`
    - `mutating func insertFraction()`
    - `mutating func insertRadical()`
    - `mutating func insertExponent()`
    - `mutating func insertIntegral()`
    - `mutating func insertSummation()`
    - `mutating func insertLogBase()`
    - `mutating func delete()`
    - `mutating func moveLeft()`
    - `mutating func moveRight()`
    - `mutating func moveUp()`
    - `mutating func moveDown()`
    - `func toLinearString() -> String`

- [ ] **Step 1: Write unit tests for 2D AST insertion, deletion, and cursor navigation**

```swift
// In Tests/CasioEvaluatorTests.swift:
var mgr = MathASTManager()
mgr.insertText("2")
mgr.insertFraction()
// Cursor should now be in the denominator of the fraction whose numerator has "2"
assertTrue(mgr.cursor.slot != .root, "Cursor should be inside fraction denominator")
mgr.insertText("3")
mgr.moveRight() // Exit fraction
mgr.insertText("+")
mgr.insertRadical()
mgr.insertText("2")
let linear = mgr.toLinearString()
assertStringEqual(linear, "(2)/(3)+√(2)")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift Sources/greeter/*.swift Tests/CasioEvaluatorTests.swift`
Expected: Compilation failure due to missing `MathASTManager` and `MathNode`.

- [ ] **Step 3: Implement `MathAST.swift`**

Implement `MathNode`, `MathSlotID`, `CursorPath`, and `MathASTManager` supporting in-order traversal, template wrapping of previous terms, and 4-way vertical/horizontal navigation.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift Sources/greeter/*.swift Tests/CasioEvaluatorTests.swift`
Expected: PASS with 0 exit code.

- [ ] **Step 5: Commit**

```bash
git add Sources/greeter/MathAST.swift Tests/CasioEvaluatorTests.swift
git commit -m "feat: 2D Math AST data structures and 2D cursor navigation engine"
```

---

### Task 2: Exact Multi-Term Symbolic Engine

**Files:**
- Create: `Sources/greeter/ExactMath.swift`
- Test: `Tests/CasioEvaluatorTests.swift`

**Interfaces:**
- Produces:
  - `struct Rational: Equatable, Comparable, Hashable, CustomStringConvertible, Sendable`
    - `var num: Int64`
    - `var den: Int64`
    - `static func + (lhs: Rational, rhs: Rational) -> Rational`
    - `static func - (lhs: Rational, rhs: Rational) -> Rational`
    - `static func * (lhs: Rational, rhs: Rational) -> Rational`
    - `static func / (lhs: Rational, rhs: Rational) -> Rational?`
  - `struct ExactValue: Equatable, Sendable`
    - `var surdTerms: [Int64: Rational]` // radicand -> coefficient (radicand 1 is rational)
    - `var piCoeff: Rational` // multiple of pi
    - `var isZero: Bool`
    - `func toDouble() -> Double`
    - `func toMathNodes() -> [MathNode]`
    - `func toLinearString() -> String`
    - `static func rational(_ r: Rational) -> ExactValue`
    - `static func surd(coeff: Rational = Rational(1, 1), radicand: Int64) -> ExactValue`
    - `static func piMultiple(_ r: Rational) -> ExactValue`
    - `static func + (lhs: ExactValue, rhs: ExactValue) -> ExactValue`
    - `static func - (lhs: ExactValue, rhs: ExactValue) -> ExactValue`
    - `static func * (lhs: ExactValue, rhs: ExactValue) -> ExactValue`
    - `static func / (lhs: ExactValue, rhs: ExactValue) -> ExactValue?`

- [ ] **Step 1: Write tests for ExactValue arithmetic and radical simplification**

```swift
// Test sqrt(18) = 3*sqrt(2)
let s18 = ExactValue.surd(radicand: 18)
assertEqual(s18.toDouble(), Foundation.sqrt(18.0))
// Test sqrt(2)/2 + sqrt(2)/3 = 5*sqrt(2)/6
let halfSqrt2 = ExactValue.surd(coeff: Rational(1, 2), radicand: 2)
let thirdSqrt2 = ExactValue.surd(coeff: Rational(1, 3), radicand: 2)
let sumSurd = halfSqrt2 + thirdSqrt2
let nodes = sumSurd.toMathNodes()
// nodes should represent fraction with (5*√(2))/(6)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift Sources/greeter/*.swift Tests/CasioEvaluatorTests.swift`
Expected: Compilation failure due to missing `Rational` and `ExactValue`.

- [ ] **Step 3: Implement `ExactMath.swift`**

Implement `Rational` with GCD reduction, square-free reduction for radicals, and `ExactValue` arithmetic supporting multi-term combinations ($a_0 + \sum a_i\sqrt{d_i} + c\pi$).

- [ ] **Step 4: Run test to verify it passes**

Run: `swift Sources/greeter/*.swift Tests/CasioEvaluatorTests.swift`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/greeter/ExactMath.swift Tests/CasioEvaluatorTests.swift
git commit -m "feat: exact multi-term symbolic algebra engine"
```

---

### Task 3: 2D AST Mathematical LCD Renderer

**Files:**
- Create: `Sources/greeter/MathViews.swift`
- Test: `xtool dev build`

**Interfaces:**
- Consumes: `MathNode`, `CursorPath`, `CasioTheme`
- Produces:
  - `struct MathASTView: View`: Recursively renders `[MathNode]` with baseline alignment, active blinking cursor in the focused slot, and placeholder squares for empty slots.
  - `struct FractionNodeView: View`: Stacks numerator and denominator with horizontal line.
  - `struct RadicalNodeView: View`: Draws radical hook and extended vinculum bar.
  - `struct ExponentNodeView: View`: Elevated base + power.
  - `struct IntegralNodeView: View`: Integral glyph with upper/lower limits.
  - `struct SummationNodeView: View`: $\Sigma$ glyph with upper/lower limits.

- [ ] **Step 1: Implement `MathViews.swift`**

Build the recursive SwiftUI view hierarchy matching the Casio fx-991ES PLUS LCD style (`CasioTheme.lcdTextActive`, `#07090D`).

- [ ] **Step 2: Verify `MathViews.swift` compiles with `xtool dev build`**

Run: `xtool dev build`
Expected: Exit code 0.

- [ ] **Step 3: Commit**

```bash
git add Sources/greeter/MathViews.swift
git commit -m "feat: natural 2D math SwiftUI renderers for LCD screen"
```

---

### Task 4: Connect 2D AST & Exact Evaluator to CalculatorEngine

**Files:**
- Modify: `Sources/greeter/Calculator.swift`
- Test: `Tests/CasioEvaluatorTests.swift`

**Interfaces:**
- Connects `MathASTManager` and `ExactValue` into `CalculatorEngine`:
  - `var astManager: MathASTManager`
  - `var exactResult: ExactValue?`
  - `var isShowingDecimal: Bool` (toggled by `S<=>D`)
  - `func handleKey(_ key: String)`
  - Exact persistence for variables and `Ans`.
  - Implicit multiplication with higher precedence: $1/2\pi \to \frac{1}{2\pi}$.

- [ ] **Step 1: Write integration tests in `Tests/CasioEvaluatorTests.swift`**

Test end-to-end evaluation of AST expressions:
`√(2)/2 + √(2)/3`, `1/2 + 1/3`, `sin(30)`, `1/2π`, and `S<=>D` toggle.

- [ ] **Step 2: Run tests to verify failure**

Run: `swift Sources/greeter/*.swift Tests/CasioEvaluatorTests.swift`
Expected: FAIL.

- [ ] **Step 3: Update `CalculatorEngine` in `Calculator.swift`**

Wire AST manager to evaluation, exact symbolic representation, and variable persistence.

- [ ] **Step 4: Run tests to verify pass**

Run: `swift Sources/greeter/*.swift Tests/CasioEvaluatorTests.swift`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/greeter/Calculator.swift Tests/CasioEvaluatorTests.swift
git commit -m "feat: integrate 2D AST evaluator and exact result persistence in CalculatorEngine"
```

---

### Task 5: Update LCD and Keypad in ContentView & Full System Verification

**Files:**
- Modify: `Sources/greeter/ContentView.swift`
- Test: `xtool dev build`

**Interfaces:**
- Consumes: `MathASTView`, `CalculatorEngine`, `MathASTManager`
- Updates:
  - `casioScreen`: Renders expression line using `MathASTView` in `MthIO` mode (or linear string in `LineIO`).
  - Result line: Renders exact 2D `MathASTView` for fractions/surds or large formatted text for decimals.
  - Wire Replay D-pad (`▲`, `▼`, `◀`, `▶`) to 4-way AST navigation.
  - Wire function keys (`a/b`, `√`, `xʸ`, `log_ab`, `∫dx`, `Σ`, `d/dx`) to insert structured 2D AST nodes.
  - Wire `S<=>D` to toggle between natural exact display and decimal representation.

- [ ] **Step 1: Update `ContentView.swift` to render 2D AST and connect all keys**

- [ ] **Step 2: Verify `xtool dev build`**

Run: `xtool dev build`
Expected: Build complete! (0 errors)

- [ ] **Step 3: Run complete test suite**

Run: `swift Sources/greeter/*.swift Tests/CasioEvaluatorTests.swift`
Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
git add Sources/greeter/ContentView.swift
git commit -m "feat: Casio LCD 2D natural math rendering and full keypad wiring"
```
