//
//  LinkedCubeList.swift
//  CubeSolver
//
//  Created by Hrayr on 8/9/23.
//

import UIKit

class CubeNode {
    init(cube: [[Int]], moves: [String], next: CubeNode? = nil) {
        self.cube = cube
        self.moves = moves
        self.next = next
    }
    
    var cube: [[Int]]
    var moves: [String]
    var next: CubeNode?
}

class LinkedCubeList: NSObject {
    
    var first: CubeNode?
    var last: CubeNode?
    
    func append(_ node: CubeNode) {
        if let last = self.last {
            last.next = node
            self.last = node
        } else {
            self.first = node
            self.last = node
        }
    }
    
    func printAllElements() {
        var node = self.first
        var string = self.description
        while let node1 = node {
            string += ", [\(node1.moves.joined(separator: " "))]"
            node = node1.next
        }
        print(string)
    }
    
}
