//
//  String+IntegerRangeSubstring.swift
//  NineAnimator
//
//  Created by Xule Zhou on 12/4/18.
//  Copyright © 2018 Marcus Zhou. All rights reserved.
//

import Foundation

extension String {
    subscript (bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start...end])
    }
    
    subscript (bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }
    
    subscript (bounds: NSRange) -> String {
        let range = Range(bounds, in: self)!
        return String(self[range])
    }
    
    var matchingRange: NSRange {
        return NSRange(location: 0, length: utf16.count)
    }
}
