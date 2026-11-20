import Foundation

// MARK: - SETUP preferences (SHIFT + MODE, guide §1–§9)

/// Natural-result style when MthIO input is selected (guide §3.2–§3.4).
public enum MathOutputStyle: String, Sendable {
    case mathO
    case lineO
}

/// Exponential display range for the Norm number format (guide §9, Casio SETUP).
public enum NormMode: Int, Sendable {
    case norm1 = 1   // scientific when |x| < 1e-2 or |x| >= 1e10
    case norm2 = 2   // scientific when |x| < 1e-9 or |x| >= 1e10

    var lowerThreshold: Double { self == .norm1 ? 1e-2 : 1e-9 }
}

/// Decimal-point punctuation for displayed results (Casio SETUP page 2 → Disp).
public enum DecimalPoint: String, Sendable {
    case dot = "."
    case comma = ","
}

/// Fraction result format (SETUP page 2 → ab/c vs d/c).
public enum FractionDisplay: String, Sendable {
    case mixed = "ab/c"
    case improper = "d/c"
}

// MARK: - Engine SETUP handling

extension CalculatorEngine {
    /// Handle a numbered selection while any SETUP-related menu is open.
    /// Returns true when the selection was consumed by SETUP.
    @discardableResult
    public func handleSetupSelection(_ number: Int) -> Bool {
        switch menuState {
        case .setupMenu(let page):
            if page == 1 {
                switch number {
                case 1:
                    isMthIO = true
                    menuState = .mthIOMenu
                case 2:
                    isMthIO = false
                    menuState = .none
                case 3: angleUnit = .deg; menuState = .none
                case 4: angleUnit = .rad; menuState = .none
                case 5: angleUnit = .gra; menuState = .none
                case 6: menuState = .fixPrompt
                case 7: menuState = .sciPrompt
                case 8: menuState = .normPrompt
                default: break
                }
            } else {
                switch number {
                case 1:
                    fractionDisplay = .mixed
                    menuState = .none
                case 2:
                    fractionDisplay = .improper
                    menuState = .none
                case 3: menuState = .cmplxFormatMenu
                case 4: menuState = .statFreqMenu
                case 5: menuState = .dispFormatMenu
                case 6: menuState = .contrastPrompt
                default: break
                }
            }

        case .mthIOMenu:
            // 1: MathO (natural result), 2: LineO (linear result)
            mathOutputStyle = number == 2 ? .lineO : .mathO
            menuState = .none

        case .fixPrompt:
            let d = min(max(0, number), 9)
            displayFormat = .fix(d)
            menuState = .none
            refreshDisplayedNumber()

        case .sciPrompt:
            let d = min(max(0, number), 9)
            displayFormat = .sci(d)
            menuState = .none
            refreshDisplayedNumber()

        case .normPrompt:
            normMode = number == 2 ? .norm2 : .norm1
            if case .fix = displayFormat {} else if case .sci = displayFormat {} else {
                displayFormat = .norm
            }
            menuState = .none
            refreshDisplayedNumber()

        case .cmplxFormatMenu:
            complexFormat = number == 2 ? .polar : .rectangular
            menuState = .none
            refreshComplexResultDisplay()

        case .statFreqMenu:
            statFrequencyEnabled = number == 1   // 1: ON, 2: OFF
            menuState = .none

        case .dispFormatMenu:
            decimalPoint = number == 2 ? .comma : .dot
            menuState = .none
            refreshDisplayedNumber()

        case .contrastPrompt:
            contrastLevel = min(max(0, number), 9)
            menuState = .none

        default:
            return false
        }
        return true
    }

    /// Reformat the currently displayed numeric result after a display setting
    /// changes (does not re-evaluate the expression).
    public func refreshDisplayedNumber() {
        guard isShowingResult, !isError, !isShowingComplexResult,
              let value = Double(result.replacingOccurrences(of: "×10^", with: "e")),
              matrixResult == nil, vectorResult == nil else { return }
        result = formatNumber(value)
    }

    /// Format a number using all active SETUP preferences.
    public func formatNumber(_ val: Double) -> String {
        let text = formattedValue(val)
        return decimalPoint == .comma ? text.replacingOccurrences(of: ".", with: ",") : text
    }

    private func formattedValue(_ val: Double) -> String {
        if !val.isFinite { return "Math ERROR" }
        if val == 0 { return "0" }
        switch displayFormat {
        case .fix(let d):
            return String(format: "%.\(d)f", val)
        case .sci(let d):
            // Casio Sci 0 means ten significant digits (guide §9.3).
            let digits = d == 0 ? 10 : d
            return String(format: "%.\(digits - 1)e", val)
        case .eng:
            return CasioEvaluator.formatEng(val, level: engLevel)
        case .fraction, .mixedFraction, .norm:
            let mag = abs(val)
            let useScientific = mag >= 1e10 || mag < normMode.lowerThreshold
            if useScientific {
                // Casio uses 10 significant digits in scientific form.
                return scientific(val)
            }
            return String(format: "%.10g", val)
        }
    }

    /// Scientific notation with a proper ×10^ exponent, like the calculator LCD.
    private func scientific(_ val: Double) -> String {
        if val == 0 { return "0" }
        let exp = Int(floor(log10(abs(val))))
        let mantissa = val / pow(10.0, Double(exp))
        var m = String(format: "%.9g", mantissa)
        if m.contains(".") { m = m.replacingOccurrences(of: "0+$", with: "", options: .regularExpression) }
        if m.hasSuffix(".") { m.removeLast() }
        return "\(m)×10^\(exp)"
    }

    /// Restore every SETUP preference to Casio's documented defaults
    /// (guide §1, §4: MthIO-MathO, Deg, Norm 1, d/c, a+bi, FREQ off, Dot).
    public func applySetupDefaults() {
        isMthIO = true
        mathOutputStyle = .mathO
        angleUnit = .deg
        displayFormat = .norm
        normMode = .norm1
        fractionDisplay = .improper
        complexFormat = .rectangular
        statFrequencyEnabled = false
        decimalPoint = .dot
        contrastLevel = 3
    }
}
