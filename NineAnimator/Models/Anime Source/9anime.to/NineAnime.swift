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

import Alamofire
import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

class NASourceNineAnime: BaseSource, Source {
    let name: String = "9anime.ru"
    override var endpoint: String { return "https://\(_currentHost)" }
    
#if canImport(UIKit)
    var siteLogo: UIImage { return #imageLiteral(resourceName: "9anime Site Icon") }
#elseif canImport(AppKit)
    var siteLogo: NSImage { return #imageLiteral(resourceName: "9anime Site Icon") }
#endif
    
    var siteDescription: String {
        return "9anime is a popular free anime streaming website and one of the first and best supported sources of NineAnimator. You may be prompt to complete CAPTCHAs occationally."
    }
    
    lazy var _currentHost: String = possibleHosts.first!
    var _endpointDeterminingTask: NineAnimatorAsyncTask? // Avoid multiple concurrent requests
    
    override init(with parent: NineAnimator) {
        super.init(with: parent)
        _internalUAIdentity = "Mozilla/5.0 (iPad; CPU iPhone OS 12_1_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Mobile/15E148 Safari/604.1"
        addMiddleware(NASourceNineAnime._verificationDetectionMiddleware)
    }
    
    override func canHandle(url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return possibleHosts.contains(host)
    }
    
    // Override the request methods to intercept endpoint change
    
    override func request(
            browse url: URL,
            headers: [String: String],
            completion handler: @escaping NineAnimatorCallback<String>
        ) -> NineAnimatorAsyncTask? {
        let task = NineAnimatorMultistepAsyncTask()
        task += super.request(browse: _process(url: url), headers: headers) {
            value, error in // Not using weak self here because Source instances persist
            // If the result is valid, pass it on to the handler
            if let value = value { return handler(value, nil) }
            
            // Return error directly
            if error is NineAnimatorError.AuthenticationRequiredError {
                return handler(value, error)
            }
            
            Log.info("[9anime] Request failed with an error. Trying to resolve a different endpoint.")
            // Trying to determine a new endpoint if an error occurred
            self._endpointDeterminingTask = self.determineEndpoint(url)
                .error { _ in handler(nil, error) }
                .finally {
                    [weak task] newUrl in
                    guard let task = task else { return }
                    Log.info("[9anime] New endpoint found, resuming original task.")
                    task += super.request(browse: newUrl, headers: headers, completion: handler)
                }
        }
        return task
    }
    
    override func request(
            ajax url: URL,
            headers: [String: String],
            completion handler: @escaping NineAnimatorCallback<NSDictionary>
        ) -> NineAnimatorAsyncTask? {
        let task = NineAnimatorMultistepAsyncTask()
        task += super.request(ajax: _process(url: url), headers: headers) {
            value, error in // Not using weak self here because Source instances persist
            // If the result is valid, pass it on to the handler
            if let value = value { return handler(value, nil) }
            
            Log.info("[9anime] Request failed with an error. Trying to resolve a different endpoint.")
            // Trying to determine a new endpoint if an error occurred
            self._endpointDeterminingTask = self.determineEndpoint(url)
                .error { _ in handler(nil, error) }
                .finally {
                    [weak task] newUrl in
                    guard let task = task else { return }
                    Log.info("[9anime] New endpoint found, resuming original task.")
                    task += super.request(ajax: newUrl, headers: headers, completion: handler)
                }
        }
        return task
    }
    
    override func request(
            ajaxString url: URL,
            headers: [String: String],
            completion handler: @escaping NineAnimatorCallback<String>
        ) -> NineAnimatorAsyncTask? {
        let task = NineAnimatorMultistepAsyncTask()
        task += super.request(ajaxString: _process(url: url), headers: headers) {
            value, error in // Not using weak self here because Source instances persist
            // If the result is valid, pass it on to the handler
            if let value = value { return handler(value, nil) }
            
            Log.info("[9anime] Request failed with an error. Trying to resolve a different endpoint.")
            // Trying to determine a new endpoint if an error occurred
            self._endpointDeterminingTask = self.determineEndpoint(url)
                .error { _ in handler(nil, error) }
                .finally {
                    [weak task] newUrl in
                    guard let task = task else { return }
                    Log.info("[9anime] New endpoint found, resuming original task.")
                    task += super.request(ajaxString: newUrl, headers: headers, completion: handler)
                }
        }
        return task
    }
}
