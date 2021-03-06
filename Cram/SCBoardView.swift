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
//    var clearH = 0
//    var clearV = 0
    var insideGame = false
    var gameOver = false

    enum LocationType {
        case Local  //game is on this system - two local players
        case Remote //game is through GC - each player is local, each opponent is remote
        case AI     //game is on this system - one player is local, other player is AI
    }
    
    func setupBoard(viewController: SCMainViewController) {
        mainViewController = viewController

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

        insideGame = false
        gameOver = false

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

    func setupPlayers(type: SCBoardView.LocationType, otherPlayerName: String?) {
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
            players[1].playerName = "The AI"
            players[1].playerOwnsName = "The AI's"
            players[1].playerType = SCBoardView.LocationType.AI
        } else { //if gameType == SCBoardView.LocationType.Remote {
            players[0].playerName = "You"
            players[0].playerOwnsName = "Your"
            players[0].playerType = SCBoardView.LocationType.Local
            players[1].playerName = otherPlayerName!
            players[1].playerOwnsName = otherPlayerName! + "'s"
            players[1].playerType = SCBoardView.LocationType.Remote
        }
    }

    func startLocalGame() {
        if gameType == SCBoardView.LocationType.Remote {
            mainViewController?.gameCenterManager.disconnectMatch()
        }
        gameType = SCBoardView.LocationType.Local
        setupPlayers(SCBoardView.LocationType.Local, otherPlayerName: nil)
        rematch()
    }

    func startAIGame() {
        if gameType == SCBoardView.LocationType.Remote {
            mainViewController?.gameCenterManager.disconnectMatch()
        }
        gameType = SCBoardView.LocationType.AI
        setupPlayers(SCBoardView.LocationType.AI, otherPlayerName: nil)
        rematch()
    }
    
    func startRemoteGame(otherPlayerName: String) {
        gameType = SCBoardView.LocationType.Remote
        setupPlayers(SCBoardView.LocationType.Remote, otherPlayerName: otherPlayerName)
        rematch()
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
        if currentPlay != nil {
            currentPlay?.setState(SCPlayView.PlayState.Clear)
            currentPlay = nil
        }
        
        currentPlay = newPlay

        if currentPlay != nil {
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
        if currentPlay == nil {
            return
        }

        insideGame = true

        if (gameType == LocationType.Remote) && (players[currentPlayer].playerType == LocationType.Local) {
            mainViewController?.gameCenterManager.sendTurnMessage(currentPlay!, isConfirmed: true)
        }
    
    
        currentPlay?.setState(SCPlayView.PlayState.Committed)
        blockAdjacentPlayViews(currentPlay!)
        
        currentPlay = nil

        if isGameOver() == true {
            gameOver = true
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

//    func isGameOver() -> Bool {
//        clearH = 0
//        clearV = 0
//        //are there moves left?
//        //if no moves left the player who just played loses
//        var gameOver = true
//        for row in 0..<numRows {
//            for col in 0..<(numCols-1) {
//                if horizontalPlays[row][col].playState == SCPlayView.PlayState.Clear {
//                    clearH++
//                    gameOver = false
//                }
//            }
//        }
//        
//        for row in 0..<(numRows-1) {
//            for col in 0..<numCols {
//                if verticalPlays[row][col].playState == SCPlayView.PlayState.Clear {
//                    clearV++
//                    gameOver = false
//                }
//            }
//        }
//        
//        return gameOver
//    }
    
    func isGameOver() -> Bool {
        //are there moves left?
        //if no moves left the player who just played loses
        for row in 0..<numRows {
            for col in 0..<(numCols-1) {
                if horizontalPlays[row][col].playState == SCPlayView.PlayState.Clear {
                    return false
                }
            }
        }
        
        for row in 0..<(numRows-1) {
            for col in 0..<numCols {
                if verticalPlays[row][col].playState == SCPlayView.PlayState.Clear {
                    return false
                }
            }
        }
        
        return true
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

        insideGame = false
        gameOver = false
    }

    func rematch() {
        resetGame()
        currentPlayer = Int(arc4random_uniform(2))
        nextTurn()

        if gameType == LocationType.Remote {
            //at start up this will be sent by BOTH games ... and it's a race condition
            //if each starts with different currentPlayer and sends the messages at the same time
            //the message triggers startMatch() in the other game
            //then each will reset the other's currentPlayer ... test this ... 
            //if it's a problem copy SCFirstPlayerNegotiator
            //this isn't a problem for rematches since rematch starting is asymmetric (the way it's done here)
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

        mainViewController?.setPromptText("It's \(players[currentPlayer].playerOwnsName) turn!")

        if gameType != LocationType.Local {
            if players[currentPlayer].playerType == LocationType.Local {
                userInteractionEnabled = true
            } else {    //the other player
                userInteractionEnabled = false
                if gameType == LocationType.AI {
                    //the AI
                    let aiPlayView = nextAIPlay()
                    let delay = 2.0 * Double(NSEC_PER_SEC)
                    let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
                    dispatch_after(time, dispatch_get_main_queue()) { self.playerTapped(aiPlayView) }
                }
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

//        let clearHProportion = (100 * clearH) / (clearH + clearV)
//        do {
//            if (Int(arc4random_uniform(100)) < clearHProportion) {
//                //find a Clear horizontal play
//                let row = Int(arc4random_uniform(UInt32(horizontalPlays.count)))
//                let col = Int(arc4random_uniform(UInt32(horizontalPlays[0].count)))
//                aiPlayView = horizontalPlays[row][col]
//                if aiPlayView?.playState != SCPlayView.PlayState.Clear {
//                    aiPlayView = nil
//                }
//            } else {
//                //find a Clear vertical play
//                let row = Int(arc4random_uniform(UInt32(verticalPlays.count)))
//                let col = Int(arc4random_uniform(UInt32(verticalPlays[0].count)))
//                aiPlayView = verticalPlays[row][col]
//                if aiPlayView?.playState != SCPlayView.PlayState.Clear {
//                    aiPlayView = nil
//                }
//            }
//
//        } while aiPlayView == nil;

        //count number of playviews
        var numberOfPlayViews = 0
        for aiPlayView in self.subviews {
            
            if aiPlayView is SCPlayView {
                numberOfPlayViews++;
            }
        }
        
        do {
            //get random playView
            let playViewTarget = Int(arc4random_uniform(UInt32(numberOfPlayViews)))
            
            var playViewNum = 0
            //find the playview
            for aiPlayView in self.subviews {
                if aiPlayView is SCPlayView {
                    if playViewNum == playViewTarget {
                        break;
                    }
                    playViewNum++;
                }
            }
        
            //is the playview available?
            if aiPlayView?.playState != SCPlayView.PlayState.Clear {
                aiPlayView = nil
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