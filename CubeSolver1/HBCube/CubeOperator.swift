//
//  CubeSolver.swift
//  CubeSolver
//
//  Created by Hrayr on 8/5/23.
//

import UIKit

class CubeOperator: NSObject {
        
    //MARK: - Variables
    
    static let shared = CubeOperator()
    
    private var faceRotationIndexesClockwise: [[(face: Int, indexes: [Int])]] = []
    private var sliceIndexesClockwise: [Character : [(face: Int, indexes: [Int])]] = [:]

    private(set) var defaultCube: [[Int]] = []
    
    //MARK: - Public
    
    func rotateFace(cube: [[Int]], face: Int, clockwise: Bool) -> [[Int]] {
        let array = faceRotationIndexesClockwise[face]
        
        var cube1 = rotateIndexesInCube(cube, clockwise: clockwise, indexes: array)
        cube1[face] = rotateFace(cube1[face], clockwise: clockwise)
        return cube1
    }
    
    func sliceCube(_ cube: [[Int]], direction: Character, clockwise: Bool) -> [[Int]] {
        let indexes = sliceIndexesClockwise[direction]!
        return rotateIndexesInCube(cube, clockwise: clockwise, indexes: indexes)
    }
    
    //MARK: - Private
    
    override init() {
        super.init()
        
        generateFaceRotationIndexes()
        generateSliceIndexes()
        
        for i in 0..<6 {
            defaultCube.append(Array(repeating: i, count: 9))
        }
    }
    
    private func rotateIndexesInCube(_ cube: [[Int]], clockwise: Bool, indexes: [(face: Int, indexes: [Int])]) -> [[Int]] {
        var current = indexes[0]
        var cube1: [[Int]] = cube
        for i in 0..<4 {
            var i = i
            if !clockwise && i != 0 {
                i = 4 - i
            }
            
            let next = indexes[(i + (clockwise ? 1 : -1) + 4) % 4]
            for j in 0..<current.indexes.count {
                cube1[next.face][next.indexes[j]] = cube[current.face][current.indexes[j]]
            }
            current = next
        }
        return cube1
    }
    
    private func generateSliceIndexes() {
        let yIndexes = [1, 4, 7]
        let xIndexes = [3, 4, 5]
        
        let mFaces = [0, 1, 5, 3]
        var mArray: [(face: Int, indexes: [Int])] = []
        for i in 0...3 {
            mArray.append((mFaces[i], (i == 3 ? yIndexes : yIndexes.reversed())))
        }
        sliceIndexesClockwise["M"] = mArray
        
        var eArray: [(face: Int, indexes: [Int])] = []
        for i in 0...3 {
            eArray.append((i + 1, xIndexes))
        }
        sliceIndexesClockwise["E"] = eArray
        
        let sFaces = [0, 2, 5, 4]
        var sArray: [(face: Int, indexes: [Int])] = []
        for i in 0...3 {
            var indexes = (i % 2 == 0) ? xIndexes : yIndexes
            if i / 2 == 1 {
                indexes = indexes.reversed()
            }
            sArray.append((sFaces[i], indexes))
        }
        sliceIndexesClockwise["S"] = sArray
    }
        
    private func generateFaceRotationIndexes() {
        if !faceRotationIndexesClockwise.isEmpty {
            return
        }
        faceRotationIndexesClockwise = Array(repeating: [], count: 6)
        let sideIndexes = [[6, 7, 8], [8, 5, 2], [2, 1, 0], [0, 3, 6]]
        for i in 0...5 {
            if i == 0 {
                for j in 0...3 {
                    let j = 3 - j
                    faceRotationIndexesClockwise[i].append((j + 1, sideIndexes[2]))
                }
            } else if i == 5 {
                var array = Array(faceRotationIndexesClockwise[0].reversed())
                for j in 0..<array.count {
                    array[j].indexes = sideIndexes[0]
                }
                faceRotationIndexesClockwise[i] = array
            } else {
                for j in 0...3 {
                    if j == 0 {
                        faceRotationIndexesClockwise[i].append((0, sideIndexes[i - 1]))
                    } else if j == 2 {
                        var index = i - 1
                        if index % 2 == 0 {
                            index = 2 - index
                        }
                        faceRotationIndexesClockwise[i].append((5, sideIndexes[index]))
                    } else {
                        var face = i + (j == 1 ? 1 : -1)
                        face = ((face - 1 + 4) % 4) + 1
                        let index = (j == 1 ? 3 : 1)
                        faceRotationIndexesClockwise[i].append((face, sideIndexes[index]))
                    }
                }
            }
        }
    }
    
    private func rotateFace(_ face: [Int], clockwise: Bool) -> [Int] {
        var newFace = Array(repeating: 0, count: face.count)
        let sideCount = 3
        for i in 0..<face.count {
            let x = i % sideCount
            let y = i / sideCount
            var x1 = 0
            var y1 = 0
            if !clockwise {
                x1 = y
                y1 = sideCount - 1 - x
            } else {
                x1 = sideCount - 1 - y
                y1 = x
            }
            let newI = y1*sideCount + x1
            newFace[newI] = face[i]
        }
        return newFace
    }
    
}
