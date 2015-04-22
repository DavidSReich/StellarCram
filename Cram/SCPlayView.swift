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

class SCPlayView : UIImageView {
    var boardView: SCBoardView?
    var row: Int
    var col: Int
    var orientation: PlayOrientation
    var hotSpotPath: CGMutablePathRef
    var previousPointInsidePoint: CGPoint?
    var previousPointInsideResponse: Bool?
    var tapRecognizer: UITapGestureRecognizer?
    var doubleTapRecognizer: UITapGestureRecognizer?
    var playState: PlayState = PlayState.Clear
    var playedFrame: CGRect?
    var clearFrame: CGRect?

    enum PlayOrientation {
        case Horizontal   //piece is played in two adjacent cells in row
        case Vertical   //piece is played in two adjacent cells in column
    }

    enum PlayState {
        case Clear  //unmarked
        case Tentative  //mark lightly
        case Committed  //permanent marker
        case Blocked    //unmarked and one of the cells is covered already
    }

    required init(coder: NSCoder) {
        fatalError("NSCoding not supported for SCPlayView")
    }
    
    init(theBoard: SCBoardView, frame:CGRect, aRow:Int, aCol:Int, aOrientation:PlayOrientation) {
        boardView = theBoard
        row = aRow
        col = aCol
        orientation = aOrientation
        hotSpotPath = CGPathCreateMutable();
        clearFrame = frame

        super.init(frame: frame)
        
        //make path
        CGPathMoveToPoint(hotSpotPath, nil, frame.size.width / 4, frame.size.height / 2)
        CGPathAddLineToPoint(hotSpotPath, nil, frame.size.width / 2, 0);
        CGPathAddLineToPoint(hotSpotPath, nil, frame.size.width - frame.size.width / 4, frame.size.height / 2);
        CGPathAddLineToPoint(hotSpotPath, nil, frame.size.width / 2, frame.size.height);

        //close the path
        CGPathCloseSubpath(hotSpotPath);

//        let rcLabel = UILabel(frame: bounds)
//        rcLabel.textAlignment = NSTextAlignment.Center;
//        rcLabel.textColor = UIColor.whiteColor()
//        rcLabel.backgroundColor = UIColor.clearColor()
//        rcLabel.text = String(format: "%d %d", aRow, aCol)
////        rcLabel.font = [UIFont fontWithName:@"Verdana-Bold" size:78.0/16];
//        addSubview(rcLabel)

        //rotate AFTER setting dimensions
        if orientation == PlayOrientation.Vertical {
            transform = CGAffineTransformMakeRotation(kPiOver2);
        }

        tapRecognizer = UITapGestureRecognizer(target: self, action:Selector("playTapped:"))
        tapRecognizer?.enabled = true
        addGestureRecognizer(tapRecognizer!);
        doubleTapRecognizer = UITapGestureRecognizer(target: self, action:Selector("playDoubleTapped:"))
        doubleTapRecognizer?.numberOfTapsRequired = 2
        doubleTapRecognizer?.enabled = true
        addGestureRecognizer(doubleTapRecognizer!);

        userInteractionEnabled = true
    }

    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        let superResult = super.pointInside(point, withEvent: event)
        if (!superResult) {
            return superResult;
        }

        if let thePoint = previousPointInsidePoint {
            if (CGPointEqualToPoint(point, previousPointInsidePoint!)) {
                return previousPointInsideResponse!;
            }
        }

        previousPointInsidePoint = point;
    
        let response = CGPathContainsPoint(hotSpotPath, nil, point, true);
        
        //        UIEventType et = event.type;
        //        UIEventSubtype est = event.subtype;//
        //        NSLog(@"%hhd  %f %f event:%ld %ld", response, point.x, point.y, et, est);
        
        previousPointInsidePoint = point;
        previousPointInsideResponse = response;
        if (response) {
            NSLog("Clicked inside %d R:%d C:%d", orientation.hashValue, row, col)
        }
        return response;
    }

    func playTapped(recognizer: UITapGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.Ended {
            boardView?.playerTapped(self)
            NSLog("Tapped in PlayView")
        }
    }
    
    func playDoubleTapped(recognizer: UITapGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.Ended {
            boardView?.playerCommitted()
            NSLog("Doubletapped in PlayView")
        }
    }
    
    func updatePlayView() {
        if (playState == PlayState.Clear) || (playState == PlayState.Blocked) {
            layer.backgroundColor = UIColor.clearColor().CGColor
            layer.borderColor = UIColor.clearColor().CGColor
            layer.frame = clearFrame!
        }
        else if playState == PlayState.Tentative {
            var insetSize = (orientation == PlayOrientation.Vertical) ? layer.frame.size.height : layer.frame.size.width
            insetSize *= 0.09
            layer.cornerRadius = insetSize * 1.3
            layer.backgroundColor = UIColor.darkGrayColor().CGColor
            layer.borderColor = UIColor.lightGrayColor().CGColor
            layer.borderWidth = 1
            layer.frame = CGRectMake(layer.frame.origin.x + insetSize, layer.frame.origin.y + insetSize, layer.frame.size.width - insetSize * 2, layer.frame.size.height - insetSize * 2)
        } else {    //PlayState.Committed
            //we only transition here from Tentative --
            //which means a Committed message via GameCenter must change state to Tentative before becoming Committed
            //and a move via "AI" must also do this
            layer.backgroundColor = UIColor.blackColor().CGColor
        }
    }

    func setState(newState: PlayState) {
        if playState == newState {
            return
        }

        if newState == PlayState.Blocked && playState == PlayState.Committed {
            return
        }

        //if currently clear
        if playState == PlayState.Clear {
            clearFrame = layer.frame
        }

        playState = newState

        if playState == PlayState.Clear {
            tapRecognizer?.addTarget(self, action: Selector("playTapped:"))
            tapRecognizer?.enabled = true
            doubleTapRecognizer?.removeTarget(self, action: Selector("playDoubleTapped:"))
            doubleTapRecognizer?.enabled = false
            userInteractionEnabled = true
        } else if playState == PlayState.Tentative {
            tapRecognizer?.removeTarget(self, action: Selector("playTapped:"))
            tapRecognizer?.enabled = false
            doubleTapRecognizer?.addTarget(self, action: Selector("playDoubleTapped:"))
            doubleTapRecognizer?.enabled = true
            userInteractionEnabled = true
        } else {    //PlayState.Committed, Blocked
            tapRecognizer?.removeTarget(self, action: Selector("playTapped:"))
            tapRecognizer?.enabled = false
            doubleTapRecognizer?.removeTarget(self, action: Selector("playDoubleTapped:"))
            doubleTapRecognizer?.enabled = false
            userInteractionEnabled = false
        }

        updatePlayView()
    }
}
