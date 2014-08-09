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
    var verticalPlays = Array<Array<SCPlayView>>()
    var cellSize:CGFloat = 0
    var currentPlay: SCPlayView?

    func setupBoard() {
#if false
        var parent: UIView? = self
        do {
            NSLog("AAA: %@ (%f %f; %f %f)", parent!, parent!.bounds.origin.x, parent!.bounds.origin.y, parent!.bounds.size.width, parent!.bounds.size.height)
            let parent2 = parent?.superview
            if (parent2 != nil) {
                    parent = parent2
                }
            else {
                    parent = nil
                }
        } while (parent != nil);

#if true
        var newBounds = frame
        newBounds.origin.x = 0
        newBounds.origin.y = 0
        self.superview?.superview?.superview?.bounds = newBounds
        self.superview?.superview?.bounds = newBounds
        self.superview?.bounds = newBounds
        self.bounds = newBounds
#else
        let fullScreen = UIScreen.mainScreen().bounds
        NSLog("FULLSCREEN: (%f %f; %f %f)", fullScreen.origin.x, fullScreen.origin.y, fullScreen.size.width, fullScreen.size.height)
        self.superview?.superview?.superview?.frame = fullScreen
        self.superview?.superview?.frame = fullScreen
        self.superview?.frame = fullScreen
        self.frame = fullScreen
        self.superview?.superview?.superview?.bounds = fullScreen
        self.superview?.superview?.bounds = fullScreen
        self.superview?.bounds = fullScreen
        self.bounds = fullScreen
#endif

        parent = self
        do {
            NSLog("%BBB: %@ (%f %f; %f %f)", parent!, parent!.bounds.origin.x, parent!.bounds.origin.y, parent!.bounds.size.width, parent!.bounds.size.height)
            let parent2 = parent?.superview
            if (parent2 != nil) {
                parent = parent2
            }
            else {
                parent = nil
            }
        } while (parent != nil);
#endif

        userInteractionEnabled = true
        
//        self.layer.borderColor = UIColor.greenColor().CGColor
//        self.layer.borderWidth = 1

        cellSize = CGFloat(min(self.frame.size.height, self.frame.size.width)) / CGFloat(kNumRowsCols)

        //create cells - 8x8
        createCells()
        //create horizontal boundaries
        createHorizontalPlays()
        //create vertical boundaries
        createVerticalPlays()
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
                var play = SCPlayView(theBoard: self, frame: frame, aRow: row, aCol: col, aOrientation: SCPlayView.PlayOrientation.Horizontal)
                rowArray.append(play)
                let center = CGPoint(x: CGFloat(col + 1) * cellSize, y: (CGFloat(row) + 0.5) * cellSize)
                 play.center = center
                self.addSubview(play)
            }

            horizontalPlays.append(rowArray)
        }
    }

    func createVerticalPlays() {
        for row in 0..<(numRows-1) {
            var rowArray = Array<SCPlayView>()
            for col in 0..<numCols {
                let frame = CGRectMake(0, 0, cellSize * 2, cellSize)
                var play = SCPlayView(theBoard: self, frame: frame, aRow: row, aCol: col, aOrientation: SCPlayView.PlayOrientation.Vertical)
                rowArray.append(play)
                let center = CGPoint(x: (CGFloat(col) + 0.5) * cellSize, y: (CGFloat(row) + 1.0) * cellSize)
                play.center = center
                self.addSubview(play)
            }

            verticalPlays.append(rowArray)
        }
    }

/*
    playerTapped -
        if haveCurrentPlay
            currentPlay.setState(Clear)
        set currentPlay = thisPlay
        currentPlay.setState(Tentative)
    playerCommitted - 
        currentPlay.setState(Committed)
        currentPlay = nil
        mark cells
        check for check, checkmate??
        swap players
*/
    //used by current (local) player so board will be marked
    func playerTapped(newPlay: SCPlayView, playerNum: Int, undo: Bool) {
        if currentPlay? != nil {
            currentPlay?.setState(SCPlayView.PlayState.Clear)
            currentPlay = nil
        }
        
        currentPlay = newPlay

        if currentPlay? != nil {
            currentPlay?.setState(SCPlayView.PlayState.Tentative)
        }
    }

    //used by local and remote players to complete move
    //a local player will have already called playerPlayed()
    //a remote player will have called playerPlayed() but this is not transmitted to the other player, so the playerCommitted() must
    //also invoke playerPlayed ... there should be no "cost" to calling playerPlayed() twice
//    func playerCommitted(row: Int, col: Int, orientation: SCPlayView.PlayOrientation, playerNum: Int) {
    func playerCommitted() {
        if currentPlay? == nil {
            return
        }

        currentPlay?.setState(SCPlayView.PlayState.Committed)

        //keep these to mark the cells, and disable the adjacent boundaries
        let row = currentPlay?.row
        let col = currentPlay?.col
        let orientation = currentPlay?.orientation
        
        currentPlay = nil

        //mark cells
//        check for check, checkmate??
//            swap players
    }
    
}