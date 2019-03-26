//
//  This file is part of the NineAnimator project.
//
//  Copyright © 2018-2019 Marcus Zhou. All rights reserved.
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

class NASourceAnimeUltima: BaseSource, Source, PromiseSource {
    var name: String { return "animeultima.eu" }
    
    override var endpoint: String { return "https://www10.animeultima.eu" }
    
    func anime(from link: AnimeLink) -> NineAnimatorPromise<Anime> {
        return .fail(.unknownError)
    }
    
    func episode(from link: EpisodeLink, with anime: Anime) -> NineAnimatorPromise<Episode> {
        return .fail(.unknownError)
    }
    
    func link(from url: URL) -> NineAnimatorPromise<AnyLink> {
        return .fail(.unknownError)
    }
    
    func suggestProvider(episode: Episode, forServer server: Anime.ServerIdentifier, withServerName name: String) -> VideoProviderParser? {
        return nil
    }
}
