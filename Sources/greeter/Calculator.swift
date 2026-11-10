import Foundation

/// Immediate-execution scientific calculator engine.
final class CalculatorEngine: ObservableObject {
    @Published var display = "0"
    @Published var radiansMode = false
    @Published var preview = ""

    private struct PendingBinary {
        let symbol: String
        let operate: (Double, Double) -> Double
        let lhs: Double
    }

    private var currentValue: Double?
    private var pending: PendingBinary?
    private var inputBuffer = ""
    private var isEnteringNumber = false

    // MARK: - Input

    func digit(_ d: String) {
        if !isEnteringNumber {
            inputBuffer = d == "." ? "0." : d
            isEnteringNumber = true
        } else if d == "." {
            guard !inputBuffer.contains(".") else { return }
            inputBuffer += "."
        } else {
            guard inputBuffer.replacingOccurrences(of: "-", with: "").count < 15 else { return }
            inputBuffer += d
        }
        display = inputBuffer
    }

    func clearAll() {
        display = "0"
        preview = ""
        currentValue = nil
        pending = nil
        inputBuffer = ""
        isEnteringNumber = false
    }

    func negate() {
        if isEnteringNumber {
            inputBuffer = inputBuffer.hasPrefix("-") ? String(inputBuffer.dropFirst()) : "-" + inputBuffer
            display = inputBuffer
        } else if let v = currentValue, v.isFinite {
            currentValue = -v
            display = format(-v)
        }
    }

    func percent() {
        let v = commitInput()
        currentValue = v / 100
        display = format(v / 100)
        isEnteringNumber = false
    }

    // MARK: - Binary operations

    func setBinary(_ symbol: String, _ operate: @escaping (Double, Double) -> Double) {
        let v = commitInput()
        if let p = pending {
            let r = p.operate(p.lhs, v)
            guard r.isFinite else { fail(); return }
            currentValue = r
            display = format(r)
            preview = "\(format(r)) \(symbol)"
        } else {
            currentValue = v
            preview = "\(format(v)) \(symbol)"
        }
        pending = PendingBinary(symbol: symbol, operate: operate, lhs: currentValue ?? 0)
        isEnteringNumber = false
    }

    func equals() {
        let v = commitInput()
        guard let p = pending else {
            if let c = currentValue { display = format(c) }
            preview = ""
            return
        }
        let r = p.operate(p.lhs, v)
        guard r.isFinite else { fail(); return }
        currentValue = r
        pending = nil
        preview = ""
        display = format(r)
        isEnteringNumber = false
    }

    // MARK: - Unary functions & constants

    func applyUnary(_ f: (Double) -> Double) {
        let v = commitInput()
        let r = f(v)
        guard r.isFinite else { fail(); return }
        currentValue = r
        display = format(r)
        isEnteringNumber = false
    }

    func setConstant(_ value: Double) {
        currentValue = value
        display = format(value)
        isEnteringNumber = false
    }

    func toggleAngleMode() {
        radiansMode.toggle()
    }

    // MARK: - Helpers

    private func commitInput() -> Double {
        if isEnteringNumber {
            let v = Double(inputBuffer) ?? 0
            isEnteringNumber = false
            currentValue = v
            return v
        }
        return currentValue ?? 0
    }

    private func fail() {
        currentValue = nil
        pending = nil
        inputBuffer = ""
        isEnteringNumber = false
        preview = ""
        display = "Error"
    }

    func format(_ v: Double) -> String {
        guard v.isFinite else { return "Error" }
        if v == 0 { return "0" }
        let mag = abs(v)
        if mag >= 1e12 || mag < 1e-9 {
            return String(format: "%.6g", v)
        }
        return String(format: "%.10g", v)
    }

    // MARK: - Scientific functions

    var trigInput: (Double) -> Double {
        radiansMode ? { $0 } : { $0 * .pi / 180 }
    }

    var sinFunction: (Double) -> Double { { x in Foundation.sin(self.trigInput(x)) } }
    var cosFunction: (Double) -> Double { { x in Foundation.cos(self.trigInput(x)) } }
    var tanFunction: (Double) -> Double { { x in Foundation.tan(self.trigInput(x)) } }

    var lnFunction: (Double) -> Double { { x in x > 0 ? Foundation.log(x) : .nan } }
    var logFunction: (Double) -> Double { { x in x > 0 ? Foundation.log10(x) : .nan } }

    var sqrtFunction: (Double) -> Double { { x in x >= 0 ? Foundation.sqrt(x) : .nan } }
    var squareFunction: (Double) -> Double { { $0 * $0 } }
    var reciprocalFunction: (Double) -> Double { { x in x != 0 ? 1 / x : .nan } }

    var factorialFunction: (Double) -> Double { { x in Self.factorial(x) } }

    static func factorial(_ x: Double) -> Double {
        guard x >= 0, x <= 170, x.rounded(.down) == x else { return .nan }
        guard x > 1 else { return 1 }
        var result = 1.0
        for n in 2...Int(x) { result *= Double(n) }
        return result
    }
}
