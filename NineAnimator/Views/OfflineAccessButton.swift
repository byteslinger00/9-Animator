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

/// A self-contained view to handle download initiating and monitoring tasks
@IBDesignable
class OfflineAccessButton: UIButton, Themable {
    var offlineAccessState: OfflineState = .preserving(0.5) {
        didSet { updateContent() }
    }
    
    var episodeLink: EpisodeLink? {
        didSet {
            NotificationCenter.default.removeObserver(self)
            guard let link = episodeLink, link != oldValue else { return }
            offlineAccessState = OfflineContentManager.shared.state(for: link)
            setTitle(nil, for: .normal)
            
            // Add observer to listen to update notification
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(onOfflineAccessStateUpdates(_:)),
                name: .offlineAccessStateDidUpdate,
                object: nil
            )
        }
    }
    
    @IBInspectable var insetSpace: CGFloat = 6 {
        didSet { updateContent() }
    }
    
    @IBInspectable var strokeWidth: CGFloat = 2 {
        didSet { updateContent() }
    }
    
    @IBInspectable var centerRectWidth: CGFloat = 8 {
        didSet { updateContent() }
    }
    
    @IBInspectable var centerRectCornerRadius: CGFloat = 2 {
        didSet { updateContent() }
    }
    
    private var preservationInitiatedActivityIndicator: UIActivityIndicatorView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        addTarget(self, action: #selector(onTapped(_:)), for: .touchUpInside)
    }
    
    private func updateContent() {
        switch offlineAccessState {
        case .preservationInitialed:
            // Use an empty image and add activity indicator to it
            setImage(UIImage(), for: .normal)
            preservationInitiatedActivityIndicator?.removeFromSuperview()
            let newIndicator = UIActivityIndicatorView(style: Theme.current.activityIndicatorStyle)
            newIndicator.frame = bounds
            newIndicator.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            newIndicator.hidesWhenStopped = true
            addSubview(newIndicator)
            preservationInitiatedActivityIndicator = newIndicator
            newIndicator.startAnimating()
        case .error, .ready:
            setImage(#imageLiteral(resourceName: "Cloud Download"), for: .normal)
            preservationInitiatedActivityIndicator?.stopAnimating()
            preservationInitiatedActivityIndicator?.removeFromSuperview()
            preservationInitiatedActivityIndicator = nil
        case .preserved:
            setImage(UIImage(), for: .normal)
            preservationInitiatedActivityIndicator?.stopAnimating()
            preservationInitiatedActivityIndicator?.removeFromSuperview()
            preservationInitiatedActivityIndicator = nil
        case .preserving(let progress):
            let size = bounds.size
            let renderer = UIGraphicsImageRenderer(size: size)
            let image = renderer.image {
                _ in
                
                let trackPath = UIBezierPath(
                    arcCenter: CGPoint(x: size.width / 2, y: size.height / 2),
                    radius: size.width / 2 - insetSpace,
                    startAngle: 0,
                    endAngle: 2 * .pi,
                    clockwise: true
                )
                trackPath.lineWidth = strokeWidth
                Theme.current.secondaryText.withAlphaComponent(0.4).setStroke()
                trackPath.stroke()
                
                let progressPath = UIBezierPath(
                    arcCenter: CGPoint(x: size.width / 2, y: size.height / 2),
                    radius: size.width / 2 - insetSpace,
                    startAngle: 3 * .pi / 2,
                    endAngle: (CGFloat(3) * .pi / 2) + (CGFloat(2) * .pi * CGFloat(progress)),
                    clockwise: true
                )
                progressPath.lineWidth = strokeWidth
                Theme.current.tint.setStroke()
                progressPath.stroke()
                
                let centerRect = UIBezierPath(
                    roundedRect: CGRect(
                        x: (size.width / 2) - (centerRectWidth / 2),
                        y: (size.height / 2) - (centerRectWidth / 2),
                        width: centerRectWidth,
                        height: centerRectWidth
                    ),
                    byRoundingCorners: .allCorners,
                    cornerRadii: CGSize(width: centerRectCornerRadius, height: centerRectCornerRadius)
                )
                Theme.current.tint.setFill()
                centerRect.fill()
            }
            setImage(image, for: .normal)
            preservationInitiatedActivityIndicator?.stopAnimating()
            preservationInitiatedActivityIndicator?.removeFromSuperview()
            preservationInitiatedActivityIndicator = nil
        }
    }
    
    // Update UI when received state update notification
    @objc private func onOfflineAccessStateUpdates(_ notification: Notification) {
        guard let episodeLink = episodeLink else { return }
        DispatchQueue.main.async {
            self.offlineAccessState = OfflineContentManager.shared.state(for: episodeLink)
        }
    }
    
    @objc private func onTapped(_ sender: Any) {
        guard let episodeLink = episodeLink else { return }
        
        switch offlineAccessState {
        case .preservationInitialed, .preserving:
            OfflineContentManager.shared.cancelPreservation(for: episodeLink)
        case .error, .ready:
            OfflineContentManager.shared.initiatePreservation(for: episodeLink)
        default: break
        }
    }
    
    func theme(didUpdate theme: Theme) { updateContent() }
    
    deinit { NotificationCenter.default.removeObserver(self) }
}
