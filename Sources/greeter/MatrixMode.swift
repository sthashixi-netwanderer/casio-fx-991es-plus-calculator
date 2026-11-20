import Foundation

// MARK: - Matrix type (MATRIX mode)

public struct Matrix: Equatable, Sendable {
    public var rows: Int
    public var cols: Int
    public var elements: [[Double]]

    public init(rows: Int, cols: Int, initial: Double = 0) {
        self.rows = max(1, min(3, rows))
        self.cols = max(1, min(3, cols))
        self.elements = Array(repeating: Array(repeating: initial, count: self.cols), count: self.rows)
    }

    public init(elements: [[Double]]) {
        self.rows = elements.count
        self.cols = elements.first?.count ?? 0
        self.elements = elements
    }

    public func determinant() -> Double? {
        guard rows == cols else { return nil }
        if rows == 1 { return elements[0][0] }
        if rows == 2 {
            return elements[0][0] * elements[1][1] - elements[0][1] * elements[1][0]
        }
        if rows == 3 {
            let a = elements[0][0], b = elements[0][1], c = elements[0][2]
            let d = elements[1][0], e = elements[1][1], f = elements[1][2]
            let g = elements[2][0], h = elements[2][1], i = elements[2][2]
            return a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g)
        }
        return nil
    }

    public func transpose() -> Matrix {
        var result = Matrix(rows: cols, cols: rows)
        for r in 0..<rows {
            for c in 0..<cols {
                result.elements[c][r] = elements[r][c]
            }
        }
        return result
    }

    public func inverse() -> Matrix? {
        guard rows == cols, let det = determinant(), abs(det) > 1e-12 else { return nil }
        if rows == 1 {
            return Matrix(elements: [[1.0 / det]])
        }
        if rows == 2 {
            return Matrix(elements: [
                [elements[1][1] / det, -elements[0][1] / det],
                [-elements[1][0] / det, elements[0][0] / det]
            ])
        }
        if rows == 3 {
            let a = elements[0][0], b = elements[0][1], c = elements[0][2]
            let d = elements[1][0], e = elements[1][1], f = elements[1][2]
            let g = elements[2][0], h = elements[2][1], i = elements[2][2]
            let inv: [[Double]] = [
                [(e * i - f * h) / det, (c * h - b * i) / det, (b * f - c * e) / det],
                [(f * g - d * i) / det, (a * i - c * g) / det, (c * d - a * f) / det],
                [(d * h - e * g) / det, (g * b - a * h) / det, (a * e - b * d) / det]
            ]
            return Matrix(elements: inv)
        }
        return nil
    }

    public static func + (lhs: Matrix, rhs: Matrix) -> Matrix? {
        guard lhs.rows == rhs.rows && lhs.cols == rhs.cols else { return nil }
        var res = Matrix(rows: lhs.rows, cols: lhs.cols)
        for r in 0..<lhs.rows {
            for c in 0..<lhs.cols {
                res.elements[r][c] = lhs.elements[r][c] + rhs.elements[r][c]
            }
        }
        return res
    }

    public static func - (lhs: Matrix, rhs: Matrix) -> Matrix? {
        guard lhs.rows == rhs.rows && lhs.cols == rhs.cols else { return nil }
        var res = Matrix(rows: lhs.rows, cols: lhs.cols)
        for r in 0..<lhs.rows {
            for c in 0..<lhs.cols {
                res.elements[r][c] = lhs.elements[r][c] - rhs.elements[r][c]
            }
        }
        return res
    }

    public static func * (lhs: Matrix, rhs: Matrix) -> Matrix? {
        guard lhs.cols == rhs.rows else { return nil }
        var res = Matrix(rows: lhs.rows, cols: rhs.cols)
        for r in 0..<lhs.rows {
            for c in 0..<rhs.cols {
                var sum = 0.0
                for k in 0..<lhs.cols {
                    sum += lhs.elements[r][k] * rhs.elements[k][c]
                }
                res.elements[r][c] = sum
            }
        }
        return res
    }
}

