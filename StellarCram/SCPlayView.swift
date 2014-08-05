//
//  SCPlayView.swift
//  StellarCram
//
//  Created by David S Reich on 5/08/2014.
//  Copyright (c) 2014 Stellar Software Pty Ltd. All rights reserved.
//

import Foundation
import UIKit

let kPiOver2: CGFloat = CGFloat(M_PI_2)

class SCPlayView : UIView, UIGestureRecognizerDelegate {
    var row: Int
    var col: Int
    var orientation: PlayOrientation
    var hotSpotPath: CGMutablePathRef
    var previousPointInsidePoint: CGPoint?
    var previousPointInsideResponse: Bool?
    var tapRecognizer: UITapGestureRecognizer?

    enum PlayOrientation {
        case Horizontal   //piece is played in two adjacent cells in row
        case Vertical   //piece is played in two adjacent cells in column
    }

    required init(coder: NSCoder) {
        fatalError("NSCoding not supported for SCPlayView")
    }
    
    init(frame:CGRect, aRow:Int, aCol:Int, aOrientation:PlayOrientation) {
        row = aRow
        col = aCol
        orientation = aOrientation
        hotSpotPath = CGPathCreateMutable();

        super.init(frame: frame)
        
        //make path
        CGPathMoveToPoint(hotSpotPath, nil, 0, frame.size.height / 2)
        CGPathAddLineToPoint(hotSpotPath, nil, frame.size.width / 2, 0);
        CGPathAddLineToPoint(hotSpotPath, nil, frame.size.width, frame.size.height / 2);
        CGPathAddLineToPoint(hotSpotPath, nil, frame.size.width / 2, frame.size.height);

        //close the path
        CGPathCloseSubpath(hotSpotPath);

//        let rcLabel = UILabel(frame: self.bounds)
//        rcLabel.textAlignment = NSTextAlignment.Center;
//        rcLabel.textColor = UIColor.whiteColor()
//        rcLabel.backgroundColor = UIColor.clearColor()
//        rcLabel.text = String(format: "%d %d", aRow, aCol)
////        rcLabel.font = [UIFont fontWithName:@"Verdana-Bold" size:78.0/16];
//        self.addSubview(rcLabel)

        //rotate AFTER setting dimensions
        if orientation == PlayOrientation.Vertical {
            self.transform = CGAffineTransformMakeRotation(kPiOver2);
        }

//        if (row + col) % 2 == 0 {
//            self.layer.borderColor = UIColor.yellowColor().CGColor
//            self.layer.borderWidth = 1
//        }

        tapRecognizer = UITapGestureRecognizer(target: self, action:Selector("playTapped:"))
        tapRecognizer?.numberOfTapsRequired = 1;
        tapRecognizer?.delegate = self
        
        addGestureRecognizer(self.tapRecognizer!)
    }

    @IBAction func playTapped(recognizer: UITapGestureRecognizer) {
        
    }

    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        let superResult = super.pointInside(point, withEvent: event)
        if (!superResult) {
            return superResult;
        }

        if let thePoint = previousPointInsidePoint {
            if (CGPointEqualToPoint(point, previousPointInsidePoint!)) {
                return self.previousPointInsideResponse!;
            }
        }

        self.previousPointInsidePoint = point;
    
        let response = CGPathContainsPoint(hotSpotPath, nil, point, true);
        
        //        UIEventType et = event.type;
        //        UIEventSubtype est = event.subtype;//
        //        NSLog(@"%hhd  %f %f event:%ld %ld", response, point.x, point.y, et, est);
        
        self.previousPointInsidePoint = point;
        self.previousPointInsideResponse = response;
        return response;
    }

}
