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

import NineAnimatorCommon
import NineAnimatorNativeParsers
import NineAnimatorNativeSources
import UIKit

/// A boilerplate for using the `MinFilledLayoutDelegate`
///
/// Simplifies the steps of using the `MinFilledFlowLayoutHelper`. Just call the
/// `setLayoutParameters(...)` in `viewDidLoad` and the `MinFilledCollectionViewController`
/// handles all the internals.
class MinFilledCollectionViewController: UICollectionViewController, MinFilledLayoutDelegate, UICollectionViewDelegateFlowLayout {
    // swiftlint:disable implicitly_unwrapped_optional
    private(set) var layoutHelper: MinFilledFlowLayoutHelper!
    // swiftlint:enable implicitly_unwrapped_optional
    
    /// Initialize and set the `MinFilledFlowLayoutHelper` parameters
    ///
    /// This method must be called in `viewDidLoad` and before any layout function is used.
    func setLayoutParameters(alwaysFillLine: Bool, minimalSize: CGSize...) {
        layoutHelper = MinFilledFlowLayoutHelper(
            dataSource: collectionView.dataSource ?? self,
            alwaysFillLine: alwaysFillLine,
            minimalSizes: minimalSize
        )
        collectionView.collectionViewLayout.invalidateLayout()
        layoutHelper.configure(collectionView: collectionView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.layoutHelper.viewWillAppear(collectionView)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if let layoutHelper = layoutHelper {
            layoutHelper.viewWillTransition(
                coordinator: coordinator,
                in: collectionView
            )
        } else { Log.error("[MinFilledCollectionViewController] View changing bounds while the layout helper has not been initialized") }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        layoutHelper.collectionView(
            collectionView,
            layout: layout,
            sizeForItemAt: indexPath
        )
    }
}
