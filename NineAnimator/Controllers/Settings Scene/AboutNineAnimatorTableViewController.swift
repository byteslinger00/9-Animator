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

import AppCenterAnalytics
import SafariServices
import UIKit

class AboutNineAnimatorTableViewController: UITableViewController {
    private let urlForIdentifier: [String?: String] = [
        // View GitHub Repository
        "about.viewrepo": "https://github.com/SuperMarcus/NineAnimator",
        // Report issue
        "about.issue": "https://github.com/SuperMarcus/NineAnimator/issues/new/choose",
        // View License
        "about.license": "https://github.com/SuperMarcus/NineAnimator/blob/master/LICENSE",
        "about.credits": "https://nineanimator.marcuszhou.com/docs/credits.html",
        "about.privacy.policy": "https://nineanimator.marcuszhou.com/docs/privacy-policy.html"
    ]
    
    private let discordInvitationUrl = URL(string: "https://discord.gg/dzTVzeW")!
    private var aboutTappingCounter = 0
    private var buildTappingCounter = 0
    
    @IBOutlet private weak var versionLabel: UILabel!
    @IBOutlet private weak var buildNumberLabel: UILabel!
    @IBOutlet private weak var optOutAnalyticsSwitch: UISwitch!
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer { tableView.deselectSelectedRows() }
        
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        
        if let url = urlForIdentifier[cell.reuseIdentifier] {
            let safariViewController = SFSafariViewController(url: URL(string: url)!)
            present(safariViewController, animated: true)
        } else { // "about.privacy"
            switch cell.reuseIdentifier {
            case "about.privacy":
                // Manage persisted data (on the previous page)
                navigationController?.popViewController(animated: true)
            case "about.discord":
                // Open discord invitation url
                UIApplication.shared.open(discordInvitationUrl)
            case "about.version":
                aboutTappingCounter += 1
                if aboutTappingCounter >= 10 {
                    aboutTappingCounter = 5
                    doMagic()
                }
            case "about.build":
                buildTappingCounter += 1
                if buildTappingCounter >= 3 {
                    buildTappingCounter = 0
                    exportLogs(source: cell)
                }
            default:
                Log.error("[AboutNineAnimatorTableViewController] Unknwon cell with identitier %@ selected.", cell.reuseIdentifier ?? "<Unknown>")
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.makeThemable()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.makeThemable()
        configureForTransparentScrollEdge()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUIComponents()
    }
    
    private func doMagic() {
        _ = SettingsAppIconController.makeAvailable("Fox", from: self, allowsSettingsPopup: false)
    }
    
    private func exportLogs(source: UIView) {
        let alertController = UIAlertController(
            title: "Export Runtime Logs",
            message: "Export NineAnimator runtime logs for debugging. You may choose to export a redacted version for sharing with the developers. Redacted runtime logs remove all dynamic information such as anime title, episode name, playback progresses, etc.",
            preferredStyle: .actionSheet
        )
        
        alertController.addAction(UIAlertAction(title: "Redacted Version", style: .default) {
            [weak self, weak source] _ in DispatchQueue.main.async {
                if let self = self, let source = source {
                    self.exportLogsForReal(source: source, exportOptions: [ .redactParameters ])
                }
            }
        })
        
        alertController.addAction(UIAlertAction(title: "Full Version", style: .default) {
            [weak self, weak source] _ in DispatchQueue.main.async {
                if let self = self, let source = source {
                    self.exportLogsForReal(source: source, exportOptions: [])
                }
            }
        })
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = source
            popoverController.sourceRect = source.bounds
        }
        
        self.present(alertController, animated: true)
    }
    
    private func exportLogsForReal(source: UIView, exportOptions: NineAnimatorLogger.ExportPrivacyOption) {
        do {
            let exportedFileURL = try Log.exportRuntimeLogs(privacyOptions: exportOptions)
            RootViewController.shared?.presentShareSheet(
                forURL: exportedFileURL,
                from: source,
                inViewController: self
            )
        } catch {
            let alertController = UIAlertController(error: error)
            self.present(alertController, animated: true)
        }
    }
    
    private func updateUIComponents() {
        // Update version information
        versionLabel.text = NineAnimator.default.version
        buildNumberLabel.text = "\(NineAnimator.default.buildNumber)"
        optOutAnalyticsSwitch.setOn(NineAnimator.default.user.optOutAnalytics, animated: true)
    }
    
    @IBAction private func didToggleOptOutAnalyticsSwitch(_ sender: UISwitch) {
        NineAnimator.default.user.optOutAnalytics = sender.isOn
        Analytics.enabled = !sender.isOn
    }
}
