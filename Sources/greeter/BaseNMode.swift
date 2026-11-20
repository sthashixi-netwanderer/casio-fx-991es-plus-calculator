import Foundation

// MARK: - BASE-N mode (manual §7)

public enum BaseNFormatter {
    /// Fixed display widths used by the fx-991ES PLUS (manual §7.6).
    public static func width(for base: BaseNType) -> Int {
        switch base {
        case .bin: return 16
        case .oct: return 11
        case .hex: return 8
        case .dec: return 0
        }
    }

    public static func format(_ val: Int32, base: BaseNType) -> String {
        switch base {
        case .dec:
            return "\(val)"
        case .hex:
            let s = String(UInt32(bitPattern: val), radix: 16, uppercase: true)
            return String(repeating: "0", count: max(0, 8 - s.count)) + s
        case .bin:
            let s = String(UInt32(bitPattern: val), radix: 2)
            return String(repeating: "0", count: max(0, 16 - s.count)) + s
        case .oct:
            let s = String(UInt32(bitPattern: val), radix: 8)
            return String(repeating: "0", count: max(0, 11 - s.count)) + s
        }
    }

    /// BIN uses a 16-bit range; DEC/OCT/HEX use 32-bit (manual §7.9).
    public static func clamp(_ value: Double, base: BaseNType) -> Int32 {
        if base == .bin {
            let v = Int(value)
            let wrapped = ((v + 32768) % 65536 + 65536) % 65536 - 32768
            return Int32(wrapped)
        }
        return Int32(truncatingIfNeeded: Int64(value))
    }

    /// Reject digits that do not exist in the selected base (manual §7.9).
    public static func isValidDigit(_ c: Character, base: BaseNType) -> Bool {
        guard let s = c.wholeNumberValue, c.isNumber else {
            return base == .hex && "ABCDEFabcdef".contains(c)
        }
        switch base {
        case .bin: return s == 0 || s == 1
        case .oct: return s >= 0 && s <= 7
        case .dec, .hex: return s >= 0 && s <= 9
        }
    }
}

extension CalculatorEngine {
    /// Evaluate the current BASE-N expression, then convert to the selected base.
    public func evaluateBaseN() {
        let eval = CasioEvaluator.evaluate(expression, angleUnit: .deg, variables: [:], lastAnswer: lastAnswer)
        if let err = eval.error {
            isError = true
            result = err
            return
        }
        guard let val = eval.value else {
            isError = true
            result = "Syntax ERROR"
            return
        }
        let intVal = BaseNFormatter.clamp(val, base: baseNType)
        lastAnswer = Double(intVal)
        isError = false
        result = BaseNFormatter.format(intVal, base: baseNType)
    }

    public func formatBaseN(_ val: Int32, base: BaseNType) -> String {
        BaseNFormatter.format(val, base: base)
    }

    public func setBaseN(_ base: BaseNType) {
        baseNType = base
        if !isError, lastAnswer.isFinite {
            let intVal = BaseNFormatter.clamp(lastAnswer, base: base)
            result = BaseNFormatter.format(intVal, base: base)
        }
    }

    /// Whether a key's text may be inserted in the current base.
    public func baseNAllows(_ text: String) -> Bool {
        guard activeMode == .baseN else { return true }
        return text.allSatisfy { BaseNFormatter.isValidDigit($0, base: baseNType) || "+-×÷() ".contains($0) }
    }
}
