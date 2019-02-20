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

import UIKit

/// ViewController for presenting listing service anime information
///
/// Must be instantiated from storyboard. See `AnimeViewController`
class AnimeInformationTableViewController: UITableViewController, DontBotherViewController, Themable {
    private var presentingReference: ListingAnimeReference?
    private var presentingAnimeInformation: ListingAnimeInformation?
    
    // References to tasks
    private var listingAnimeRequestTask: NineAnimatorAsyncTask?
    private var characterListRequestTask: NineAnimatorAsyncTask?
    private var episodeFetchingTask: NineAnimatorAsyncTask?
    
    // Cached information list
    private var enumeratedInformationList = [(name: String, value: String)]()
    
    // Cached character list
    private var characterList: [ListingAnimeCharacter]?
    
    // Outlets
    @IBOutlet private var showEpisodesButton: UIButton!
    @IBOutlet private var fetchEpisodesActivityIndicator: UIActivityIndicatorView!
    
    // Cell needs layout handler
    private lazy var needsLayoutHandler: (() -> Void) = {
        [weak self] in
        self?.tableView.performBatchUpdates({
            self?.tableView.setNeedsLayout()
        }, completion: nil)
    }
    
    @IBOutlet private weak var headingView: InformationSceneHeadingView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Resets the episodes fetching button and indicator
        showEpisodesButton.isHidden = false
        fetchEpisodesActivityIndicator.stopAnimating()
        
        // Remove extra lines and make tableview themable
        tableView.tableFooterView = UIView()
        
        // Add tab bar inset
        if let tabBarHeight = tabBarController?.tabBar.frame.height {
            tableView.contentInset = .init(
                top: 0,
                left: 0,
                bottom: tabBarHeight,
                right: 0
            )
        }
        
        tableView.makeThemable()
        
        tableView.performBatchUpdates({
            headingView.sizeToFit()
            tableView.setNeedsLayout()
        }, completion: nil)
        
        // Layout table view when the heading layout has changed
        headingView.onNeededLayout = needsLayoutHandler
        
        // Update navigation bar style
        Theme.provision(self)
        
        guard let reference = presentingReference else {
            return Log.error("AnimeInformationTableViewController is presented without an reference")
        }
        
        // Check if we need to re-request the anime information
        guard presentingAnimeInformation == nil ||
            presentingReference != presentingAnimeInformation?.reference
            else { return }
        
        // Clear any previous information if needed
        enumeratedInformationList = []
        
        // Initialize the heading view with the provided reference
        headingView.initialize(withReference: reference)
        
        // Request anime information
        listingAnimeRequestTask = reference
            .parentService
            .listingAnime(from: reference)
            .dispatch(on: DispatchQueue.main)
            .error(onError) // Promises manages references pretty nicely, so no need to worry about reference cycle
            .finally(onAnimeInformationDidLoad)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.cancelPerformingTasks()
    }
    
    private func onAnimeInformationDidLoad(_ information: ListingAnimeInformation) {
        // Store information
        presentingAnimeInformation = information
        enumeratedInformationList = information.information.map { $0 }
        
        // Update table view
        tableView.reloadSections(Section.indexSet([
            .information,
            .synopsis
        ]), with: .automatic)
        
        // Update heading view
        headingView.update(with: information)
        
        // Request character list
        characterListRequestTask = information
            .characters
            .error(onError)
            .finally {
                [weak self] characters in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.characterList = characters
                    self.tableView.reloadSections(Section.indexSet(.characters), with: .automatic)
                }
            }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard presentingAnimeInformation != nil else { return 0 }
        
        // Always account for the first header view
        switch Section(rawValue: section)! {
        case .information: return enumeratedInformationList.count + 1
        case .synopsis: return 1
        case .characters: return characterList == nil ? 0 : 2
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let information = presentingAnimeInformation!
        let section = Section(rawValue: indexPath.section)!
        
        // Return synopsis section
        if section == .synopsis {
            let cell = tableView.dequeueReusableCell(withIdentifier: "anime.synopsis", for: indexPath) as! InformationSceneSynopsisTableViewCell
            cell.onLayoutChange = needsLayoutHandler
            cell.information = information
            return cell
        }
        
        // Return header
        if indexPath.item == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "anime.heading", for: indexPath) as! InformationSceneHeadingTableViewCell
            
            // Assign header value
            switch section {
            case .information: cell.headingText = "Information"
            case .characters: cell.headingText = "Characters"
            default: break
            }
            
            return cell
        }
        
        let itemIndex = indexPath.item - 1
        
        switch section {
        case .information:
            let cell = tableView.dequeueReusableCell(withIdentifier: "anime.information", for: indexPath)
            cell.textLabel?.text = enumeratedInformationList[itemIndex].name
            cell.detailTextLabel?.text = enumeratedInformationList[itemIndex].value
            return cell
        case .characters:
            let cell = tableView.dequeueReusableCell(withIdentifier: "anime.characters", for: indexPath) as! InformationSceneCharactersTableViewCell
            cell.initialize(characterList!)
            return cell
        default: fatalError("No section \(section) was found")
        }
    }
}

