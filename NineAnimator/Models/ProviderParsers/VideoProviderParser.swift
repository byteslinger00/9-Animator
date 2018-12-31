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
import AVKit
import UIKit

protocol VideoProviderParser {
    func parse(episode: Episode, with session: SessionManager, onCompletion handler: @escaping NineAnimatorCallback<PlaybackMedia>) -> NineAnimatorAsyncTask
}

extension VideoProviderParser {
    var defaultUserAgent: String {
        return "Mozilla/5.0 (iPhone; CPU iPhone OS 11_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/11.0 Mobile/15E148 Safari/604.1"
    }
}

class VideoProviderRegistry {
    static let `default`: VideoProviderRegistry = {
        let defaultProvider = VideoProviderRegistry()
        
        defaultProvider.register(MyCloudParser(), forServer: "MyCloud")
        defaultProvider.register(RapidVideoParser(), forServer: "RapidVideo")
        defaultProvider.register(StreamangoParser(), forServer: "Streamango")
        defaultProvider.register(Mp4UploadParser(), forServer: "Mp4Upload")
        defaultProvider.register(TiwiKiwiParser(), forServer: "Tiwi.Kiwi")
        
        return defaultProvider
    }()
    
    private var providers = [(server: String, provider: VideoProviderParser)]()
    
    func register(_ provider: VideoProviderParser, forServer server: String) {
        providers.append((server, provider))
    }
    
    func provider(for server: String) -> VideoProviderParser? {
        return (providers.first { $0.server.lowercased() == server.lowercased() })?.provider
    }
}
