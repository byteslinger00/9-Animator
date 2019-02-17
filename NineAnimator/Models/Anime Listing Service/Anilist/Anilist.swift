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

class Anilist: BaseListingService, ListingService {
    var name: String { return "AniList.co" }
    
    /// Anilist API endpoint
    let endpoint = URL(string: "https://graphql.anilist.co")!
    
    /// Cached current user settings
    var _currentUser: User?
    
    /// Hold reference to mutation requests
    var _mutationRequestReferencePool = [NineAnimatorAsyncTask]()
    
    override var identifier: String {
        return "com.marcuszhou.nineanimator.service.anilist"
    }
    
    required init(_ parent: NineAnimator) {
        super.init(parent)
    }
}

// MARK: - Exposed interface
extension Anilist {
    var isCapableOfListingAnimeInformation: Bool {
        return true
    }
    
    var isCapableOfPersistingAnimeState: Bool {
        return didSetup && !didExpire
    }
    
    var isCapableOfRetrievingAnimeState: Bool {
        return didSetup && !didExpire
    }
    
    /// Retrieve if Anilist has been setup
    var didSetup: Bool { return accessToken != nil }
    
    /// Retrieve if the OAuth token has expired
    var didExpire: Bool { return accessTokenExpirationDate.timeIntervalSinceNow < 0 }
    
    /// Single-Sign-On URL for AniList
    var ssoUrl: URL { return URL(string: "https://anilist.co/api/v2/oauth/authorize?client_id=1623&response_type=token")! }
    
    /// Single-Sign-On Callback Scheme
    var ssoCallbackScheme: String { return "nineanimator-list-auth" }
}

// MARK: - Tokens & authentication data
extension Anilist {
    private var accessToken: String? {
        get { return persistedProperties["access_token"] as? String }
        set { persistedProperties["access_token"] = newValue }
    }
    
    private var accessTokenExpirationDate: Date {
        get { return (persistedProperties["access_token_expiration"] as? Date) ?? .distantPast }
        set { return persistedProperties["access_token_expiration"] = newValue }
    }
    
    /// Handle authentication event with the callback URL
    func authenticate(with url: URL) -> Error? {
        guard let authFragment = url.fragment?.split(separator: "&") else {
            return NineAnimatorError.urlError
        }
        
        let authValue = Dictionary(uniqueKeysWithValues: authFragment.compactMap {
            item -> (String, String)? in
            let pair = item.split(separator: "=")
            if pair.count > 1 {
                return (String(pair[0]), String(pair[1]))
            } else { return nil }
        })
        
        guard authValue["token_type"] == "Bearer",
            let token = authValue["access_token"],
            let expirationDateString = authValue["expires_in"],
            let expirationDateSeconds = TimeInterval(expirationDateString) else {
                return NineAnimatorError.responseError("Invalid expiration date")
        }
        
        // Persist token and expiration date
        accessToken = token
        accessTokenExpirationDate = Date().addingTimeInterval(expirationDateSeconds)
        Log.info("[AniList.co] Authenticated until %@", accessTokenExpirationDate)
        
        return nil
    }
    
    /// Log Out the Anilist account
    func deauthenticate() {
        Log.info("[AniList.co] Removing credentials")
        accessToken = nil
        accessTokenExpirationDate = Date.distantPast
        _currentUser = nil
    }
}

// MARK: - Making requests
extension Anilist {
    func graphQL(query: String, variables: [String: CustomStringConvertible]) -> NineAnimatorPromise<NSDictionary> {
        var headers = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        
        if let token = accessToken, !didExpire {
            headers["Authorization"] = "Bearer \(token)"
        }
        
        let encodingRequestData: [String: Any] = [
            "query": query,
            "variables": variables
        ]
        
        return NineAnimatorPromise.firstly {
            try JSONSerialization.data(withJSONObject: encodingRequestData, options: [])
        } .thenPromise {
            [unowned self] in
            self.request(self.endpoint, method: .post, data: $0, headers: headers)
        } .then {
            data in
            guard let responseObject = try JSONSerialization.jsonObject(with: data, options: [])
                as? NSDictionary else {
                throw NineAnimatorError.responseError("Cannot decode response from server")
            }
            
            // If the 'errors' entry is present in the response object
            if let errorList = responseObject["errors"] as? [NSDictionary], !errorList.isEmpty {
                Log.error("[Anilist.co] %@ errors are found in the GraphQL query.", errorList.count)
                
                // If only one error is present
                if errorList.count == 1, let errorDict = errorList.first {
                    let message = (errorDict["message"] as? String) ?? "Unknown"
                    let status = (errorDict["status"] as? Int) ?? 0
                    
                    // Unauthorized
                    if status == 401 {
                        throw NineAnimatorError.authenticationRequiredError(message, nil)
                    }
                    
                    // Other errors
                    throw NineAnimatorError.responseError("\(status): \(message)")
                }
                
                throw NineAnimatorError.responseError("GraphQL: \(errorList.count) errors reported")
            }
            
            return responseObject["data"] as? NSDictionary
        }
    }
    
    func mutationGraphQL(query: String, variables: [String: CustomStringConvertible]) {
        let task = graphQL(query: query, variables: variables)
        .error {
            [unowned self] in
            Log.error("[AniList.co] Unable to update: %@", $0)
            self.cleanupReferencePool()
        } .finally {
            [unowned self] _ in
            Log.info("[AniList.co] Mutation made")
            self.cleanupReferencePool()
        }
        _mutationRequestReferencePool.append(task)
    }
    
    private func cleanupReferencePool() {
        _mutationRequestReferencePool.removeAll {
            ($0 as! NineAnimatorPromise<NSDictionary>).isResolved
        }
    }
}
