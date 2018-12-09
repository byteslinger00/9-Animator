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

import UIKit
import Alamofire

struct AnimeLink: Alamofire.URLConvertible {
    var title: String
    var link: URL
    var image: URL
    
    init(title: String, link: URL, image: URL) {
        self.title = title
        self.link = link
        self.image = image
    }
    
    func asURL() -> URL { return link }
}

extension AnimeLink: Equatable {
    static func == (lhs: AnimeLink, rhs: AnimeLink) -> Bool {
        return lhs.link == rhs.link
    }
}