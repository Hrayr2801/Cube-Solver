//
//  CFOPSolver.swift
//  CubeSolver1
//
//  Created by Hrayr on 8/10/23.
//

import UIKit

class CFOPSolver: NSObject {
    
    ///Face-turn metric.
    
    private var permutator = CubePermutator()
    private let engine = CubeEngine()
    
    private var sidesOfMoves: [String : Int] = {
        let sideMoves = ["F", "R", "B", "L"]
        var dic: [String : Int] = [:]
        for side in 0...3 {
            let first = sideMoves[side]
            let second = sideMoves[(side - 1 + 4) % 4] + "'"
            dic[first] = side
            dic[second] = side
        }
        return dic
    }()
    
    lazy private var ollAlgorithms: [[Int] : [String]] = {
        return self.loadNumberAlgorithmPairs(name: "OLL", count: 57)
    }()
    
    lazy private var pllAlgorithms: [[Int] : [String]] = {
        return self.loadNumberAlgorithmPairs(name: "PLL", count: 21)
    }()
    
    private let defaultOLLPosition = Array(repeating: 1, count: 9) + Array(repeating: 0, count: 12)
    private let defaultPLLPosition = Array(repeating: 0, count: 11)

    //MARK: - Public
    
    ///optimal cross, OLL and PLL. intuitive advanced F2L
    func solve(cube: [[Int]], completion: @escaping (_ moves: [String]) -> Void) {
        var moves: [String] = []
        let t1 = CACurrentMediaTime()
        cross(cube: cube) { (cube, moves1) in
            let t2 = CACurrentMediaTime()
            print("completed cross", moves1, t2 - t1)
            moves += moves1
            self.f2l(cube: cube) { (cube, moves1) in
                moves += moves1
                print(CACurrentMediaTime() - t2)
                
                let lastLayer = self.lastLayer(cube: cube)
                moves += lastLayer
                
                completion(moves)
            }
        }
    }
    
    //MARK: - Cross
    
    private func cross(cube: [[Int]], completion: @escaping (_ cube: [[Int]], _ moves: [String]) -> Void) {
        permutator.permutations(engine: engine, cube: cube, worthContinuing: { (cube, movesCount) in
            if movesCount > 8 {
                return false
            }
            if movesCount >= 3 {
                let indexes = [7, 5, 1, 3]
                let array = cube[5]
                var rightCount = 0
                var prevRightK: Int?
                for i in 0..<4 {
                    if array[indexes[i]] == 5 {
                        let k = (cube[i + 1][7] - (i + 1) + 4) % 4
                        if let prev = prevRightK, k != prev {
                            prevRightK = k
                            continue
                        }
                        prevRightK = k
                        
                        rightCount += 1
                        if CGFloat(movesCount) / CGFloat(rightCount) <= 2.5 {
                            return true
                        }
                    }
                }
                return false
            }
            return true
        }, isMatching: { (cube) -> Bool in
            self.isCross(cube: cube)
        }, completion: { cube, moves in
            completion(cube!, moves)
        })
    }
    
    private func isCross(cube: [[Int]]) -> Bool {
        let indexes = [1, 3, 5, 7]
        let array = cube[5]
        for index in indexes {
            if array[index] != 5 {
                return false
            }
        }
        for i in 1...4 {
            if cube[i][7] != i {
                return false
            }
        }
        return true
    }
    
}

//MARK: - Last Layer

extension CFOPSolver {
    
    private func loadNumberAlgorithmPairs(name: String, count: Int) -> [[Int] : [String]] {
        var algorithms: [[Int] : [String]] = [:]
        let string = try! String(contentsOfFile: Bundle.main.path(forResource: name, ofType: "txt")!)
        let array = string.components(separatedBy: "\n")
        for item in array {
            if item.isEmpty {
                continue
            }
            let array1 = item.components(separatedBy: " * ")
            
            let key = array1[0].components(separatedBy: " ").map { (s) -> Int in
                return Int(s)!
            }
            let value = array1[1].components(separatedBy: " ")
            algorithms[key] = value
        }
        if algorithms.count != count {
            abort()
        }
        return algorithms
    }
    
    func generateNumberKeyAlgorithms(name: String, numbers: (_ cube: [[Int]]) -> [Int]) {
        let string = try! String(contentsOfFile: Bundle.main.path(forResource: "\(name) raw", ofType: "txt")!)
        let algorithms = string.components(separatedBy: "\n")
        for algorithm in algorithms {
            if algorithm.isEmpty {
                continue
            }
            let moves = algorithm.components(separatedBy: " ")
            let inverse = engine.inverseAlgorithm(moves)
            
            let cube = try! engine.rotateExtended(cube: CubeOperator.shared.defaultCube, algorithm: inverse)
            let numbers = numbers(cube)
            print(numbers.map({ (n) -> String in
                return "\(n)"
            }).joined(separator: " "), "*", algorithm)
        }
    }
    
