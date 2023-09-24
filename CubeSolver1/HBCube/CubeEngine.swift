//
//  CubeEngine.swift
//  CubeSolver
//
//  Created by Hrayr on 8/7/23.
//

import UIKit

class CubeEngine: NSObject {
    
    enum Errors : Error {
        case invalidAlgorithm
    }
    
    private let faceOrder = ["U", "F", "R", "B", "L", "D"]
    
    let sliceMoves: [Character] = ["M", "E", "S"]
    
    lazy var allMoves: [String] = {
        var array: [String] = []
        array.reserveCapacity(faceOrder.count * 3)
        for item in faceOrder {
            array.append(item)
            array.append(item + "'")
            array.append(item + "2")
        }
        return array
    }()
    
    lazy var oppositeFaces: [Character : Character] = {
        var dic: [Character : Character] = [:]
        let array: [[Character]] = [["F", "B"], ["R", "L"], ["U", "D"]]
        for array1 in array {
            dic[array1[0]] = array1[1]
            dic[array1[1]] = array1[0]
        }
        return dic
    }()
    
    lazy var extendedMoves: [String : [String]] = {
        var extendedMoves: [String : [String]] = [:]
        let slices = ["U" : "E'", "F" : "S", "R" : "M'", "B" : "S'", "L" : "M", "D" : "E"]
        for move in faceOrder {
            extendedMoves[move.lowercased()] = [move, slices[move]!]
        }
        
        for move in extendedMoves.keys {
            extendedMoves[oppositeMove(move)] = extendedMoves[move]!.map({ (move) -> String in
                return self.oppositeMove(move)
            })
        }
        for move in extendedMoves.keys {
            extendedMoves[move + "2"] = extendedMoves[move]!.map({ (move) -> String in
                var move = move
                if move.last == "'" {
                    move.removeLast()
                }
                return move + "2"
            })
        }
        return extendedMoves
    }()
    
    //MARK: - Public
    
    ///supports slice moves (M, E, S)
    func rotate(cube: [[Int]], algorithm: [String]) throws -> [[Int]] {
        var cube = cube
        for move in algorithm {
            guard let first = move.first, move.count <= 2 else {
                throw Errors.invalidAlgorithm
            }
            var clockwise = true
            var count = 1
            if let last = move.last, move.count == 2 {
                if last == "'" {
                    clockwise = false
                } else if last == "2" {
                    count = 2
                } else {
                    throw Errors.invalidAlgorithm
                }
            }
            if let face = faceOrder.firstIndex(of: String(first)) {
                for _ in 0..<count {
                    cube = CubeOperator.shared.rotateFace(cube: cube, face: face, clockwise: clockwise)
                }
            } else if sliceMoves.contains(move.first!) {
                for _ in 0..<count {
                    cube = CubeOperator.shared.sliceCube(cube, direction: move.first!, clockwise: clockwise)
                }
            } else {
                throw Errors.invalidAlgorithm
            }
            
        }
        return cube
    }
    
    ///supports extended moves (r, M, etc.)
    func rotateExtended(cube: [[Int]], algorithm: [String]) throws -> [[Int]] {
        var algorithm = algorithm
        var i = 0
        while i < algorithm.count {
            if let moves = extendedMoves[algorithm[i]] {
                algorithm.remove(at: i)
                algorithm.insert(contentsOf: moves, at: i)
                
                i += moves.count
            } else {
                i += 1
            }
        }
        return try rotate(cube: cube, algorithm: algorithm)
    }
    
    func isAlgorithmClean(cleanMoves: [String], addingMove move: String, elite: Bool) -> Bool {
        let eliteFaces: [Character] = ["F", "R", "U"]
        let opposite = self.oppositeFaces[move.first!]!
        for i in 0..<cleanMoves.count {
            let i = cleanMoves.count - 1 - i
            let first = cleanMoves[i].first!
            if first == opposite {
                if elite && !eliteFaces.contains(first) {
                    return false
                } else {
                    continue
                }
            }
            return first != move.first
        }
        return true
    }
    
    func cleanAlgorithm(_ algorithm: [String]) -> [String] {
        var algorithm = algorithm
        
        var i = 0
        while i < algorithm.count {
            let move = algorithm[i]
            let opposite = oppositeFaces[Character(move.first!.uppercased())]
            
            let values: [Character : Int] = ["2" : 2, "'" : -1]
            var moveValue = values[move.last!] ?? 1
            
            var j = i + 1
            while j < algorithm.count {
                let move1 = algorithm[j]
                if move1.first == opposite {
                    j += 1
                } else if move.first == move1.first {
                    moveValue += values[move1.last!] ?? 1
                    algorithm.remove(at: j)
                } else {
                    break
                }
            }
            
            let newMove = (moveValue + 4) % 4
            if newMove == 0 {
                algorithm.remove(at: i)
            } else {
                let endings = [2 : "2", 3 : "'", 1 : ""]
                algorithm[i] = String(move.first!) + endings[newMove]!
                i += 1
            }
        }
        return algorithm
    }
    
    func randomScramble(movesCount: Int = 20) -> [[Int]] {
        var moves: [String] = []
        let count = movesCount
        moves.reserveCapacity(count)
        for _ in 0..<count {
            while let move = allMoves.randomElement() {
                if isAlgorithmClean(cleanMoves: moves, addingMove: move, elite: false) {
                    moves.append(move)
                    break
                }
            }
        }
        print(moves)
        return try! rotate(cube: CubeOperator.shared.defaultCube, algorithm: moves)
    }
    
    func oppositeMove(_ move: String) -> String {
        var move = move
        if move.last == "2" {
            return move
        }
        if move.last == "'" {
            move.removeLast()
        } else {
            move += "'"
        }
        return move
    }
    
    func inverseAlgorithm(_ algorithm: [String]) -> [String] {
        return algorithm.reversed().map { (move) -> String in
            return oppositeMove(move)
        }
    }
}
