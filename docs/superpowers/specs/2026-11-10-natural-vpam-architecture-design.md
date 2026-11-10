# Casio fx-991ES PLUS Natural-V.P.A.M. Architecture & 2D Math Rendering Specification

## 1. Intent and Why
Transform the calculator into an authentic **Casio fx-991ES PLUS (2nd Edition) NATURAL-V.P.A.M.** emulator, matching the hardware specification and architecture defined in `/home/defy/Downloads/casio_fx_991es_plus_architecture_and_specification.md`.
The key requirement is to replace flat 1D string inputs and outputs with true **Natural-V.P.A.M. (Visually Perfect Algebraic Method)**:
1. Mathematical expressions are input and displayed as 2D textbook math: vertical fractions $\frac{\Box}{\Box}$, elevated exponents $x^{\Box}$, radical bars extending over radicands $\sqrt{\Box}$, integrals $\int_{a}^{b} f(x) dx$, and summations $\sum_{x=a}^{b} f(x)$.
2. Full 2D cursor navigation across sub-blocks and slots using the 4-way REPLAY D-pad (`▲`, `▼`, `◀`, `▶`).
3. Dual display output modes (`MthIO` vs `LineIO`) with exact multi-term symbolic results (e.g. $\frac{\sqrt{2}}{2} + \frac{\sqrt{2}}{3} = \frac{5\sqrt{2}}{6}$, $1 + \sqrt{2}$, $\frac{1 + \sqrt{5}}{2}$, $\frac{3\pi}{4}$) and `S<=>D` toggling between exact natural display and floating-point decimal approximations.

## 2. Approaches Considered

### Approach 1: Native Recursive SwiftUI Math View Hierarchy & 2D AST (Selected)
- **Description**: Model expressions as a typed 2D Abstract Syntax Tree (`MathNode`) containing sub-expression slots (`Slot`). Render both input expressions and output results using modular, lightweight SwiftUI views (`MathNodeView`, `FractionView`, `RadicalView`, `ExponentView`, `IntegralView`) styled to the Casio dot-matrix LCD (`#8B9B7E` / `#07090D`). Implement 2D cursor addressability (`CursorPath`) to enable navigation between slots via the 4-way D-pad. Implement an exact symbolic algebra evaluator that outputs rational numbers, exact surds ($a\sqrt{b}/c$), linear combinations of surds and rationals, and $\pi$ multiples.
- **Why chosen**: Completely native to Swift/SwiftUI, compiles cleanly with `xtool dev build`, gives pixel-perfect Casio typography and LCD proportions, and delivers zero-latency 2D cursor interaction without webview overhead.

### Approach 2: LaTeX / WebKit Canvas Wrapper
- **Description**: Convert expressions to LaTeX and render inside an embedded `WKWebView` or Canvas.
- **Why rejected**: Clunky cursor positioning, high latency, styling does not match the authentic Casio 192×63 dot-matrix LCD aesthetic, and adds unnecessary platform baggage.

## 3. Goals, Non-Goals, and Anti-Goals

### Goals
1. **2D AST Input Buffer**:
   - `MathNode`:
     - `.text(id: UUID, content: String)`: Digits, decimal points, variables ($A, B, C, D, E, F, X, Y, M$), constants ($\pi, e$, $Ans$), operators ($+, -, \times, \div$).
     - `.fraction(id: UUID, num: [MathNode], den: [MathNode])`: Vertical numerator and denominator.
     - `.exponent(id: UUID, base: [MathNode], power: [MathNode])`: Elevated power template.
     - `.radical(id: UUID, index: [MathNode]?, radicand: [MathNode])`: Square root or arbitrary root with overhead horizontal vinculum.
     - `.integral(id: UUID, integrand: [MathNode], lower: [MathNode], upper: [MathNode])`: Definite integral template.
     - `.summation(id: UUID, expr: [MathNode], lower: [MathNode], upper: [MathNode])`: $\Sigma$ template with limits.
     - `.logBase(id: UUID, base: [MathNode], arg: [MathNode])`: Logarithm with arbitrary base.
     - `.parens(id: UUID, children: [MathNode])`: Bracketed grouping.
     - `.function(id: UUID, name: String, arg: [MathNode])`: Named functions like $\sin, \cos, \tan, \ln, \log, \text{abs}$.
