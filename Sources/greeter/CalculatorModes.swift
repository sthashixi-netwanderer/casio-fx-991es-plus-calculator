import Foundation

// MARK: - Mode & Menu Definitions
//
// Shared type definitions for the calculator's operating modes. Kept in their
// own file so the engine core stays focused on evaluation and state transitions.

public enum CalcMode: String, CaseIterable, Sendable {
    case comp = "COMP"
    case cmplx = "CMPLX"
    case stat = "STAT"
    case baseN = "BASE-N"
    case eqn = "EQN"
    case matrix = "MATRIX"
    case table = "TABLE"
    case vector = "VECTOR"
}

public enum BaseNType: String, CaseIterable, Sendable {
    case dec = "d"
    case hex = "H"
    case bin = "b"
    case oct = "o"
}

/// Complex-number result format (SETUP page 2 → CMPLX, manual §3.5 / §5.2).
public enum ComplexFormat: String, Sendable {
    case rectangular = "a+bi"
    case polar = "r∠θ"
}

public enum MenuState: Equatable, Sendable {
    case none
    case modeMenu
    case setupMenu(page: Int)
    case mthIOMenu
    case fixPrompt
    case sciPrompt
    case normPrompt
    case dispFormatMenu
    case statFreqMenu
    case contrastPrompt
    case clrPrompt
    case constPrompt
    case convPrompt
    case statTypeMenu
    case statSubMenu
    case statDataEditor(row: Int)
    case cmplxMenu
    case cmplxFormatMenu
    case eqnTypeMenu
    case eqnCoeffPrompt(type: Int, coeffName: String, coeffIndex: Int)
    case eqnSolutionView(solutions: [String], index: Int)
    case matrixMenu
    case matrixDimSelect
    case matrixDataSelect
    case matrixDimPrompt(name: String)
    case matrixCellEditor(name: String, row: Int, col: Int)
    case vectorMenu
    case vectorDimSelect
    case vectorDataSelect
    case vectorDimPrompt(name: String)
    case vectorComponentEditor(name: String, index: Int)
    case tablePrompt(step: Int)
    case calcPrompt(varName: Character, remainingVars: [Character])
    case solvePrompt(initialGuess: Double)
    case solveResult(root: Double, residual: Double)
    case authenticityView
}
