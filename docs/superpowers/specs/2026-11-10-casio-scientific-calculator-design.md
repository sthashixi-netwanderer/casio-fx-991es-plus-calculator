# Casio fx-991ES PLUS (2nd Edition) Scientific Calculator Redesign

## Intent and Why
Transform the current generic calculator into an authentic **Casio fx-991ES PLUS (2nd edition) NATURAL-V.P.A.M.** scientific calculator. The goal is to deliver:
1. Natural mathematical expression entry (formulas appear on the top LCD line, evaluated algebraically on pressing `=`).
2. Classic Casio hardware chassis, solar cell, branding badges, dual-line LCD display with status annunciators (`S`, `A`, `M`, `D`/`R`/`G`, `Math`), and tactile button aesthetic (lime green `DEL`/`AC`, silver Replay D-pad, yellow `SHIFT` and red `ALPHA` secondary functions).
3. Full Casio `MODE` and `SETUP` menus (Deg/Rad/Gra, Fix/Sci/Norm, MthIO/LineIO).

## Approaches Considered
1. **Full Natural Expression Engine + Casio Shell (Selected)**:
   - *Description*: Users type standard mathematical formulas into the top dot-matrix display line (e.g. `sin(30)+5×2`, `√(16)×3`). Pressing `=` parses and evaluates the expression respecting algebraic precedence, parentheses, and active angle unit (`Deg`, `Rad`, `Gra`), rendering the result on the bottom-right line.
   - *Why chosen*: Matches user requirement ("1"), providing the true authentic Casio scientific calculator behavior.
2. **Immediate Execution Shell**:
   - Immediate execution postfix calculations without formula buffering. Superseded by Option 1.

## Goals, Non-Goals, and Anti-Goals
- **Goals**:
  - Expression-based calculation: Input tokens append to the expression buffer on the top line with an active cursor (`_`). Pressing `=` computes the mathematical value and displays it on the bottom line. Supports `+`, `−`, `×`, `÷`, powers (`^`, `x²`, `x³`), square root (`√`), trig functions (`sin`, `cos`, `tan`, `sin⁻¹`, `cos⁻¹`, `tan⁻¹`), logarithmic functions (`log`, `ln`, `10^x`, `e^x`), percentages, parentheses `(`, `)`, constants (`π`, `e`), and `Ans`.
  - Replay navigation: Left `◀` and Right `▶` cursor controls on the Replay D-pad to navigate and edit the expression.
  - Authentic Casio chassis: dark matte housing (`#18191B`), white "CASIO" logo, "fx-991ES PLUS" metallic badge, "NATURAL-V.P.A.M." 2nd edition insignia, and photovoltaic solar cell grid simulation.
  - Dual-line LCD screen (`#8B9B7E`) with top dot-matrix formula line, large bottom 7-segment/digit line, and annunciator flags (`S`, `A`, `M`, `D`, `R`, `G`, `Fix`, `Sci`, `Math`).
  - Keypad layout:
    - Control tier: `SHIFT` (yellow), `ALPHA` (magenta), circular Replay D-pad (`▲`, `▼`, `◀`, `▶`), `MODE SETUP`, `ON`.
    - Function tiers (3 rows × 6 columns): `x⁻¹`, `log_a b`, `■/□`, `√`, `x²`, `x^■`, `log`, `ln`, `(-)`, `° ' "`, `hyp`, `sin`, `cos`, `tan`, `RCL (STO)`, `ENG`, `(`, `)`, `S<=>D`, `M+`.
    - Main pad (4 rows × 5 columns): Digits 0-9, `.`, `×10^x`, `Ans`, `=`, `+`, `−`, `×`, `÷`, with lime green `DEL` and `AC`.
  - Functional `SHIFT` and `ALPHA` modifiers:
    - Activating `SHIFT` lights `S` annunciator; next key triggers yellow secondary function.
    - Activating `ALPHA` lights `A` annunciator; next key triggers pink/red function.
  - Interactive `MODE` & `SETUP` menus:
    - `MODE`: `1: COMP`, `2: STAT`, `3: TABLE`, `4: EQN`.
    - `SHIFT + MODE` (`SETUP`): `1: MthIO`, `2: LineIO`, `3: Deg`, `4: Rad`, `5: Gra`, `6: Fix`, `7: Sci`, `8: Norm`.
    - Angle modes immediately update active trig math and annunciator (`D`, `R`, or `G`).
    - Decimal formatting supports Fix (0–9 decimal places) and Sci (significant digits).
  - Authentic Casio error handling: `Math ERROR` with `[AC] : Cancel`.
- **Non-Goals**:
  - Full multi-variable matrix/vector solvers beyond mode state display.
- **Anti-Goals**:
  - Generic mobile calculator look.
  - Compilation failures under `xtool dev build`.

## Architecture & Components
1. **`CalculatorEngine` (`Sources/greeter/Calculator.swift`)**:
   - `expression: String`: Current formula input buffer.
   - `cursorPosition: Int`: Index within expression for cursor rendering and editing.
   - `resultDisplay: String`: Lower display string for calculation results or error messages.
   - `angleUnit: AngleUnit` (`.deg`, `.rad`, `.gra`): Controls trig functions.
   - `displayFormat: DisplayFormat` (`.norm`, `.fix(Int)`, `.sci(Int)`).
   - `activeMode: CalcMode` (`.comp`, `.stat`, `.table`, `.eqn`).
   - `menuState: MenuState` (`.none`, `.mode`, `.setup`).
   - Expression evaluation: Infix tokenizer & Shunting-Yard evaluator with operator precedence:
     - Functions: `sin`, `cos`, `tan`, `asin`, `acos`, `atan`, `ln`, `log`, `sqrt`, `abs`.
     - Operators: `+`, `-`, `×`, `÷`, `^`, `!`.
     - Parentheses: `(`, `)`.
     - Constants: `π`, `e`, `Ans`.
2. **`ContentView` (`Sources/greeter/ContentView.swift`)**:
   - Authentic Casio shell layout with LCD display and responsive keypad matrix.
