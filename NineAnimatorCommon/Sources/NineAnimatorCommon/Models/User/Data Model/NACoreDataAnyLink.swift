//
//  This file is part of the NineAnimator project.
//
//  Copyright © 2018-2020 Marcus Zhou. All rights reserved.
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

import CoreData
import Foundation

@objc(NACoreDataAnyLink)
public class NACoreDataAnyLink: NSManagedObject {
    public var nativeAnyLink: AnyLink? {
        switch self {
        case let coreDataAnimeLink as NACoreDataAnimeLink:
            guard let animeLink = coreDataAnimeLink.nativeAnimeLink else {
                Log.error("[NACoreDataAnyLink] Potential data corruption: unable to retrieve the corresponding anime link associated with this entity.")
                return nil
            }
            return .anime(animeLink)
        case let coreDataListingTitleReference as NACoreDataListingReference:
            guard let listingReference = coreDataListingTitleReference.nativeListingReference else {
                Log.error("[NACoreDataAnyLink] Potential data corruption: unable to retrieve the corresponding list reference associated with this entity.")
                return nil
            }
            return .listingReference(listingReference)
        default:
            Log.error("[NACoreDataAnyLink] Potential data corruption: unknown type of AnyLink. Is the app outdated?")
            return nil
        }
    }
}
