//
//  Episode.swift
//  NineAnimator
//
//  Created by Xule Zhou on 12/6/18.
//  Copyright © 2018 Marcus Zhou. All rights reserved.
//

import Foundation
import Alamofire
import SwiftSoup
import AVKit

struct Episode {
    let link: Anime.EpisodeLink
    let target: URL
    
    var name: String { return link.name }
    var parentLink: AnimeLink { return link.parent }
    
    var nativePlaybackSupported: Bool {
        return VideoProviderRegistry.default.provider(for: link.server) != nil
    }
    
    private var _parent: Anime?
    private var _session: Alamofire.SessionManager
    
    init(_ link: Anime.EpisodeLink, on target: URL, with session: Alamofire.SessionManager, parent: Anime? = nil) {
        self.link = link
        self.target = target
        self._parent = parent
        self._session = session
    }
    
    func retrive(onCompletion handler: @escaping NineAnimatorCallback<AVPlayerItem>) -> NineAnimatorAsyncTask? {
        guard let provider = VideoProviderRegistry.default.provider(for: link.server) else {
            handler(nil, NineAnimatorError.providerError("no parser found for server \(link.server)"))
            return nil
        }
        
        return provider.parse(url: target, with: _session, onCompletion: handler)
    }
    
    func parent(onCompletion handler: @escaping NineAnimatorCallback<Anime>){
        if let parent = _parent { handler(parent, nil) }
        else { NineAnimator.default.anime(with: link.parent, onCompletion: handler) }
    }
}

extension Anime {
    func episode(with link: EpisodeLink, onCompletion handler: @escaping NineAnimatorCallback<Episode>) -> NineAnimatorAsyncTask {
        let ajaxHeaders: Alamofire.HTTPHeaders = [ "Referer": self.link.link.absoluteString ]
        
        let task = session
            .request(AjaxPath.episode(for: link.identifier, on: link.server), headers: ajaxHeaders)
            .responseJSON{
                response in
                if case let .failure(error) = response.result {
                    debugPrint("Error: Failiure on request: \(error)")
                    handler(nil, error)
                    return
                }
                
                guard let responseJson = response.value as? NSDictionary else {
                    debugPrint("Error: No content received")
                    handler(nil, NineAnimatorError.responseError("no content received from server"))
                    return
                }
                
                guard let targetString = responseJson["target"] as? String,
                      let target = URL(string: targetString) else {
                    debugPrint("Error: Target not defined or is invalid in response")
                    handler(nil, NineAnimatorError.responseError("target url not defined or invalid"))
                    return
                }
                
                handler(Episode(link, on: target, with: self.session, parent: self), nil)
        }
        
        return task
    }
}
