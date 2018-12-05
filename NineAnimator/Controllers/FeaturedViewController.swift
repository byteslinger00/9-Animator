//
//  RecentlyUpdatedViewController.swift
//  NineAnimator
//
//  Created by Xule Zhou on 12/3/18.
//  Copyright © 2018 Marcus Zhou. All rights reserved.
//

import UIKit

class FeaturedViewController: UITableViewController {
    var featuredAnimePage: FeaturedAnimePage? = nil {
        didSet{
            tableView.reloadData()
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
            animeCell.animeImageView.image = animeLink.uiImage
            
            return animeCell
        } else if indexPath.section == 1 {
            let animeLink = featuredAnimePage!.latest[indexPath.item]
            let animeCell = tableView.dequeueReusableCell(withIdentifier: "anime.updated", for: indexPath) as! RecentlyUpdatedAnimeTableViewCell
            
            animeCell.title = animeLink.title
            animeCell.coverImage = animeLink.uiImage
            
            return animeCell
        } else {
            fatalError("Unknown section")
        }
    }
}
