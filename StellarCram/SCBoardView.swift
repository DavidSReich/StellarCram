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
//let kNumRowsCols = 4;

class SCBoardView : UIView {

    let numCols = kNumRowsCols;
    let numRows = kNumRowsCols;
    var cells = Array<Array<SCCellView>>()
    var horizontalPlays = Array<Array<SCPlayView>>()
    var verticalPlays = Array<Array<SCPlayView>>()
    var cellSize:CGFloat = 0
    var currentPlay: SCPlayView?
    var mainViewController: SCMainViewController?
    var currentPlayer = 0
    var players = Array<SCPlayer>()
    var gameType = LocationType.Local
    var clearH = 0
    var clearV = 0

    enum LocationType {
        case Local  //game is on this system - two local players
        case Remote //game is through GC - each player is local, each opponent is remote
        case AI     //game is on this system - one player is local, other player is AI
    }
    
    func setupBoard(viewController: SCMainViewController) {
        mainViewController = viewController
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

        currentPlayer = 1
        nextTurn()
#if true
    NSLog("%d", players.count)
    for player in players {
        NSLog("\(player.playerName) -- \(player.playerType.hashValue)")
//        NSLog("%s %d", player.playerName, player.playerType.hashValue)
    }
#endif
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

    func setupPlayers(type: SCBoardView.LocationType) {
        while players.count < 2 {
            players.append(SCPlayer())
        }

        gameType = type
        if gameType == SCBoardView.LocationType.Local {
            players[0].playerName = "Player 1"
            players[0].playerOwnsName = "Player 1's"
            players[0].playerType = SCBoardView.LocationType.Local
            players[1].playerName = "Player 2"
            players[1].playerOwnsName = "Player 2's"
            players[1].playerType = SCBoardView.LocationType.Local
        } else if gameType == SCBoardView.LocationType.AI {
            players[0].playerName = "You"
            players[0].playerOwnsName = "Your"
            players[0].playerType = SCBoardView.LocationType.Local
            players[1].playerName = "AI"
            players[1].playerOwnsName = "AI's"
            players[1].playerType = SCBoardView.LocationType.AI
        } else { //if gameType == SCBoardView.LocationType.Remote {
            players[0].playerName = "You"
            players[0].playerOwnsName = "Your"
            players[0].playerType = SCBoardView.LocationType.Local
            players[1].playerName = "Other Player"
            players[1].playerOwnsName = "Other Player's"
            players[1].playerType = SCBoardView.LocationType.Remote
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

        if players[currentPlayer].playerType == LocationType.AI {
//            let delay = 2.0 * Double(NSEC_PER_SEC)
            let delay = 1.0 * Double(NSEC_PER_SEC)
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
            dispatch_after(time, dispatch_get_main_queue()) { self.playerCommitted() }
        } else if (gameType == LocationType.Remote) && (players[currentPlayer].playerType == LocationType.Local) {
            mainViewController?.gameCenterManager.sendTurnMessage(newPlay, isConfirmed: false)
        }
    }

    //used by local and remote players to complete move
    //a local player will have already called playerTapped()
    //a remote player will have called playerTapped() but this is not transmitted to the other player, so the playerCommitted() must
    //also invoke playerTapped ... there should be no "cost" to calling playerTapped() twice
    func playerCommitted() {
        if currentPlay? == nil {
            return
        }

        if (gameType == LocationType.Remote) && (players[currentPlayer].playerType == LocationType.Local) {
            mainViewController?.gameCenterManager.sendTurnMessage(currentPlay!, isConfirmed: true)
        }
    
    
        currentPlay?.setState(SCPlayView.PlayState.Committed)
        blockAdjacentPlayViews(currentPlay!)
        
        currentPlay = nil

        if isGameOver() == true {
            currentPlayer = currentPlayer == 1 ? 0 : 1
            if gameType != LocationType.Local && players[currentPlayer].playerType == LocationType.Local {
                mainViewController?.setPromptText("\(players[currentPlayer].playerName) have won!")
            } else {
                mainViewController?.setPromptText("\(players[currentPlayer].playerName) has won!")
            }
        } else {
            nextTurn()
        }
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
        cells[row][col].covered = true  //used mainly by "AI"

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
        clearH = 0
        clearV = 0
        //are there moves left?
        //if no moves left the player who just played loses
        var gameOver = true
        for row in 0..<numRows {
            for col in 0..<(numCols-1) {
                if horizontalPlays[row][col].playState == SCPlayView.PlayState.Clear {
                    clearH++
                    gameOver = false
                }
            }
        }
        
        for row in 0..<(numRows-1) {
            for col in 0..<numCols {
                if verticalPlays[row][col].playState == SCPlayView.PlayState.Clear {
                    clearV++
                    gameOver = false
                }
            }
        }
        
        return gameOver
    }
    
    func resetGame() {
        //clear all plays
        for row in 0..<numRows {
            for col in 0..<(numCols-1) {
                horizontalPlays[row][col].setState(SCPlayView.PlayState.Clear)
            }
        }
        
        for row in 0..<(numRows-1) {
            for col in 0..<numCols {
                verticalPlays[row][col].setState(SCPlayView.PlayState.Clear)
            }
        }

        //uncover cells
        for row in 0..<numRows {
            for col in 0..<numCols {
                cells[row][col].covered = false
            }
        }
    }

    func rematch() {
        resetGame()
        currentPlayer = Int(arc4random_uniform(2))
        nextTurn()

        if gameType == LocationType.Remote {
            mainViewController?.gameCenterManager.sendStartMessage(currentPlayer)
        }
    }

    //only called in remote player when receiving startMessage
    func startMatch(firstPlayer: Int) {
        resetGame()
        currentPlayer = firstPlayer
        nextTurn()
    }
    
    func nextTurn() {
        //swap players
        currentPlayer = currentPlayer == 1 ? 0 : 1

        if gameType == LocationType.Local {
            mainViewController?.setPromptText("\(players[currentPlayer].playerName) - it's your turn!")
        } else if gameType == LocationType.AI {
            if players[currentPlayer].playerType == LocationType.Local {
                mainViewController?.setPromptText("\(players[currentPlayer].playerName) - it's your turn!")
                userInteractionEnabled = true
            } else {    //the AI
                mainViewController?.setPromptText("AI - it's your turn!")
                userInteractionEnabled = false
                let aiPlayView = nextAIPlay()

                let delay = 2.0 * Double(NSEC_PER_SEC)
                let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
                dispatch_after(time, dispatch_get_main_queue()) { self.playerTapped(aiPlayView) }
            }
        } else {    //Remote
            if players[currentPlayer].playerType == LocationType.Local {
                mainViewController?.setPromptText("\(players[currentPlayer].playerName) - it's your turn!")
                userInteractionEnabled = true
            } else {    //the other player
                mainViewController?.setPromptText("\(players[currentPlayer].playerName) - it's your turn!")
                userInteractionEnabled = false
            }
        }
    }

    func nextAIPlay() -> SCPlayView {
        //don't check isGameOver() it should have already been called
        //first - are there any covered cells?
        var anyCovered: Bool = false
        for row in 0..<numRows {
            for col in 0..<numCols {
                if cells[row][col].covered == true {
                    anyCovered = true
                }
            }
        }
        //to make a better?? AI, if anyCovered try to play adjacent to one??? or avoid playing next to one?

        var aiPlayView: SCPlayView?

        let clearHProportion = (100 * clearH) / (clearH + clearV)
        do {
            if (Int(arc4random_uniform(100)) < clearHProportion) {
                //find a Clear horizontal play
                let row = Int(arc4random_uniform(UInt32(horizontalPlays.count)))
                let col = Int(arc4random_uniform(UInt32(horizontalPlays[0].count)))
                aiPlayView = horizontalPlays[row][col]
                if aiPlayView?.playState != SCPlayView.PlayState.Clear {
                    aiPlayView = nil
                }
            } else {
                //find a Clear vertical play
                let row = Int(arc4random_uniform(UInt32(verticalPlays.count)))
                let col = Int(arc4random_uniform(UInt32(verticalPlays[0].count)))
                aiPlayView = verticalPlays[row][col]
                if aiPlayView?.playState != SCPlayView.PlayState.Clear {
                    aiPlayView = nil
                }
            }

        } while aiPlayView == nil;

        return aiPlayView!
    }

    func getPlayView(row: Int, col: Int, isHorizontal: Bool) -> SCPlayView {
        if isHorizontal {
            return horizontalPlays[row][col]
        }

        //must be vertical
        return verticalPlays[row][col]
    }
}