//
//  CubePermutator.swift
//  CubeSolver
//
//  Created by Hrayr on 8/8/23.
//

import UIKit

class CubePermutator: NSObject {
    
    private let syncQueue: DispatchQueue = DispatchQueue(label: String(describing: self) + "sync")

    private var finished = false
    private var tasksCount = 0
    private var endedTasksCount = 0
    
    //MARK: - Public
    
    ///Concurrent. Around O(14^n) with default validator in worst case, where n is optimal moves count
    func permutations(engine: CubeEngine, cube: [[Int]], isValid: ((_ algorithm: [String], _ addingMove: String) -> Bool)? = nil, worthContinuing: ((_ cube: [[Int]], _ movesCount: Int) -> Bool)? = nil, isMatching: @escaping (_ cube: [[Int]]) -> Bool, completion: @escaping (_ cube: [[Int]]?, _ moves: [String]) -> Void) {
        if isMatching(cube) {
            completion(cube, [])
            return
        }
        
        var positions: [(move: String, cube: [[Int]])] = []
        for move in engine.allMoves {
            if let isValid = isValid, !isValid([], move) {
                continue
            }
            let cube1 = try! engine.rotate(cube: cube, algorithm: [move])
            if isMatching(cube1) {
                completion(cube1, [move])
                return
            }
            positions.append((move, cube1))
        }
        
        self.tasksCount = positions.count
        self.endedTasksCount = 0
        self.finished = false
        let queue = DispatchQueue(label: String(describing: self) + "permutations", attributes: .concurrent)
        
        for position in positions {
            queue.async {
                self.oneThreadPermutations(engine: engine, cube: position.cube, previousMoves: [position.move], isValid: isValid, worthContinuing: worthContinuing, isMatching: isMatching, completion: completion)
            }
        }
    }
    
    //MARK: - Private
    
    private func oneThreadPermutations(engine: CubeEngine, cube: [[Int]], previousMoves: [String] = [], isValid: ((_ algorithm: [String], _ addingMove: String) -> Bool)? = nil, worthContinuing: ((_ cube: [[Int]], _ movesCount: Int) -> Bool)?, isMatching: @escaping (_ cube: [[Int]]) -> Bool, completion: @escaping (_ cube: [[Int]]?, _ moves: [String]) -> Void) {
        let list = LinkedCubeList()
        list.append(CubeNode(cube: cube, moves: previousMoves))
        //let triedPositions = NSMutableSet()
        
        let semaphore = DispatchSemaphore(value: 0)
        var found = false
        while let node = list.first {
            let cube = node.cube
            let previousMoves = node.moves
            
            /*let matching = isMatching(cube)
            if !matching {
                if let filter = worthContinuing, !filter(cube, previousMoves.count) {
                    
                } else {
                    for move in engine.allMoves {
                        if !engine.isAlgorithmClean(cleanMoves: previousMoves, addingMove: move, elite: true) {
                            continue
                        }
                        if let validator = isValid {
                            if !validator(previousMoves, move) {
                                continue
                            }
                        }
                        
                        let cube1 = try! engine.rotate(cube: cube, algorithm: [move])
                                            
                        var newMoves = previousMoves
                        newMoves.append(move)
                        
                        list.append(CubeNode(cube: cube1, moves: newMoves))
                    }
                }
            }
            self.syncQueue.sync {
                if !self.finished && matching {
                    self.finished = true
                    completion(cube, previousMoves)
                }
                found = self.finished
                semaphore.signal()
            }
            semaphore.wait()
            if found {
                break
            }*/
            for move in engine.allMoves {
                if !engine.isAlgorithmClean(cleanMoves: previousMoves, addingMove: move, elite: true) {
                    continue
                }
                if let validator = isValid {
                    if !validator(previousMoves, move) {
                        continue
                    }
                }
                
                let cube1 = try! engine.rotate(cube: cube, algorithm: [move])
                
                let matching = isMatching(cube1)
                
                
                var newMoves = previousMoves
                newMoves.append(move)
                    
                if let filter = worthContinuing, !matching, !filter(cube1, newMoves.count) {
                    
                } else {
                    list.append(CubeNode(cube: cube1, moves: newMoves))
                }
                                
                self.syncQueue.sync {
                    if !self.finished && matching {
                        self.finished = true
                        completion(cube1, newMoves)
                    }
                    found = self.finished
                    semaphore.signal()
                }
                semaphore.wait()
                if found {
                    break
                }
            }
            if found {
                break
            }
            list.first = list.first?.next
        }
        if !found {
            self.syncQueue.sync {
                self.endedTasksCount += 1
                if self.endedTasksCount == self.tasksCount {
                    completion(nil, [])
                }
            }
        }
        while list.first != nil {
            list.first = list.first?.next
        }
    }
    
}
