//
//  SCBoardView.swift
//  StellarCram
//
//  Created by David S Reich on 2/08/2014.
//  Copyright (c) 2014 Stellar Software Pty Ltd. All rights reserved.
//

import UIKit
import Foundation

let kNumRowsCols = 8;

class SCBoardView : UIView {

    let numCols = kNumRowsCols;
    let numRows = kNumRowsCols;
    var cells = Array<Array<SCCellView>>()
    var horizontalPlays = Array<Array<SCPlayView>>()
    var cellSize:CGFloat = 0

    func setupBoard() {
//        self.layer.borderColor = UIColor.greenColor().CGColor
//        self.layer.borderWidth = 1
        cellSize = CGFloat(min(self.frame.size.height, self.frame.size.width)) / CGFloat(kNumRowsCols)

        //create cells - 8x8
        createCells()
        //create horizontal boundaries
        createHorizontalPlays()
        //create vertical boundaries
    }

    func createCells() {
        for row in 0..<numRows {
            var rowArray = Array<SCCellView>()
            for col in 0..<numCols {
                let frame = CGRectMake(0, 0, cellSize, cellSize)
                var cell = SCCellView(frame: frame, aRow: row, aCol: col)
                rowArray.append(cell)
                let center = CGPoint(x: (CGFloat(col) + 0.5) * cellSize, y: (CGFloat(row) + 0.5) * cellSize)
                cell.center = center
                self.addSubview(cell)
            }
            cells.append(rowArray)
        }
    }
    
    func createHorizontalPlays() {
        for row in 0..<numRows {
            var rowArray = Array<SCPlayView>()
            for col in 0..<(numCols-1) {
                let frame = CGRectMake(0, 0, cellSize * 2, cellSize)
                var play = SCPlayView(frame: frame, aRow: row, aCol: col, aOrientation: SCPlayView.PlayOrientation.Horizontal)
                rowArray.append(play)
                let center = CGPoint(x: CGFloat(col + 1) * cellSize, y: (CGFloat(row) + 0.5) * cellSize)
                 play.center = center
                self.addSubview(play)
            }
            horizontalPlays.append(rowArray)
        }
    }
}