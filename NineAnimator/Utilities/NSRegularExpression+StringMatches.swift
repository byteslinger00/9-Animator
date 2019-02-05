//
//  This file is part of the NineAnimator project.
//
//  Copyright © 2018 Marcus Zhou. All rights reserved.
//
//  NineAnimator is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  NineAnimator is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with NineAnimator.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation

extension NSRegularExpression {
    func matches(in content: String, options: NSRegularExpression.MatchingOptions = []) -> [NSTextCheckingResult] {
        return matches(in: content, options: options, range: content.matchingRange)
    }
    
    // Return the groups of the first matches
    func firstMatch(in content: String, options: NSRegularExpression.MatchingOptions = []) -> [String]? {
        guard let match = matches(in: content, options: options).first else { return nil }
        return (0..<match.numberOfRanges).map { content[match, at: $0] }
    }
}

extension Array where Element == String {
    // Return the first matching group (second array item)
    var firstMatchingGroup: String? {
        if count > 1 {
            return self[1]
        } else { return nil }
    }
}
