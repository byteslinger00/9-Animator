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
import Alamofire
import AVKit

class MyCloudParser: VideoProviderParser {
    static let videoIdentifierRegex = try! NSRegularExpression(pattern: "videoId:\\s*'([^']+)", options: .caseInsensitive)
    static let videoSourceRegex = try! NSRegularExpression(pattern: "\"file\":\"([^\"]+)", options: .caseInsensitive)
    
    func parse(episode: Episode, with session: SessionManager, onCompletion handler: @escaping NineAnimatorCallback<PlaybackMedia>) -> NineAnimatorAsyncTask {
        let additionalHeaders: HTTPHeaders = [
            "Referer": episode.parentLink.link.absoluteString,
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "User-Agnet": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_1) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0.1 Safari/605.1.15",
            "Host": "mcloud.to"
        ]
        
        let playerAdditionalHeaders: HTTPHeaders = [
            "Referer": episode.target.absoluteString,
            "User-Agnet": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_1) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0.1 Safari/605.1.15"
        ]
        return session.request(episode.target, headers: additionalHeaders).responseString {
            response in
            guard let text = response.value else {
                debugPrint("Error: \(response.error?.localizedDescription ?? "Unknown")")
                return handler(nil, NineAnimatorError.responseError(
                    "response error: \(response.error?.localizedDescription ?? "Unknown")"
                ))
            }
            
            let matches = MyCloudParser.videoSourceRegex.matches(
                in: text, range: text.matchingRange
            )
            
            guard let match = matches.first else {
                return handler(nil, NineAnimatorError.responseError(
                    "no matches for source url"
                ))
            }
            
            guard let sourceURL = URL(string: text[match.range(at: 1)]) else {
                return handler(nil, NineAnimatorError.responseError(
                    "source url not recongized"
                ))
            }
            
            debugPrint("Info: (MyCloud Parser) found asset at \(sourceURL.absoluteString)")
            
            //MyCloud might not support Chromecast, since it uses COR checking
            handler(BasicPlaybackMedia(
                url: sourceURL,
                parent: episode,
                contentType: "application/vnd.apple.mpegurl",
                headers: playerAdditionalHeaders), nil)
        }
    }
}