// MARK: - Exposed interface
extension AnimeInformationTableViewController {
    /// Initialize this `AnimeInformationTableViewController` with
    /// the `ListingAnimeReference`.
    func setPresenting(reference: ListingAnimeReference) {
        self.presentingReference = reference
    }
    
    /// Initialize this `AnimeInformationTableViewController` with
    /// the `AnyLink`.
    ///
    /// Only `.listingReference` link is supported
    func setPresenting(_ link: AnyLink) {
        switch link {
        case .listingReference(let reference): setPresenting(reference: reference)
        default: Log.error("Attempting to initialize a AnimeInformationTableViewController with unsupported link %@", link)
        }
    }
}

// MARK: - Visual effects
extension AnimeInformationTableViewController {
    func adjustNavigationBarStyle() {
        guard let navigationBar = navigationController?.navigationBar,
            let statusBar = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView
            else { return }
        let scrollPosition = max(tableView.contentOffset.y, 0)
        let transitionPosition = headingView.suggestedTransitionHeight
        
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
        navigationBar.barTintColor = .clear
        navigationBar.isTranslucent = true
        
        // If scrolled way pass the position, set the navigation bar to opaque
        let alpha = min(scrollPosition / transitionPosition, 1.0)
        statusBar.backgroundColor = Theme.current.background.withAlphaComponent(alpha)
        navigationBar.backgroundColor = Theme.current.background.withAlphaComponent(alpha)
        navigationBar.tintColor = alpha == 1.0 ? Theme.current.tint : Theme.current.primaryText
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.makeThemable()
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        adjustNavigationBarStyle()
        
        // If the content offset is smaller than 0, tell the heading view
        // to expand the top image
        if scrollView.contentOffset.y < 0 {
            headingView.headingScrollExpansion = scrollView.contentOffset.y
        } else { headingView.headingScrollExpansion = 0 }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Add scroll view insets
        tableView.scrollIndicatorInsets = .init(
            top: navigationController?.navigationBar.frame.height ?? 0,
            left: 0,
            bottom: tabBarController?.tabBar.frame.height ?? 0,
            right: 0
        )
    }
    
    func theme(didUpdate theme: Theme) {
        adjustNavigationBarStyle()
    }
}

// MARK: - Fetch Episodes
extension AnimeInformationTableViewController {
    /// Fetch and display the current anime reference in the
    /// currently selected source
    private func performEpisodeFetching() {
        // Use all available names to make decisions
        guard let information = presentingAnimeInformation else {
            return
        }
        let animeName = information.name
        
        // Hides the view episodes button and starts animating
        // the activity indicator
        fetchEpisodesActivityIndicator.isHidden = false
        fetchEpisodesActivityIndicator.startAnimating()
        showEpisodesButton.isHidden = true
        
        // Perform fetch task
        episodeFetchingTask = AnimeFetchingAgent
            .search(information.name.default)
            .then {
                results -> (Double, AnimeLink)? in
                try some(
                    results.compactMap {
                        anyLink -> (Double, AnimeLink)? in
                        if case .anime(let link) = anyLink {
                            return (animeName.proximity(to: link), link)
                        } else { return nil }
                    } .max { $0.0 < $1.0 },
                    or: .searchError("No matching anime found")
                )
            }
            .error(onError)
            .finally {
                [weak self] match in
                let (confidence, link) = match
                Log.info("Found an anime \"%@\" with %@ confidence", link.title, confidence)
                DispatchQueue.main.async {
                    // If we are highly confident that we got a match, open that link
                    if confidence > 0.95 {
                        self?.onPerfectMatch(link)
                    } else { self?.onUnconfidentMatch() }
                }
            }
    }
    
    @IBAction private func onViewEpisodesButtonTapped(_ sender: Any) {
        // Fetch episodes
        performEpisodeFetching()
    }
    
