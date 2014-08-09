//
//  SCMainViewController.swift
//  StellarCram
//
//  Created by David S Reich on 2/08/2014.
//  Copyright (c) 2014 Stellar Software Pty Ltd. All rights reserved.
//

import UIKit

class SCMainViewController: UIViewController, UITabBarDelegate {
    @IBOutlet weak var outerView: UIView!
    @IBOutlet weak var boardView: SCBoardView!
    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var confirmMoveButton: UITabBarItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nibself.
        tabBar.delegate = self
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        // Do any additional setup after loading the view, typically from a nibself.
        boardView.setupBoard()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func tabBar(tabBar: UITabBar!, didSelectItem item: UITabBarItem!) {
        if item == confirmMoveButton {
            boardView.playerCommitted()
        }
    }
    
}

