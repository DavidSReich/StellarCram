//
//  SCGameCenterManager.swift
//  StellarCram
//
//  Created by David S Reich on 20/08/2014.
//  Copyright (c) 2014 Stellar Software Pty Ltd. All rights reserved.
//

import Foundation
import GameKit

struct SCCramTurnMessage {
    var row = 0
    var col = 0
    var isHorizontal = false
    var isConfirmed = false
}

class SCGameCenterManager: NSObject, GKMatchmakerViewControllerDelegate, GKMatchDelegate {
    var havePlayer = false
    var mainViewController: SCMainViewController?
    var theMatch: GKMatch?
    var matchStarted = false
    var turnMessage = SCCramTurnMessage()
    var turnData = NSMutableData(length: sizeof(SCCramTurnMessage))

    init(theViewController: SCMainViewController) {
        mainViewController = theViewController
        havePlayer = false
        super.init()
        NSNotificationCenter.defaultCenter().addObserverForName(GKPlayerDidChangeNotificationName, object: nil, queue: NSOperationQueue.mainQueue()) { _ in self.authenticationChanged()}
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("authenticationChanged:"), name: GKPlayerDidChangeNotificationName, object: nil)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: GKPlayerDidChangeNotificationName, object: nil)
    }

    func authenticationChanged() {
        var localPlayer = GKLocalPlayer()
        if (localPlayer.authenticated == true) {
            println("Authentication changed: Player is Authenticated")
            self.havePlayer = true
        } else {
            //popupGCNotAvailable()
            println("Authentication changed: Player Still Not Authenticated")
            self.havePlayer = false
            self.havePlayer = true  //should be false!
        }
    }

    func authenticateLocalPlayer() {
        var localPlayer = GKLocalPlayer()
        localPlayer.authenticateHandler = {(viewController, error) -> Void in
            if (viewController != nil) {
                self.havePlayer = false
                println("Showing GC")
                self.mainViewController?.presentViewController(viewController, animated: true, completion: nil)
            } else if (localPlayer.authenticated == true) {
                println("Player is Authenticated")
                self.havePlayer = true
            } else {
                self.popupGCNotAvailable()
                println("Player Still Not Authenticated")
                self.havePlayer = false
                self.havePlayer = true  //should be false!
            }
        }
    }
    
    func matchMakerMatchMaker() {
        if !havePlayer {
            authenticateLocalPlayer()
            return
        }
        var gcRequest = GKMatchRequest()
        gcRequest.minPlayers = 2
        gcRequest.maxPlayers = 2
        gcRequest.defaultNumberOfPlayers = 2
        
        var gcViewController = GKMatchmakerViewController(matchRequest: gcRequest)
        gcViewController.matchmakerDelegate = self
        
        self.mainViewController?.presentViewController(gcViewController, animated: true, completion: nil)
    }

    //GKMatchmakerViewControllerDelegate
    func matchmakerViewControllerWasCancelled(viewController: GKMatchmakerViewController!) {
        NSLog("CANCELLEDCANCELLED")
        viewController.dismissViewControllerAnimated(true, nil)
    }

    func matchmakerViewController(viewController: GKMatchmakerViewController!, didFailWithError error: NSError!) {
        NSLog("FAILEDFAILED")
        viewController.dismissViewControllerAnimated(true, nil)
    }

    func matchmakerViewController(viewController: GKMatchmakerViewController!, didFindMatch match: GKMatch!) {
        NSLog("MATCHMATCH")
        viewController.dismissViewControllerAnimated(true, nil)
        theMatch = match
        match.delegate = self
        if !matchStarted && match.expectedPlayerCount == 0 {
            matchStarted = true
            mainViewController?.boardView.gameType = SCBoardView.LocationType.Remote
            mainViewController?.boardView.setupPlayers(SCBoardView.LocationType.Remote)
            mainViewController?.boardView.rematch()
        }
    }
    
    func matchmakerViewController(viewController: GKMatchmakerViewController!, hostedPlayerDidAccept player: GKPlayer!) {
        NSLog("ACCEPTEDACCEPTED")
        viewController.dismissViewControllerAnimated(true, nil)
    }

    func matchmakerViewController(viewController: GKMatchmakerViewController!, didFindHostedPlayers players: [AnyObject]!) {
        NSLog("HOSTEDHOSTED")
        viewController.dismissViewControllerAnimated(true, nil)
    }

    //GKMatchDelegate
    func match(match: GKMatch!, didFailWithError error: NSError!) {
        NSLog("Match Failed: \(match) :: \(error)")
    }

    func match(match: GKMatch!, didReceiveData data: NSData!, fromRemotePlayer player: GKPlayer!) {
        receivedData(match, data: data)
    }

    func match(match: GKMatch!, didReceiveData data: NSData!, fromPlayer playerID: String!) {
        receivedData(match, data: data)
    }

    func match(match: GKMatch!, player: GKPlayer!, didChangeConnectionState state: GKPlayerConnectionState) {
        NSLog("Match player connection state changed: \(player) :: \(state)")
    }

    func match(match: GKMatch!, shouldReinvitePlayer playerID: String!) -> Bool {
        return true
    }

    func match(match: GKMatch!, shouldReinviteDisconnectedPlayer player: GKPlayer!) -> Bool {
        return true
    }

    func receivedData(match: GKMatch!, data: NSData!) {
        //make sure message is correct size?
        if data.length == sizeof(SCCramTurnMessage) {
            data.getBytes(&turnMessage, length: sizeof(SCCramTurnMessage))
            //is this a "start" message?
            if turnMessage.row == -1 {
                //START!!
                mainViewController?.boardView.startMatch(turnMessage.col)
                return
            }

            //find SCPlayView
            var thePlay = mainViewController?.boardView.getPlayView(turnMessage.row, col: turnMessage.col, isHorizontal: turnMessage.isHorizontal)
            //tap it
            mainViewController?.boardView.playerTapped(thePlay!)
            //if confirmed then committ it
            if turnMessage.isConfirmed {
                mainViewController?.boardView.playerCommitted()
            }
        }
    }

    func localPlayerTapped(thePlay: SCPlayView) {
        sendTurnMessage(thePlay, isConfirmed: false)
    }
    
    func localPlayerCommitted(thePlay: SCPlayView) {
        sendTurnMessage(thePlay, isConfirmed: true)
    }
    
    func sendTurnMessage(thePlay: SCPlayView, isConfirmed: Bool) {
        turnMessage.row = thePlay.row
        turnMessage.col = thePlay.col
        turnMessage.isHorizontal = (thePlay.orientation == SCPlayView.PlayOrientation.Horizontal)
        turnMessage.isConfirmed = isConfirmed
        sendGameMessage()
    }

    func sendStartMessage(firstPlayer: Int) {
        turnMessage.row = -1
        turnMessage.col = firstPlayer
        sendGameMessage()
    }

    func sendGameMessage() {
        turnData.replaceBytesInRange(NSMakeRange(0, sizeof(SCCramTurnMessage)), withBytes: &turnMessage, length: sizeof(SCCramTurnMessage))
        var sendError: NSErrorPointer = nil
        var rval = theMatch?.sendDataToAllPlayers(turnData, withDataMode: GKMatchSendDataMode.Reliable, error: sendError)
        if rval == false {
            //handle send error???
            NSLog("SendDataError: \(sendError)")
        }
    }

    func popupGCNotAvailable() {
        var alertBox = UIAlertView(title: "The Game Center is not yet available - please try again.", message: nil, delegate: nil, cancelButtonTitle: nil)
        alertBox.show()

        let delay = 2.0 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) { alertBox.dismissWithClickedButtonIndex(0, animated: true) }
        
    }
}