    private func lastLayer(cube: [[Int]]) -> [String] {
        var moves: [String] = []
        var cube = cube
        for i in 0...2 {
            let oll = (i == 0)
            for move in ["", "U", "U2", "U'"] {
                var cube1 = cube
                if move != "" {
                    cube1 = try! engine.rotate(cube: cube, algorithm: [move])
                }
                let numbers = (oll ? recognizeOLL(cube: cube1) : recognizePLL(cube: cube1))
                let defaultPosition = (oll ? defaultOLLPosition : defaultPLLPosition)
                if numbers == defaultPosition {
                    if move != "" {
                        moves.append(move)
                    }
                    return moves
                }
                
                if let algorithm = (oll ? ollAlgorithms : pllAlgorithms)[numbers] {
                    let cube2 = try! engine.rotateExtended(cube: cube1, algorithm: algorithm)
                    cube = cube2
                    if move == "" {
                        moves += algorithm
                    } else {
                        moves.append(move)
                        moves += algorithm
                        break
                    }
                }
            }
        }
        return moves
    }
    
    private func recognizeOLL(cube: [[Int]]) -> [Int] {
        var numbers: [Int] = []
        numbers.reserveCapacity(21)
        
        let toBinary: (_ n: Int) -> Int = { n in
            return n == 0 ? 1 : 0
        }
        let top = cube[0]
        for i in 0..<9 {
            numbers.append(toBinary(top[i]))
        }
        for i in 1...4 {
            for j in 0...2 {
                numbers.append(toBinary(cube[i][j]))
            }
        }
        return numbers
    }
    
    private func recognizePLL(cube: [[Int]]) -> [Int] {
        var numbers: [Int] = []
        numbers.reserveCapacity(12)
        
        for i in 1...4 {
            for j in 0...2 {
                let n = cube[i][j]
                numbers.append(n)
            }
        }
        let first = numbers[0]
        for i in 0..<numbers.count {
            var n = numbers[i]
            n -= first
            if n < 0 {
                n += 4
            }
            numbers[i] = n
        }
        numbers.removeFirst()
        return numbers
    }
}

//MARK: - F2L

extension CFOPSolver {
    
    //TODO: - Pre-calculated cache usage
    
    private func f2l(cube: [[Int]], completion: @escaping (_ cube: [[Int]], _ moves: [String]) -> Void) {
        let bottomPlaces = [0, 2, 6, 8]
        var solvedCorners: [Int] = []
        for i in 0...3 {
            if cube[5][bottomPlaces[i]] == 5 &&
                cube[i + 1][6] == i + 1 &&
                cube[i + 1][3] == i + 1 {
                let prevIndex = ((i - 1 + 3) % 3) + 1
                if cube[prevIndex][5] == prevIndex {
                    solvedCorners.append(i)
                }
            }
        }
        f2l(cube: cube, solvedCorners: solvedCorners, completion: completion)
    }
    
    private func f2l(cube: [[Int]], solvedCorners: [Int], completion: @escaping (_ cube: [[Int]], _ moves: [String]) -> Void) {
        if solvedCorners.count == 4 {
            completion(cube, [])
            return
        }
        //find good corner
        var i = 0
        var corner = -1
        let topIndexes = [6, 8, 2, 0]
        for j in 0..<3 {
            var array = [cube[0][topIndexes[j]], cube[(j == 0 ? 4 : j)][2], cube[j + 1][0]]
            if let index = array.firstIndex(of: 5) {
                array.remove(at: index)
                if abs(array[0] - array[1]) == 1 {
                    corner = array.max()! - 1
                } else {
                    corner = array.min()! - 1
                }
                break
            }
        }
        
        
        if corner > 0 {
            i = corner
        } else {
            for j in 0..<4 {
                if solvedCorners.contains(j) {
                    continue
                }
                i = j
                break
            }
        }
        
        //solve
        self.permutator = CubePermutator()
        self.permutator.permutations(engine: self.engine, cube: cube) { (moves, move) -> Bool in
            self.matchingF2l(moves: moves, move: move, side: i, immovableSides: solvedCorners)
        } isMatching: { (cube) -> Bool in
            let face = i + 1
            let prevFace = (i - 1 + 4) % 4 + 1
            for element in [(face, 3), (prevFace, 5), (face, 6), (prevFace, 8)] {
                if cube[element.0][element.1] != element.0 {
                    return false
                }
            }
            return self.isCross(cube: cube)
        } completion: { (cube, moves1) in
            //print("finished", solvedCorners, moves1)
            self.f2l(cube: cube!, solvedCorners: solvedCorners + [i]) { (cube, moves2) in
                completion(cube, moves1 + moves2)
            }
        }
    }
    