2. **2D Cursor Engine**:
   - A `CursorPath` points to a slot in the AST and an index inside that slot.
   - When inside a fraction, `UP` jumps to numerator, `DOWN` jumps to denominator, `RIGHT` from denominator exits the fraction to the right.
   - When inserting `a/b`: if a term precedes the cursor, it populates the numerator and the cursor moves to the denominator; otherwise an empty fraction template $\frac{\Box}{\Box}$ is inserted with cursor in the numerator.
   - `DEL` deletes the token preceding the cursor or removes the template block if empty.
3. **Natural LCD Rendering**:
   - Top line renders the 2D AST with active cursor (`_` or solid block cursor) in the focused slot, displaying empty slots as placeholder squares `□` when unoccupied.
   - Horizontal scrolling if expression exceeds screen width.
4. **Exact Multi-Term Symbolic Output Engine**:
   - `MthIO` mode: exact fractions ($\frac{1}{2}$), exact surds ($\sqrt{2}$, $\frac{5\sqrt{2}}{6}$), multi-term expressions ($1 + \sqrt{2}$, $\frac{1 + \sqrt{5}}{2}$), and $\pi$ terms ($\frac{3\pi}{4}$) rendered in vertical 2D textbook format.
   - `S<=>D` key: toggles between exact 2D natural display and decimal representation ($0.5$, $1.178511302$).
   - Exact persistence: `Ans` and variables ($A\dots F, X, Y, M$) retain exact symbolic representations across calculations.
   - `LineIO` mode: linear formatting for AST and results (`5*√(2)/6 = 1.178511302`).
5. **Casio Precedence & Edge Cases**:
   - Strict implicit multiplication precedence: $1/2\pi = \frac{1}{2\pi}$.
   - Exact simplification of surds and rational arithmetic.
   - Comprehensive error handling: `Math ERROR`, `Syntax ERROR` with `[AC]:Cancel`.
6. **Hardware Keypad Integration**:
   - 3-tier layout:
     - Tier 1: `SHIFT`, `ALPHA`, `REPLAY` 4-way D-Pad, `MODE/SETUP`, `ON`.
     - Tier 2: `CALC`, `∫dx`, `x⁻¹`, `log_ab`, `a/b`, `√`, `x²`, `xʸ`, `log`, `ln`, `(-)`, `° ' "`, `hyp`, `sin`, `cos`, `tan`, `RCL (STO)`, `ENG`, `(`, `)`, `S<=>D`, `M+`.
     - Tier 3: `7, 8, 9, DEL, AC`, `4, 5, 6, ×, ÷`, `1, 2, 3, +, −`, `0, ., ×10ˣ, Ans, =`.

### Non-Goals
- Sound synthesis / audio buzzer for key clicks (haptics remain tactile).
- Hardware flash memory dump emulation.

### Anti-Goals
- Regressing to flat 1D string display.
- Non-standard UI styling that breaks the Casio fx-991ES PLUS physical aesthetic.

## 4. Architectural Details

### 4.1 Layer 1: 2D AST & Navigation Model (`Sources/greeter/MathAST.swift`)
```swift
public enum MathSlotID: Equatable, Hashable, Sendable {
    case root
    case fractionNumerator(UUID)
    case fractionDenominator(UUID)
    case exponentBase(UUID)
    case exponentPower(UUID)
    case radicalRadicand(UUID)
    case radicalIndex(UUID)
    case integralIntegrand(UUID)
    case integralLower(UUID)
    case integralUpper(UUID)
    case summationExpr(UUID)
    case summationLower(UUID)
    case summationUpper(UUID)
    case logBase(UUID)
    case logArg(UUID)
    case parens(UUID)
    case functionArg(UUID)
}

public indirect enum MathNode: Identifiable, Equatable, Sendable {
    case text(id: UUID, content: String)
    case fraction(id: UUID, num: [MathNode], den: [MathNode])
    case exponent(id: UUID, base: [MathNode], power: [MathNode])
    case radical(id: UUID, index: [MathNode]?, radicand: [MathNode])
    case integral(id: UUID, integrand: [MathNode], lower: [MathNode], upper: [MathNode])
    case summation(id: UUID, expr: [MathNode], lower: [MathNode], upper: [MathNode])
    case logBase(id: UUID, base: [MathNode], arg: [MathNode])
    case parens(id: UUID, children: [MathNode])
    case function(id: UUID, name: String, arg: [MathNode])
}
```

