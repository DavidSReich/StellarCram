//
//  SCMainViewController.swift
//  StellarCram
//
//  Created by David S Reich on 2/08/2014.
//  Copyright (c) 2014 Stellar Software Pty Ltd. All rights reserved.
//

import UIKit
import GameKit

class SCMainViewController: UIViewController, UITabBarDelegate, UIActionSheetDelegate {
    @IBOutlet weak var outerView: UIView!
    @IBOutlet weak var boardView: SCBoardView!
    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var newButton: UITabBarItem!
    @IBOutlet weak var rematchButton: UITabBarItem!
    @IBOutlet weak var infoButton: UITabBarItem!
    @IBOutlet weak var confirmMoveButton: UITabBarItem!
    @IBOutlet weak var playerPrompt: UILabel!
    var gameCenterManager: SCGameCenterManager! = nil

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
        boardView.setupPlayers(SCBoardView.LocationType.Local)
//        boardView.setupPlayers(SCBoardView.LocationType.AI)
        boardView.setupBoard(self)
        playerPrompt.font = UIFont(name: "Verdana", size:playerPrompt.frame.size.width * 0.08);
        tabBar.selectedImageTintColor = UIColor.grayColor()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func tabBar(tabBar: UITabBar!, didSelectItem item: UITabBarItem!) {
        if item == newButton {
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
                    self.boardView.gameType = SCBoardView.LocationType.Local
                    self.boardView.setupPlayers(SCBoardView.LocationType.Local)
                    self.boardView.rematch()
                    }))
                actionSheet.addAction(UIAlertAction(title: "You vs. AI", style: UIAlertActionStyle.Default, handler: { (action :UIAlertAction!)in
                    self.boardView.gameType = SCBoardView.LocationType.AI
                    self.boardView.setupPlayers(SCBoardView.LocationType.AI)
                    self.boardView.rematch()
                }))
                actionSheet.addAction(UIAlertAction(title: "Two Player OnLine", style: UIAlertActionStyle.Default, handler: { (action :UIAlertAction!)in
                    self.gameCenterManager.matchMakerMatchMaker()
                }))
                actionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
                self.presentViewController(actionSheet, animated: true, completion: nil)
            }
        }
        else if item == rematchButton {
            boardView.rematch()
        } else if item == confirmMoveButton {
            boardView.playerCommitted()
        }
    }

    func setPromptText(prompt: String) {
        playerPrompt.text = prompt
    }

    func actionSheet(theActionSheet: UIActionSheet!, clickedButtonAtIndex buttonIndex: Int) {
        if (buttonIndex == 0) {
            self.boardView.gameType = SCBoardView.LocationType.Local
            self.boardView.setupPlayers(SCBoardView.LocationType.Local)
            self.boardView.rematch()
        } else if buttonIndex == 1 {
            self.boardView.gameType = SCBoardView.LocationType.AI
            self.boardView.setupPlayers(SCBoardView.LocationType.AI)
            self.boardView.rematch()
        } else if buttonIndex == 2 {
            self.gameCenterManager.matchMakerMatchMaker()
        }
    }
    
}

