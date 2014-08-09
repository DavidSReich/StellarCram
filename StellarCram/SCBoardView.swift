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
        superview?.superview?.superview?.bounds = newBounds
        superview?.superview?.bounds = newBounds
        superview?.bounds = newBounds
        bounds = newBounds
#else
        let fullScreen = UIScreen.mainScreen().bounds
        NSLog("FULLSCREEN: (%f %f; %f %f)", fullScreen.origin.x, fullScreen.origin.y, fullScreen.size.width, fullScreen.size.height)
        superview?.superview?.superview?.frame = fullScreen
        superview?.superview?.frame = fullScreen
        superview?.frame = fullScreen
        frame = fullScreen
        superview?.superview?.superview?.bounds = fullScreen
        superview?.superview?.bounds = fullScreen
        superview?.bounds = fullScreen
        bounds = fullScreen
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
        
//        layer.borderColor = UIColor.greenColor().CGColor
//        layer.borderWidth = 1

        cellSize = CGFloat(min(frame.size.height, frame.size.width)) / CGFloat(kNumRowsCols)

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
                addSubview(cell)
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
                addSubview(play)
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
                addSubview(play)
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
    func playerTapped(newPlay: SCPlayView) {
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
    func playerCommitted() {
        if currentPlay? == nil {
            return
        }

        currentPlay?.setState(SCPlayView.PlayState.Committed)
        blockAdjacentPlayViews(currentPlay!)
        
        currentPlay = nil

//        check for check, checkmate??
//            swap players
    }

    func blockAdjacentPlayViews(thePlay: SCPlayView) {
        let row = thePlay.row
        let col = thePlay.col
        if currentPlay?.orientation == SCPlayView.PlayOrientation.Horizontal {
            blockAdjacentPlayViewsFromCell(row, col: col)
            blockAdjacentPlayViewsFromCell(row, col: col + 1)
        } else {    //Vertical
            blockAdjacentPlayViewsFromCell(row, col: col)
            blockAdjacentPlayViewsFromCell(row + 1, col: col)
        }
    }
    
    func blockAdjacentPlayViewsFromCell(row: Int, col: Int) {
        //to left
        if col > 0 {
            horizontalPlays[row][col - 1].setState(SCPlayView.PlayState.Blocked)
        }
        //to right
        if col < kNumRowsCols - 1 {
            horizontalPlays[row][col].setState(SCPlayView.PlayState.Blocked)
        }
        //above
        if row > 0 {
            verticalPlays[row - 1][col].setState(SCPlayView.PlayState.Blocked)
        }
        //below
        if row < kNumRowsCols - 1 {
            verticalPlays[row][col].setState(SCPlayView.PlayState.Blocked)
        }
    }

    func isGameOver() -> Bool {
        //count possible moves left
        //if no moves left the player who just played loses
        //if there is only one move left then the current player loses
        //there are possible situations with more than one move left where making ANY move results in a loss -- ie the current player has already lost -- can we detect them?  Maybe involves also counting cells?
        return false
    }
}