### 4.2 Layer 2: 2D Cursor Manager
- `cursorSlot: MathSlotID` and `cursorIndex: Int`.
- Navigation methods:
  - `moveLeft()`, `moveRight()`: In-order traversal across nodes and into/out of template slots.
  - `moveUp()`, `moveDown()`: Context-aware vertical jump:
    - Fraction: between numerator and denominator.
    - Integral/Summation: between integrand, lower bound, and upper bound.
    - Exponent: between base line and exponent.
- Insertion methods:
  - `insertText(_ text: String)`: Appends digit or operator at `cursorIndex`.
  - `insertFraction()`: If previous node exists, wraps it as numerator; places cursor in denominator. Otherwise creates empty $\frac{\Box}{\Box}$ template.
  - `insertRadical()`, `insertExponent()`, `insertIntegral()`, `insertSummation()`, `insertLogBase()`.
  - `delete()`: Removes character or collapses empty template.

### 4.3 Layer 3: Natural SwiftUI Renderers (`Sources/greeter/MathViews.swift`)
- `MathASTView`: Renders node list horizontally with proper baseline alignments.
- `FractionView`:
  - `VStack(spacing: 1.5)` containing numerator view, a horizontal bar `Rectangle().fill(CasioTheme.lcdTextActive).frame(height: 1.5)`, and denominator view.
- `RadicalView`:
  - Custom path drawing the Casio $\sqrt{}$ symbol and an overhead bounding line spanning the width of the radicand content.
- `ExponentView`:
  - `HStack(alignment: .top, spacing: 1)` with base view and superscript view scaled down to font size 10 and elevated.
- `IntegralView`:
  - Integral symbol $\int$ with upper bound stacked above lower bound and integrand in between.
- Cursor indicator: A 2-pixel wide blinking bar or inverted block rendered at `cursorIndex` within the active slot. Unoccupied slots show a light dashed square `□`.
- Output rendering: In `MthIO` mode, an exact `ExactResult` enum is rendered with `MathASTView`:
  - Rational fraction $\frac{p}{q}$
  - Surd $\frac{a\sqrt{b}}{c}$ or $a\sqrt{b}$
  - Multi-term compound surds (e.g., $1 + \sqrt{2}$, $\frac{a + b\sqrt{d}}{c}$)
  - Multiples of $\pi$: e.g. $\frac{a\pi}{b}$
  - Complex rectangular $a + bi$ or polar $r\angle\theta$
  - Floating decimal approximation when toggled via `S<=>D`.

### 4.4 Layer 4: Execution Engine & Evaluator (`Sources/greeter/Calculator.swift`)
- Evaluator converts `[MathNode]` AST into evaluatable mathematical expressions:
  - Evaluates integrals using adaptive Simpson's rule.
  - Evaluates summations numerically.
  - Exact surd and fraction arithmetic:
    - Fractions: addition, subtraction, multiplication, division with GCD reduction.
    - Surds: square-free reduction, like-radical addition/subtraction (e.g. $\frac{\sqrt{2}}{2} + \frac{\sqrt{2}}{3} = \frac{5\sqrt{2}}{6}$).
    - Linear combinations: handles multi-term expressions ($a_0 + \sum a_i \sqrt{d_i}$).
    - Trigonometry in exact form where standard special angles ($30^\circ, 45^\circ, 60^\circ$) yield exact fractions/radicals ($\sin(30^\circ) = 1/2$, $\sin(45^\circ) = \sqrt{2}/2$, $\cos(30^\circ) = \sqrt{3}/2$).
  - Full variable persistence: $A, B, C, D, E, F, X, Y, M, Ans$ retain exact symbolic representations.
  - Modes: COMP, CMPLX, STAT, BASE-N, EQN, MATRIX, TABLE, VECTOR.

## 5. Verification Plan
1. Unit tests in `Tests/CasioEvaluatorTests.swift`:
   - 2D AST building and slot navigation (inserting into numerator, jumping to denominator, exiting).
   - Exact surd & fraction evaluation ($\frac{\sqrt{2}}{2} + \frac{\sqrt{2}}{3} = \frac{5\sqrt{2}}{6}$, $\frac{1}{2} + \frac{1}{3} = \frac{5}{6}$, $\sin(30^\circ) = \frac{1}{2}$, $\sqrt{18} = 3\sqrt{2}$).
   - `S<=>D` toggling between exact natural display and decimal representation.
   - Integral and summation evaluations ($\int_0^1 x^2 dx = 1/3$, $\sum_{x=1}^5 x = 15$).
   - Implicit multiplication precedence ($1/2\pi$).
2. Cross-platform build check:
   - `xtool dev build` completes with exit code 0 and generates `xtool/greeter.app`.