// MARK: - Engine MATRIX helpers

extension CalculatorEngine {
    public func insertMatrixToken(_ token: String) {
        if isMthIO {
            if token.hasSuffix("(") {
                insertASTFunction(String(token.dropLast()))
            } else {
                insertASTText(token)
            }
        } else {
            insert(token)
        }
    }

    public func openMatrixNamed(_ name: String, dataMode: Bool = false) {
        if dataMode && definedMatrices.contains(name) {
            beginMatrixCellEdit(name: name)
        } else {
            menuState = .matrixDimPrompt(name: name)
        }
    }

    public func dimsString(for name: String) -> String {
        let m = matrixValue(for: name)
        return "\(m.rows)×\(m.cols)"
    }

    public func matrixValue(for name: String) -> Matrix {
        switch name {
        case "MatB": return matB
        case "MatC": return matC
        case "MatAns": return matAns
        default: return matA
        }
    }

    func setMatrix(_ name: String, to m: Matrix) {
        switch name {
        case "MatB": matB = m
        case "MatC": matC = m
        case "MatAns": matAns = m
        default: matA = m
        }
    }

    public func confirmMatrixDim(buffer: String) {
        guard case .matrixDimPrompt(let name) = menuState else { return }
        let cleaned = buffer.trimmingCharacters(in: .whitespaces)
        let current = matrixValue(for: name)
        var rows = current.rows
        var cols = current.cols
        if !cleaned.isEmpty {
            let parts = cleaned.components(separatedBy: "×")
            if parts.count == 2 {
                rows = Int(parts[0]) ?? 0
                cols = Int(parts[1]) ?? 0
            } else if cleaned.count == 2 {
                rows = Int(String(cleaned.prefix(1))) ?? 0
                cols = Int(String(cleaned.suffix(1))) ?? 0
            } else {
                rows = 0
                cols = 0
            }
        }
        // All nine shapes up to 3×3 are supported, including 1-row matrices.
        guard (1...3).contains(rows), (1...3).contains(cols) else {
            isError = true
            matrixResult = nil
            vectorResult = nil
            isShowingComplexResult = false
            result = "Syntax ERROR"
            menuState = .none
            return
        }
        setMatrix(name, to: Matrix(rows: rows, cols: cols))
        definedMatrices.insert(name)
        beginMatrixCellEdit(name: name)
    }

    func beginMatrixCellEdit(name: String) {
        menuState = .matrixCellEditor(name: name, row: 1, col: 1)
    }

    public func commitMatrixCell(val: Double) {
        guard case .matrixCellEditor(let name, let row, let col) = menuState else { return }
        var m = matrixValue(for: name)
        guard row >= 1 && row <= m.rows, col >= 1 && col <= m.cols else {
            menuState = .none
            return
        }
        m.elements[row - 1][col - 1] = val
        setMatrix(name, to: m)
        definedMatrices.insert(name)

        var nextRow = row
        var nextCol = col + 1
        if nextCol > m.cols {
            nextCol = 1
            nextRow += 1
        }
        if nextRow > m.rows {
            menuState = .none
        } else {
            menuState = .matrixCellEditor(name: name, row: nextRow, col: nextCol)
        }
    }

    @discardableResult
    public func moveMatrixCell(dx: Int, dy: Int) -> Bool {
        guard case .matrixCellEditor(let name, let row, let col) = menuState else { return false }
        let m = matrixValue(for: name)
        guard m.cols > 0, m.rows > 0 else { return false }
        var r = row - 1
        var c = col - 1
        c = (c + dx + m.cols) % m.cols
        r = (r + dy + m.rows) % m.rows
        menuState = .matrixCellEditor(name: name, row: r + 1, col: c + 1)
        return true
    }

    public func matrixCellValue(name: String, row: Int, col: Int) -> Double {
        let m = matrixValue(for: name)
        guard row >= 1 && row <= m.rows, col >= 1 && col <= m.cols else { return 0 }
        return m.elements[row - 1][col - 1]
    }
}
