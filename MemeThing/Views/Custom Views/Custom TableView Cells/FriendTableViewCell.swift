//
//  FriendTableViewCell.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/31/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

// MARK: - Button Protocol

protocol FriendTableViewCellButtonDelegate: class {
    func respondToFriendRequest(from cell: FriendTableViewCell, accept: Bool)
}

class FriendTableViewCell: UITableViewCell {
    
    // MARK: - Outlets
    
    @IBOutlet weak var backgroundContainerView: MemeThingTableCellView!
    @IBOutlet weak var photoContainerView: UIView!
    @IBOutlet weak var profilePhotoImageView: ProfileImage!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var pointsLabel: UILabel!
    @IBOutlet weak var buttonStackView: UIStackView!
    @IBOutlet weak var rightConstraint: NSLayoutConstraint!
    
    
    // MARK: - Properties
    
    weak var delegate: FriendTableViewCellButtonDelegate?
    
    // MARK: - Actions
    
    @IBAction func friendRequestButtonTapped(_ sender: UIButton) {
        // Show the loading icon over the cell
        self.contentView.startLoadingIcon()
        
        // Pass the functionality off to the delegate
        delegate?.respondToFriendRequest(from: self, accept: (sender.tag == 1))
    }
    
    // MARK: - Set Up UI
    
    func setUpViews(section: FriendsListViewController.SectionNames, name: String?, points: Int? = nil, photo: UIImage? = nil) {
        nameLabel.textAlignment = .left
        rightConstraint.constant = 0
        photoContainerView.isHidden = true
        
        switch section {
        case .pendingFriendRequests:
            guard let name = name else { return }
            setUpPendingFriendRequestView(for: name)
        case .outgoingFriendRequests:
            guard let name = name else { return }
            setUpOutgoingFriendRequestView(for: name)
        case .friends:
            setUpFriendView(for: name, points: points, photo: photo)
        }
    }
    
    private func setUpPendingFriendRequestView(for name: String) {
        pointsLabel.isHidden = true
        buttonStackView.isHidden = false
        nameLabel.text = "\(name) has sent you a friend request"
    }
    
    private func setUpOutgoingFriendRequestView(for name: String) {
        pointsLabel.isHidden = true
        buttonStackView.isHidden = true
        nameLabel.text = "Waiting for \(name) to respond to your friend request"
    }
    
    private func setUpFriendView(for name: String?, points: Int?, photo: UIImage?) {
        buttonStackView.isHidden = true
        contentView.backgroundColor = .clear
        
        if let photo = photo {
            photoContainerView.isHidden = false
            profilePhotoImageView.image = photo
            profilePhotoImageView.addBorder(width: 2)
        }
        
        if let name = name {
            nameLabel.text = name
            pointsLabel.text = "Points: \(points ?? 0)"
            pointsLabel.textAlignment = .right
            rightConstraint.constant = 6
            pointsLabel.isHidden = false
        } else {
            nameLabel.text = "You have not added any friends yet"
            nameLabel.textAlignment = .center
            pointsLabel.isHidden = true
        }
    }
}
