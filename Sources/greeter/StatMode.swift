import Foundation

// MARK: - Statistical Calculations (STAT mode, manual §6)

public enum StatCalculator {
    /// Expand the stored (x, y, freq) rows into a flat observation list.
    public static func observations(_ rows: [(x: Double, y: Double, freq: Double)], paired: Bool) -> [Double] {
        var result: [Double] = []
        for row in rows {
            let count = max(0, Int(row.freq.rounded()))
            let value = paired ? row.y : row.x
            for _ in 0..<count { result.append(value) }
        }
        return result
    }

    public struct Summary {
        public let n: Double
        public let mean: Double
        public let sumX: Double
        public let sumX2: Double
        public let populationSD: Double
        public let sampleSD: Double
        public let min: Double
        public let max: Double
    }

    public static func summarize(_ values: [Double]) -> Summary? {
        guard !values.isEmpty else { return nil }
        let n = Double(values.count)
        let sum = values.reduce(0, +)
        let mean = sum / n
        let sumSq = values.reduce(0) { $0 + $1 * $1 }
        let varianceP = values.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / n
        let varianceS = n > 1 ? values.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / (n - 1) : 0
        return Summary(
            n: n,
            mean: mean,
            sumX: sum,
            sumX2: sumSq,
            populationSD: Foundation.sqrt(varianceP),
            sampleSD: Foundation.sqrt(varianceS),
            min: values.min() ?? 0,
            max: values.max() ?? 0
        )
    }

    /// Least-squares fit y = A + Bx plus Pearson's r (manual §6.7).
    public static func linearRegression(_ points: [(x: Double, y: Double)]) -> (A: Double, B: Double, r: Double)? {
        let n = Double(points.count)
        guard n > 1 else { return nil }
        let sx = points.reduce(0) { $0 + $1.x }
        let sy = points.reduce(0) { $0 + $1.y }
        let sxx = points.reduce(0) { $0 + $1.x * $1.x }
        let syy = points.reduce(0) { $0 + $1.y * $1.y }
        let sxy = points.reduce(0) { $0 + $1.x * $1.y }
        let denom = n * sxx - sx * sx
        guard abs(denom) > 1e-12 else { return nil }
        let b = (n * sxy - sx * sy) / denom
        let a = (sy - b * sx) / n
        let rNum = n * sxy - sx * sy
        let rDen = Foundation.sqrt((n * sxx - sx * sx) * (n * syy - sy * sy))
        let r = rDen > 1e-12 ? rNum / rDen : 0
        return (a, b, r)
    }

    /// Standard-normal CDF via Abramowitz–Stegun 7.1.26 approximation.
    public static func normalCDF(_ z: Double) -> Double {
        let t = 1.0 / (1.0 + 0.2316419 * abs(z))
        let poly = ((((1.330274429 * t - 1.821255978) * t + 1.781477937) * t - 0.356563782) * t + 0.319381530) * t
        let q = 0.3989422804014327 * Foundation.exp(-z * z / 2.0) * poly
        return z >= 0 ? 1.0 - q : q
    }
}

// MARK: - Engine STAT support

extension CalculatorEngine {
    public var isPairedStat: Bool { statType != "1-VAR" }

    /// Begin (or reopen) the statistics editor.
    public func openStatEditor() {
        codeBufferCompatibleReset()
        menuState = .statDataEditor(row: statData.count)
    }

    /// Compatibility hook: the UI owns codeBuffer, so nothing to reset here.
    public func codeBufferCompatibleReset() {}

    /// Commit one value into the editor. For paired types X and Y alternate by row.
    public func commitStatValue(_ value: Double, row: Int) {
        if !isPairedStat {
            if row < statData.count {
                statData[row].x = value
            } else {
                statData.append((x: value, y: 0, freq: 1))
            }
        } else {
            if row < statData.count {
                // Even rows hold X, odd rows hold the matching Y.
                if row % 2 == 0 { statData[row].x = value }
                else { statData[row].x = value }
            } else {
                statData.append((x: value, y: 0, freq: 1))
            }
        }
        menuState = .statDataEditor(row: row + 1)
    }

    /// Compute a statistic from the current data. Keys follow the STAT menu:
    /// n, mean, sumx, sumx2, sx (population), sX (sample), min, max, A, B, r,
    /// P, Q, R, t (normal distribution).
    public func statistic(_ key: String) -> Double? {
        let values = StatCalculator.observations(statData, paired: isPairedStat)
        guard let summary = StatCalculator.summarize(values) else { return nil }
        switch key {
        case "n": return summary.n
        case "mean": return summary.mean
        case "sumx": return summary.sumX
        case "sumx2": return summary.sumX2
        case "sx": return summary.populationSD
        case "sX": return summary.sampleSD
        case "min": return summary.min
        case "max": return summary.max
        case "A", "B", "r":
            let points = statData.map { (x: $0.x, y: $0.y) }
            guard let fit = StatCalculator.linearRegression(points) else { return nil }
            return key == "A" ? fit.A : (key == "B" ? fit.B : fit.r)
        default: return nil
        }
    }

    /// The standardized value (z-score) of a supplied number (manual §6.10).
    public func standardizedValue(_ x: Double) -> Double? {
        let values = StatCalculator.observations(statData, paired: isPairedStat)
        guard let s = StatCalculator.summarize(values), s.populationSD > 0 else { return nil }
        return (x - s.mean) / s.populationSD
    }

    /// Standard-normal distribution functions P/Q/R/t applied to x (manual §6.10).
    public func distribution(_ key: String, x: Double) -> Double? {
        guard let z = standardizedValue(x) else { return nil }
        let cdf = StatCalculator.normalCDF(z)
        switch key {
        case "P": return cdf
        case "Q": return 1.0 - cdf
        case "R": return abs(cdf - 0.5)
        case "t": return z
        default: return nil
        }
    }

    /// Show a computed statistic on the display as a normal result.
    public func showStatistic(_ key: String) {
        guard let value = statistic(key) else {
            isError = true
            result = "Math ERROR"
            return
        }
        isError = false
        lastAnswer = value
        isShowingDecimal = true
        result = CasioEvaluator.format(value, format: displayFormat)
        isShowingResult = true
        menuState = .none
    }

    /// STAT menu (SHIFT+1 while in STAT mode): 1 Var, 2 Sum, 3 MinMax, 4 Reg,
    /// 5 Distr, 6 Data/Edit. Selections show a value directly for the common
    /// single-variable entries.
    @discardableResult
    public func handleStatMenuOption(_ number: Int) -> Bool {
        switch number {
        case 1: showStatistic(isPairedStat ? "A" : "mean")
        case 2: showStatistic(isPairedStat ? "B" : "sumx")
        case 3: showStatistic(isPairedStat ? "r" : "min")
        case 4: showStatistic("max")
        case 5: showStatistic("sx")
        case 6: openStatEditor()
        default: return false
        }
        return true
    }
}
