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

import UIKit
import Kingfisher

class FeaturedViewController: UITableViewController {
    var featuredAnimePage: FeaturedAnimePage? = nil {
        didSet{
            UIView.transition(with: tableView,
                              duration: 0.35,
                              options: .transitionCrossDissolve,
                              animations: { self.tableView.reloadData() })
        }
    }
    
    var error: Error?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if case .none = featuredAnimePage {
            NineAnimator.default.loadHomePage {
                page, error in
                DispatchQueue.main.async {
                    self.featuredAnimePage = page
                    self.error = error
                }
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return featuredAnimePage == nil ? 1 : 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if case .none = featuredAnimePage {
            if section == 0 { return 1 }
            return 0
        }
        
        switch section {
        case 0: return featuredAnimePage!.featured.count
        case 1: return featuredAnimePage!.latest.count
        default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if case .none = featuredAnimePage {
            let loadingCell = tableView.dequeueReusableCell(withIdentifier: "loading", for: indexPath)
            return loadingCell
        }
        
        if indexPath.section == 0 {
            let animeLink = featuredAnimePage!.featured[indexPath.item]
            let animeCell = tableView.dequeueReusableCell(withIdentifier: "anime.featured", for: indexPath) as! FeaturedAnimeTableViewCell
            
            animeCell.animeTitleLabel.text = animeLink.title
            animeCell.animeImageView.kf.setImage(with: animeLink.image)
            
            return animeCell
        } else if indexPath.section == 1 {
            let animeLink = featuredAnimePage!.latest[indexPath.item]
            let animeCell = tableView.dequeueReusableCell(withIdentifier: "anime.updated", for: indexPath) as! RecentlyUpdatedAnimeTableViewCell
            
            animeCell.title = animeLink.title
            animeCell.coverImage = animeLink.image
            
            return animeCell
        } else {
            fatalError("Unknown section")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let playerViewController = segue.destination as? AnimeViewController {
            guard let selected = tableView.indexPathForSelectedRow else { return }
            let pools = [
                featuredAnimePage?.featured,
                featuredAnimePage?.latest
            ]
            guard let animeLink = pools[selected.section]?[selected.item] else { return }
            playerViewController.link = animeLink
        }
    }
}
