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

import Alamofire
import Foundation

class NineAnimeSource: BaseSource, Source {
    let name: String = "9anime.ru"
    
    override var endpoint: String { return "https://9anime.ru" }
    
    func featured(_ handler: @escaping NineAnimatorCallback<FeaturedContainer>) -> NineAnimatorAsyncTask? {
        return request(browse: "/") {
            value, error in
            guard let value = value else {
                return handler(nil, error)
            }
            
            do {
                let page = try NineAnimeFeatured(value, with: self)
                handler(page, nil)
            } catch {
                handler(nil, error)
            }
        }
    }
    
    func search(keyword: String) -> ContentProvider {
        return NineAnimeSearch(self, query: keyword)
    }
    
    func suggestProvider(episode: Episode, forServer server: Anime.ServerIdentifier, withServerName name: String) -> VideoProviderParser? {
        return VideoProviderRegistry.default.provider(for: name)
    }
}
