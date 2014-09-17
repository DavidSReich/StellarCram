//
//  SCMainViewController.swift
//  StellarCram
//
//  Created by David S Reich on 2/08/2014.
//  Copyright (c) 2014 Stellar Software Pty Ltd. All rights reserved.
//

import UIKit
import GameKit


class SCMainViewController: UIViewController, UITabBarDelegate, UIActionSheetDelegate, UIAlertViewDelegate {
    @IBOutlet weak var outerView: UIView!
    @IBOutlet weak var boardView: SCBoardView!
    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var newButton: UITabBarItem!
    @IBOutlet weak var rematchButton: UITabBarItem!
    @IBOutlet weak var infoButton: UITabBarItem!
    @IBOutlet weak var confirmMoveButton: UITabBarItem!
    @IBOutlet weak var playerPrompt: UILabel!
    var gameCenterManager: SCGameCenterManager! = nil

    let kNewGameCommand = 0
    let kRematchCommand = 1

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nibself.
        tabBar.delegate = self

////        var gcViewController: GKGameCenterViewController = GKGameCenterViewController()
////        gcViewController.gameCenterDelegate = self
//        authenticateLocalPlayer()
        gameCenterManager = SCGameCenterManager(theViewController: self)
        
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        // Do any additional setup after loading the view, typically from a nibself.
        boardView.setupPlayers(SCBoardView.LocationType.Local, otherPlayerName: nil)
//        boardView.setupPlayers(SCBoardView.LocationType.AI)
        boardView.setupBoard(self)
//        playerPrompt.font = UIFont(name: "Verdana", size:playerPrompt.frame.size.width * 0.08);
        tabBar.selectedImageTintColor = UIColor.grayColor()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func tabBar(tabBar: UITabBar!, didSelectItem item: UITabBarItem!) {
        if boardView.insideGame && !boardView.gameOver {
            if item == newButton || item == rematchButton {
                //ask about abandoning game
                //then in completion handler either call newGame, rematchGame, or do nothing
                
                let systemVersion = UIDevice.currentDevice().systemVersion
                if NSString(string: UIDevice.currentDevice().systemVersion).doubleValue < 8 {
                    //need this for all iOS 7 devices
                    var alertView = UIAlertView()
                    alertView.title = "Stop the current game?"
                    alertView.message = "This will stop the current game.  Are you sure you want to start a new game?"
                    alertView.delegate = self
                    alertView.addButtonWithTitle("New Game")
                    alertView.addButtonWithTitle("Cancel")
                    alertView.cancelButtonIndex = 1
                    if item == newButton {
                        alertView.tag = kNewGameCommand
                    } else {    //must be rematch
                        alertView.tag = kRematchCommand
                    }
                    alertView.show()
                } else {
                    var alertController = UIAlertController(title: "Stop the current game?", message: "This will stop the current game.  Are you sure you want to start a new game?", preferredStyle: UIAlertControllerStyle.Alert)
                    alertController.addAction(UIAlertAction(title: "New Game", style: UIAlertActionStyle.Default, handler: { (action :UIAlertAction!)in
                        if item == self.newButton {
                            self.newGame()
                        } else if item == self.rematchButton {
                            self.rematchGame()
                        }
                    }))
                    alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
                    self.presentViewController(alertController, animated: true, completion: nil)
                }
                
                return
            }
        }

        if item == newButton {
            newGame()
        } else if item == rematchButton {
            rematchGame()
        } else if item == confirmMoveButton {
            boardView.playerCommitted()
        } else if item == infoButton {
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
//            let infoViewController = storyBoard.instantiateViewControllerWithIdentifier("InfoViewController") as UIViewController
            let infoViewController = storyBoard.instantiateViewControllerWithIdentifier("InfoViewController") as SCInfoViewController
            infoViewController.modalPresentationStyle = UIModalPresentationStyle.FullScreen
            infoViewController.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
            self.presentViewController(infoViewController, animated: true, completion: nil)
        }
    }

    func newGame() {
        let systemVersion = UIDevice.currentDevice().systemVersion
        if NSString(string: UIDevice.currentDevice().systemVersion).doubleValue < 8 {
            //need this for all iOS 7 devices
            var actionSheet = UIActionSheet()
            actionSheet.addButtonWithTitle("Two Player")
            actionSheet.addButtonWithTitle("You vs. AI")
            actionSheet.addButtonWithTitle("Two Player Online")
            actionSheet.addButtonWithTitle("Cancel")
            if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad {
                actionSheet.addButtonWithTitle("")
            }
            actionSheet.title = "New Game"
            actionSheet.cancelButtonIndex = 3
            actionSheet.delegate = self
            actionSheet.showInView(self.view)
        } else {
            var actionSheet: UIAlertController
            if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad {
                actionSheet = UIAlertController(title: "New Game", message: "Do you want to play?", preferredStyle: UIAlertControllerStyle.Alert)
            } else {
                actionSheet = UIAlertController(title: "New Game", message: "Do you want to play?", preferredStyle: UIAlertControllerStyle.ActionSheet)
            }
            actionSheet.addAction(UIAlertAction(title: "Two Player", style: UIAlertActionStyle.Default, handler: { (action :UIAlertAction!)in
                self.boardView.startLocalGame()
            }))
            actionSheet.addAction(UIAlertAction(title: "You vs. AI", style: UIAlertActionStyle.Default, handler: { (action :UIAlertAction!)in
                self.boardView.startAIGame()
            }))
            actionSheet.addAction(UIAlertAction(title: "Two Player OnLine", style: UIAlertActionStyle.Default, handler: { (action :UIAlertAction!)in
                self.gameCenterManager.matchMakerMatchMaker()
            }))
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
            self.presentViewController(actionSheet, animated: true, completion: nil)
        }
    }

    func rematchGame() {
        if boardView.gameType == SCBoardView.LocationType.Remote {
            //ask other player
            gameCenterManager.sendRematchRequestMessage()
            //if the other player wants to rematch then they will start on their system and
            return
        }
        
        boardView.rematch()
    }
    
    func setPromptText(prompt: String) {
        playerPrompt.text = prompt
    }

    func actionSheet(theActionSheet: UIActionSheet!, clickedButtonAtIndex buttonIndex: Int) {
        if (buttonIndex == 0) {
            self.boardView.startLocalGame()
        } else if buttonIndex == 1 {
            self.boardView.startAIGame()
        } else if buttonIndex == 2 {
            self.gameCenterManager.matchMakerMatchMaker()
        }
    }
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if alertView.tag == kNewGameCommand {
            if buttonIndex == 1 {   //canceled
                return
            }
            
            newGame()
        } else if alertView.tag == kRematchCommand {
            if buttonIndex == 1 {   //canceled
                return
            }
            
            rematchGame()
        }
    }
}

