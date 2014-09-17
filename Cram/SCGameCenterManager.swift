//
//  SCGameCenterManager.swift
//  StellarCram
//
//  Created by David S Reich on 20/08/2014.
//  Copyright (c) 2014 Stellar Software Pty Ltd. All rights reserved.
//

import Foundation
import GameKit

class SCGameCenterManager: NSObject, GKMatchmakerViewControllerDelegate, GKMatchDelegate, UIAlertViewDelegate {
    var havePlayer = false
    var mainViewController: SCMainViewController?
    var theMatch: GKMatch?
    var matchStarted = false
    var keepAlive = false
    var turnMessage = SCCramTurnMessage()
    var turnData = NSMutableData(length: sizeof(SCCramTurnMessage))
    var insideMatchRematch = false
    var playerName = ""

    let kReconnectAgainAlert = 1
    let kRematchRequestAlert = 2
    
    enum MessageType {
        case None
        case Turn
        case StartMatch
        case RematchRequest
        case StartRematch
        case KeepAlive
    }
    
    struct SCCramTurnMessage {
        var messageType = MessageType.None
        var row = 0
        var col = 0
        var isHorizontal = false
        var isConfirmed = false
    }

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

        //??requestAMatch()
    }

    func authenticateLocalPlayer() {
        var localPlayer = GKLocalPlayer()
        localPlayer.authenticateHandler = {(viewController, error) -> Void in
            if (viewController != nil) {
                self.havePlayer = false
                println("Showing GC")
                self.mainViewController?.presentViewController(viewController, animated: true, completion: nil)
            } else {
                if (localPlayer.authenticated == true) {
                    println("Player is Authenticated")
                    self.havePlayer = true
                } else {
//                    self.popupGCNotAvailable()
                    println("Player Still Not Authenticated")
                    self.havePlayer = false
                    self.havePlayer = true  //should be false!
                }

                if !self.matchStarted {
                    self.requestAMatch()
                }
            }
        }
    }
    
    func matchMakerMatchMaker() {
        if !havePlayer {
            authenticateLocalPlayer()
            return
        }

        requestAMatch()
    }

    func requestAMatch() {
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
        if mainViewController?.boardView.gameType == SCBoardView.LocationType.Remote {  //can't go back to remote if we cancel or fail here
            mainViewController?.boardView.startLocalGame()
        }
    }

    func matchmakerViewController(viewController: GKMatchmakerViewController!, didFailWithError error: NSError!) {
        NSLog("FAILEDFAILED")
        viewController.dismissViewControllerAnimated(true, nil)
        if mainViewController?.boardView.gameType == SCBoardView.LocationType.Remote {  //can't go back to remote if we cancel or fail here
            mainViewController?.boardView.startLocalGame()
        }
    }

    func matchmakerViewController(viewController: GKMatchmakerViewController!, didFindMatch match: GKMatch!) {
        NSLog("MATCHMATCH")
        viewController.dismissViewControllerAnimated(true, nil)
        theMatch = match
        match.delegate = self
//        if !matchStarted && match.expectedPlayerCount == 0 {
        if match.expectedPlayerCount == 0 {
            GKPlayer.loadPlayersForIdentifiers(match.playerIDs, withCompletionHandler: {(players: [AnyObject]!, error: NSError!) in
                let otherPlayer = players[0] as GKPlayer
                self.playerName = otherPlayer.displayName.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "\u{200e}\u{201c}\u{201d}\u{202a}\u{202c}"))
//                var alertBox = UIAlertView(title: "OtherPlayer", message: "ID:Name: \(match.playerIDs[0]) : \(playerName) ", delegate: nil, cancelButtonTitle: "Cancel")
//                alertBox.show()
                self.matchStarted = true
                self.mainViewController?.boardView.startRemoteGame(self.playerName)
            })
            keepAlive = true
            sendKeepAliveMessage()  //this will never stop
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
        self.match(match, player: player, didChangeConnectionState: state)
    }

    func match(match: GKMatch!, player playerID: String!, didChangeState state: GKPlayerConnectionState) {
        if state == GKPlayerConnectionState.StateConnected {
            NSLog("DIDCHANGESTATE: StateConnected")
        } else if state == GKPlayerConnectionState.StateDisconnected {
            let now = NSDate()
            NSLog("DIDCHANGESTATE: StateDisconnected: \(now) : \(playerName)")
            self.reconnectToMatch(match, playerName: playerName)
        } else if state == GKPlayerConnectionState.StateUnknown {
//            var alertBox = UIAlertView(title: "StateUnknown", message: "StateUnknown: \(now) : \(playerName)", delegate: nil, cancelButtonTitle: "Cancel")
//            alertBox.show()
            NSLog("DIDCHANGESTATE: StateUnknown")
        } else {
//            var alertBox = UIAlertView(title: "Bad", message: "Bad", delegate: nil, cancelButtonTitle: "Cancel")
//            alertBox.show()
            NSLog("DIDCHANGESTATE: bad state")
        }
    }

    func match(match: GKMatch!, shouldReinvitePlayer playerID: String!) -> Bool {
        NSLog("SHOULDREINVITEPLAYER")
        return true
    }

    func match(match: GKMatch!, shouldReinviteDisconnectedPlayer player: GKPlayer!) -> Bool {
        NSLog("SHOULDREINVITEDISCONNECTEDPLAYER")
        return true
    }

    func receivedData(match: GKMatch!, data: NSData!) {
        //make sure message is correct size?
        if data.length == sizeof(SCCramTurnMessage) {
            data.getBytes(&turnMessage, length: sizeof(SCCramTurnMessage))
            if turnMessage.messageType == MessageType.Turn {
                //find SCPlayView
                var thePlay = mainViewController?.boardView.getPlayView(turnMessage.row, col: turnMessage.col, isHorizontal: turnMessage.isHorizontal)
                //tap it
                mainViewController?.boardView.playerTapped(thePlay!)
                //if confirmed then commit it
                if turnMessage.isConfirmed {
                    mainViewController?.boardView.playerCommitted()
                }
            } else if turnMessage.messageType == MessageType.StartMatch {
                //START!!
                mainViewController?.boardView.startMatch(turnMessage.col)
            } else if turnMessage.messageType == MessageType.RematchRequest {
                rematchRequestAlert()
            } else if turnMessage.messageType == MessageType.KeepAlive {
                //keep alive message ... ignore it
                //we send our own keep alive separately
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
        turnMessage.messageType = MessageType.Turn
        turnMessage.row = thePlay.row
        turnMessage.col = thePlay.col
        turnMessage.isHorizontal = (thePlay.orientation == SCPlayView.PlayOrientation.Horizontal)
        turnMessage.isConfirmed = isConfirmed
        sendGameMessage()
    }

    func sendStartMessage(firstPlayer: Int) {
        turnMessage.messageType = MessageType.StartMatch
        turnMessage.col = firstPlayer
        sendGameMessage()
    }

    func sendRematchRequestMessage() {
        turnMessage.messageType = MessageType.RematchRequest
        turnMessage.col = 0
        sendGameMessage()
    }
    
    func sendStartRematchMessage() {
        turnMessage.messageType = MessageType.StartRematch
        turnMessage.col = 0
        sendGameMessage()
    }
    
    func sendKeepAliveMessage() {
//        turnMessage.messageType = MessageType.KeepAlive
//        turnMessage.col = 0
//        sendGameMessage()
//        if keepAlive {
//            let delay = 1.0 * Double(NSEC_PER_SEC)
//            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
//            dispatch_after(time, dispatch_get_main_queue()) { self.sendKeepAliveMessage() } //do it again
//        }
    }
    
    func sendGameMessage() {
        turnData.replaceBytesInRange(NSMakeRange(0, sizeof(SCCramTurnMessage)), withBytes: &turnMessage, length: sizeof(SCCramTurnMessage))
        var sendError: NSErrorPointer = nil
        var rval = theMatch?.sendDataToAllPlayers(turnData, withDataMode: GKMatchSendDataMode.Reliable, error: sendError)
        if rval == false {
            //handle send error???
            NSLog("SendDataError: \(sendError)")
            keepAlive = false
        }
    }

    func timedAlert(message: String, seconds: Double) {
        var alertBox = UIAlertView(title: message, message: nil, delegate: nil, cancelButtonTitle: nil)
        alertBox.show()

        let delay = seconds * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) { alertBox.dismissWithClickedButtonIndex(0, animated: true) }
    }

    func popupGCNotAvailable() {
        timedAlert("The Game Center is not yet available - please try again.", seconds: 2)
    }
    
    func reconnectToMatch(match: GKMatch, playerName: String) {
        if !self.insideMatchRematch {    //need this because sometimes (but not always) we get two of these and only want to rematch once
            NSLog("DIDCHANGESTATE: attempting rematchWithCompletionHandler")
            var alertBox = UIAlertView(title: "Reconnecting ...", message: "We were disconnected from the match.  Attempting to reconnect to \(playerName).", delegate: nil, cancelButtonTitle: nil)
            alertBox.show()
            self.insideMatchRematch = true
            match.rematchWithCompletionHandler({(newMatch: GKMatch!, error: NSError!) in
                alertBox.dismissWithClickedButtonIndex(0, animated: true)
                self.insideMatchRematch = false
                if error == nil && newMatch != nil && newMatch.expectedPlayerCount == 0 {
                    GKPlayer.loadPlayersForIdentifiers(newMatch.playerIDs, withCompletionHandler: {(players: [AnyObject]!, error: NSError!) in
                        if error == nil {
                            self.theMatch = newMatch
                            newMatch.delegate = self
                            let otherPlayer = players[0] as GKPlayer
                            self.playerName = otherPlayer.displayName.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "\u{200e}\u{201c}\u{201d}\u{202a}\u{202c}"))
                            self.timedAlert("Successfully reconnected with \(playerName)", seconds: 1.0)
                        } else {
                            self.reconnectFailedAlert()
                        }
                    })
                    //game just resumes where it was!! How convenient!
                } else {
                    self.reconnectFailedAlert()
                }
            })
        }
    }

    func reconnectFailedAlert() {
        var alertView = UIAlertView()
        alertView.title = "Reconnect failed ..."
        alertView.message = "Unable to reconnect the current game.  Do you want to try to reconnect again?"
        alertView.delegate = self
        alertView.addButtonWithTitle("Reconnect")
        alertView.addButtonWithTitle("Cancel")
        alertView.cancelButtonIndex = 1
        alertView.tag = kReconnectAgainAlert
        alertView.show()
    }

    func rematchRequestAlert() {
        var alertView = UIAlertView()
        alertView.title = "Rematch Requested!"
        alertView.message = "\(playerName) has asked for a rematch.  Do you want to start a new game right now?"
        alertView.delegate = self
        alertView.addButtonWithTitle("Rematch")
        alertView.addButtonWithTitle("No")
        alertView.cancelButtonIndex = 1
        alertView.tag = kRematchRequestAlert
        alertView.show()
    }

    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if alertView.tag == kReconnectAgainAlert {
            if buttonIndex == 1 {   //canceled
                theMatch?.disconnect()
                theMatch = nil
                requestAMatch()
                return
            }
            
            reconnectToMatch(theMatch!, playerName: playerName)
        } else if alertView.tag == kRematchRequestAlert {
            if buttonIndex == 1 {   //canceled
                return
            }

            //we trigger the rematch!!!
            self.mainViewController?.boardView.rematch()    //this will send a message to the other game
        }
    }

    func disconnectMatch() {
        if theMatch != nil {
            theMatch?.disconnect()
        }
    }
}