    private class AnimeFetchingAgent: NineAnimatorAsyncTask, ContentProviderDelegate {
        // Keep a reference to the content provider
        private var contentProviderReference: ContentProvider?
        private weak var referencingPromise: NineAnimatorPromise<[AnyLink]>?
        
        private init(provider: ContentProvider) {
            self.contentProviderReference = provider
            self.contentProviderReference?.delegate = self
        }
        
        func promise() -> NineAnimatorPromise<[AnyLink]> {
            let promise = NineAnimatorPromise<[AnyLink]> {
                _ in
                self.contentProviderReference?.more()
                return self
            }
            self.referencingPromise = promise
            return promise
        }
        
        func cancel() { contentProviderReference = nil }
        
        func pageIncoming(_ page: Int, from provider: ContentProvider) {
            referencingPromise?.resolve(provider.links(on: page))
        }
        
        func onError(_ error: Error, from provider: ContentProvider) {
            referencingPromise?.reject(error)
        }
        
        class func search(_ query: String, on source: Source = NineAnimator.default.user.source) -> NineAnimatorPromise<[AnyLink]> {
            let provider = source.search(keyword: query)
            return AnimeFetchingAgent(provider: provider).promise()
        }
    }
}

// MARK: - Handle errors
extension AnimeInformationTableViewController {
    private func onError(_ error: Error) {
        let alert = UIAlertController(
            title: "Error",
            message: error is NineAnimatorError ? "\(error)" : error.localizedDescription,
            preferredStyle: .alert
        )
        
        // Add OK action
        alert.addAction(UIAlertAction(title: "OK", style: .cancel) {
            [weak self] _ in
            guard let self = self else { return }
            
            // If the anime information has not been loaded yet, back to previous page
            if self.presentingAnimeInformation == nil {
                self.navigationController?.popViewController(animated: true)
            }
        })
        
        // Present alert
        DispatchQueue.main.async {
            [weak self] in self?.present(alert, animated: true)
        }
    }
    
    /// Cleanup the references to tasks
    ///
    /// Not cancelling tasks that will result in contents
    /// presenting in the tableview, only contents that are
    /// not immedietly visible
    private func cancelPerformingTasks() {
        // Resets the episodes fetching button and indicator
        showEpisodesButton.isHidden = false
        fetchEpisodesActivityIndicator.stopAnimating()
        
        // Cancel and remove reference to the episode fetching task
        episodeFetchingTask?.cancel()
        episodeFetchingTask = nil
    }
    
    /// Open the match directly
    private func onPerfectMatch(_ animeLink: AnimeLink) {
        RootViewController.shared?.open(immedietly: .anime(animeLink), in: self)
    }
    
    /// Present options to the user for multiple match
    private func onUnconfidentMatch() {
        guard let reference = presentingReference else { return }
        
        let storyboard = UIStoryboard(name: "AnimeListing", bundle: Bundle.main)
        guard let listingViewController = storyboard.instantiateInitialViewController() as? ContentListViewController else {
            return Log.error("View controller instantiated from AnimeListing.storyboard is not ContentListViewController")
        }
        
        // Initialize the view controller with content provider
        listingViewController.setPresenting(
            contentProvider: NineAnimator.default.user.source.search(keyword: reference.name)
        )
        
        // Present the listing view controller
        if let navigationController = navigationController {
            navigationController.pushViewController(listingViewController, animated: true)
        } else { present(listingViewController, animated: true) }
    }
}

fileprivate extension AnimeInformationTableViewController {
    // Using this enum to remind me to implement stuff when adding new sections...
    fileprivate enum Section: Int, Equatable {
        case synopsis = 0
        
        case characters
        
        case information
        
        subscript(_ item: Int) -> IndexPath {
            return IndexPath(item: item, section: self.rawValue)
        }
        
        static func indexSet(_ sections: [Section]) -> IndexSet {
            return IndexSet(sections.map { $0.rawValue })
        }
        
        static func indexSet(_ sections: Section...) -> IndexSet {
            return IndexSet(sections.map { $0.rawValue })
        }
        
        static func == (_ lhs: Section, _ rhs: Section) -> Bool {
            return lhs.rawValue == rhs.rawValue
        }
        
        static func == (_ lhs: Int, _ rhs: Section) -> Bool {
            return lhs == rhs.rawValue
        }
        
        static func == (_ lhs: Section, _ rhs: Int) -> Bool {
            return lhs.rawValue == rhs
        }
    }
}