    private func matchingF2l(moves: [String], move: String, side: Int, immovableSides: [Int]) -> Bool {
        if moves.count == 11 {
            return false
        }
        let disabled = ["F2", "D2", "D", "D'", "B2", "R2", "L2"]
        if disabled.contains(move) {
            return false
        }
        
        var immovableSides = immovableSides
        if moves.count > 8 {
            immovableSides = Array(0...3)
            immovableSides.remove(at: side)
        }
        if move.first != "U" {
            var lastSideMove = ""
            var sideMovesCount = 0
            for move in moves {
                if move.first != "U" {
                    sideMovesCount += 1
                    lastSideMove = move
                }
            }
            if sideMovesCount % 2 == 1 {
                if (lastSideMove.first != move.first || lastSideMove.count == move.count) {
                    return false
                }
            } else if immovableSides.contains(sidesOfMoves[move]!) {
                return false
            }
        }
        return true
    }
    
    /*func generateF2lFormulas() {
        var requirements: [[(face: Int, index: Int, color: Int)]] = []
        for i in 0..<24 {
            for j in 0..<16 {
                var array: [(face: Int, index: Int, color: Int)] = []
                
                let corner = (i / 3) % 4
                let cornerRotation = i % 3
                let cornerInTop = (i < 12)
                let edge = (j / 2) % 4
                let edgeRotation = j % 2
                let edgeInTop = (j < 8)
                
                var cornerColors = [4, 1, 5]
                if cornerInTop {
                    cornerColors = [5, 1, 4]
                }
                for k in 0..<3 {
                    let color = cornerColors[(cornerRotation + k) % 3]
                    var face = 0
                    var index = 0
                    switch k {
                    case 0:
                        face = (cornerInTop ? 0 : 5)
                        index = (cornerInTop ? [6, 8, 2, 0] : [0, 2, 8, 6])[corner % 4]
                    case 1:
                        face = (corner - 1 + 4) % 4 + 1
                        index = (cornerInTop ? 2 : 8)
                    case 2:
                        face = corner + 1
                        index = (cornerInTop ? 0 : 6)
                    default:
                        break
                    }
                    array.append((face: face, index: index, color: color))
                }
                
                let edgeColors = (edgeRotation == 0 ? [1, 4] : [4, 1])
                if edgeInTop {
                    let faceIndexes = [7, 5, 1, 3]
                    array.append((face: 0, index: faceIndexes[edge], color: edgeColors[0]))
                    
                    array.append((face: edge + 1, index: 1, color: edgeColors[1]))
                } else {
                    array.append((face: edge + 1, index: 3, color: edgeColors[0]))
                    
                    array.append((face: ((edge - 1) % 4) + 1, index: 5, color: edgeColors[1]))
                }
                requirements.append(array)
            }
        }
        formulas(requirements: requirements)
    }
    
    private func formulas(requirements: [[(face: Int, index: Int, color: Int)]], i: Int = 0) {
        if i == requirements.count {
            return
        }
        let item = requirements[i]
        generateF2lFormula(requirements: item) { moves in
            print(item)
            print(moves)
            self.formulas(requirements: requirements, i: i + 1)
        }
    }
    
    private func generateF2lFormula(requirements: [(face: Int, index: Int, color: Int)], immovableSides: [Int], completion: @escaping (_ moves: [String]) -> Void) {
        self.permutator = CubePermutator()
        permutator.permutations(engine: engine, cube: CubeOperator.shared.defaultCube) { (cube) -> Bool in
            for item in requirements {
                if cube[item.face][item.index] != item.color {
                    return false
                }
            }
            return true
        } completion: { (originalCube, moves) in
            //print(moves)
            self.permutator = CubePermutator()
            self.permutator.permutations(engine: self.engine, cube: originalCube) { (moves, move) -> Bool in
                self.matchingF2l(moves: moves, move: move, immovableSides: immovableSides)
            } isMatching: { (cube) -> Bool in
                for index in [1, 3, 5, 7] {
                    if cube[5][index] != originalCube[5][index] {
                        return false
                    }
                }
                for i in 1...4 {
                    if cube[i][7] != originalCube[i][7] {
                        return false
                    }
                }
                for element in [(1, 3), (4, 5), (1, 6), (5, 0)] {
                    if cube[element.0][element.1] != element.0 {
                        return false
                    }
                }
                return true
            } completion: { (cube, moves) in
                completion(moves)
            }
        }

    }*/
    
    
}
