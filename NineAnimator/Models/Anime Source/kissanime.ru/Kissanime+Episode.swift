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

extension NASourceKissanime {
    static let knownServers = [
        "rapidvideo": "RapidVideo",
        "openload": "OpenLoad",
        "mp4upload": "Mp4Upload",
        "streamango": "Streamango",
        "nova": "Nova Server",
        "beta": "Beta Server",
        "beta2": "Beta2 Server"
    ]
    
    func episode(from link: EpisodeLink, with anime: Anime) -> NineAnimatorPromise<Episode> {
        return .fail()
    }
    
    /// Infer the episode number from episode name
    func inferEpisodeNumber(fromName name: String) -> Int? {
        do {
            let matchingRegex = try NSRegularExpression(
                pattern: "Episode\\s+(\\d+)",
                options: [.caseInsensitive]
            )
            let episodeNumberMatch = try matchingRegex
                .firstMatch(in: name)
                .tryUnwrap()
                .firstMatchingGroup
                .tryUnwrap()
            let inferredEpisodeNumber = Int(episodeNumberMatch)
            
            // Return the inferred value if it's valid
            if let eNumb = inferredEpisodeNumber, eNumb > 0 {
                return eNumb
            } else { return nil }
        } catch { return nil }
    }
}
