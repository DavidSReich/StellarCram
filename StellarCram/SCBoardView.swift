//
//  SCBoardView.swift
//  StellarCram
//
//  Created by David S Reich on 2/08/2014.
//  Copyright (c) 2014 Stellar Software Pty Ltd. All rights reserved.
//

import UIKit
//import Foundation

class SCBoardView : UIView {

    init(parentView: UIView) {
        //resize and center ...
        let parentSize = parentView.frame.size
        var shortestSide = min(parentSize.height, parentSize.width)
        shortestSide *= 0.9

        let newFrame = CGRectMake(0, 0, shortestSide, shortestSide)
        super.init(frame:newFrame)

        var center: CGPoint;
        if (parentSize.height < parentSize.width) {
            center = CGPointMake(parentSize.height / 2, parentSize.width / 2)
        }
        else {
            center = CGPointMake(parentSize.width / 2, parentSize.height / 2)
        }
        self.center = center;
        self.layer.borderColor = UIColor.greenColor().CGColor
        self.layer.borderWidth = 1
    }
    
}