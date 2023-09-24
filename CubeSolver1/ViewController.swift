//
//  ViewController.swift
//  CubeSolver1
//
//  Created by Hrayr on 8/9/23.
//

import UIKit

class ViewController: UIViewController {
    
    let solver = CFOPSolver()
    let engine = CubeEngine()
    let permutator = CubePermutator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cube = engine.randomScramble(movesCount: 20)
        //let cube = try! engine.rotate(cube: CubeOperator.shared.defaultCube, algorithm: ["D2", "R\'", "F", "D2", "B2", "R", "D", "R", "F\'", "B2", "L\'", "R2", "U\'", "B", "R\'", "L", "U\'", "L2", "U2", "B2"])
                
        solver.solve(cube: cube) { (moves) in
            print(moves, moves.count)
            let clean = self.engine.cleanAlgorithm(moves)
            print(clean, clean.count)
        }
    }
    
    private func filterString() {
        let string = try! String(contentsOfFile: Bundle.main.path(forResource: "OLL raw", ofType: "txt")!)
        let array = string.components(separatedBy: "\n").filter { (string) -> Bool in
            let array = string.components(separatedBy: " ")
            if array.count > 3 {
                for item in array {
                    if !(1...2).contains(item.count) {
                        return false
                    }
                }
                return true
            }
            return false
        }
        print(array.joined(separator: "\n"))
        print(array.count)
    }

}

