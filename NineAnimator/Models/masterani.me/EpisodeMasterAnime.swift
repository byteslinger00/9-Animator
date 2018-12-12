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

struct NAMasterAnimeStreamingInfo {
    let identifier: Int
    let hostIdentifier: Int
    let hostName: String
    let quality: Int
    
    let embeddedIdentifier: String
    let embeddedPrefix: String
    let embeddedSuffix: String
    
    var target: URL? {
        return URL(string: "\(embeddedPrefix)\(embeddedIdentifier)\(embeddedSuffix)")
    }
}

struct NAMasterAnimeEpisodeInfo {
    enum SelectOption {
        case firstOccurance
        case bestQuality
        case worstQuality
    }
    
    var link: EpisodeLink
    var url: URL
    var animeIdentifier: String
    var episodeIdentifier: String
    var servers: [NAMasterAnimeStreamingInfo]
    
    var availableHosts: [Anime.ServerIdentifier: String] {
        var hosts = [(Anime.ServerIdentifier, String)]()
        servers.forEach{
            src in
            if !hosts.contains(where: { $0.0 == "\(src.hostIdentifier)" }) {
                hosts.append(("\(src.hostIdentifier)", src.hostName))
            }
        }
        return Dictionary(uniqueKeysWithValues: hosts)
    }
    
    func select(server hostIdentifier: Anime.ServerIdentifier, option: SelectOption) -> NAMasterAnimeStreamingInfo? {
        switch option {
        case .bestQuality:
            let servers = self.servers.filter{ "\($0.hostIdentifier)" == hostIdentifier }
                .sorted{ $0.quality > $1.quality }
            return servers.first
        case .worstQuality:
            let servers = self.servers.filter{ "\($0.hostIdentifier)" == hostIdentifier }
                .sorted{ $0.quality > $1.quality }
            return servers.last
        case .firstOccurance:
            return servers.first { "\($0.hostIdentifier)" == hostIdentifier }
        }
    }
    
    init(_ link: EpisodeLink, streamingInfo: [NSDictionary], with url: URL, parentId: String, episodeId: String) {
        self.link = link
        self.url = url
        self.animeIdentifier = parentId
        self.episodeIdentifier = episodeId
        self.servers = streamingInfo.map{
            source in
            let host = source["host"] as! NSDictionary
            return NAMasterAnimeStreamingInfo(
                identifier: source["id"] as! Int,
                hostIdentifier: source["host_id"] as! Int,
                hostName: host["name"] as! String,
                quality: source["quality"] as! Int,
                embeddedIdentifier: source["embed_id"] as! String,
                embeddedPrefix: host["embed_prefix"] as! String,
                embeddedSuffix: host["embed_suffix"] as? String ?? "")
        }
    }
}
