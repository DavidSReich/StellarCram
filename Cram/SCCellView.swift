//
//  SCCellView.swift
//  StellarCram
//
//  Created by David S Reich on 4/08/2014.
//  Copyright (c) 2014 Stellar Software Pty Ltd. All rights reserved.
//

import Foundation
import UIKit

class SCCellView : UIView {
    var row: Int
    var col: Int
    var covered: Bool = false

    required init(coder: NSCoder) {
        fatalError("NSCoding not supported for SCCellView")
    }
    
    init(frame:CGRect, aRow:Int, aCol:Int) {
        row = aRow
        col = aCol
        super.init(frame: frame)
        if (row + col) % 2 == 0 {
            backgroundColor = UIColor(red: 166.0/255.0, green: 97.0/255.0, blue: 26.0/255.0, alpha: 1.0)
        }
        else {
            backgroundColor = UIColor(red: 223.0/255.0, green: 194.0/255.0, blue: 125.0/255.0, alpha: 1.0)
        }
    }
}
