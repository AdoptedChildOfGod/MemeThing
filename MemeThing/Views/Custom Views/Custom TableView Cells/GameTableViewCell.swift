//
//  GameTableViewCell.swift
//  MemeThing
//
//  Created by Shannon Draeker on 6/4/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

// MARK: - Button Protocol

protocol GameTableViewCellDelegate: class {
    func respondToGameInvitation(for cell: GameTableViewCell, accept: Bool)
}

class GameTableViewCell: UITableViewCell {
    
    // MARK: - Outlets
    
    @IBOutlet weak var mainTextLabel: UILabel!
    @IBOutlet weak var secondaryTextLabel: UILabel!
    @IBOutlet weak var buttonStackView: UIStackView!
    
    // MARK: - Properties
    
    weak var delegate: GameTableViewCellDelegate?
    
    // MARK: - Actions
    
    @IBAction func invitationResponseButtonTapped(_ sender: UIButton) {
        delegate?.respondToGameInvitation(for: self, accept: (sender.tag == 1))
    }
    
    // MARK: - Set Up UI
    
    func setUpViews(in section: GamesListTableViewController.SectionName, with game: Game?) {
        switch section {
        case .pendingInvitations:
            guard let game = game else { return }
            setUpPendingInvitationView(for: game)
        case .waitingForResponses:
            guard let game = game else { return }
            setUpWaitingForResponseView(for: game)
        case .games:
            setUpActiveGameView(for: game)
        }
    }
    
    private func setUpPendingInvitationView(for game: Game) {
        secondaryTextLabel.isHidden = true
        mainTextLabel.text = "\(game.playersNames[0]) has invited you to a game with \(game.listOfPlayerNames)"
        contentView.backgroundColor = .systemGreen
    }
    
    private func setUpWaitingForResponseView(for game: Game) {
        secondaryTextLabel.isHidden = true
        buttonStackView.isHidden = true
        mainTextLabel.text = "You have sent a game invitation to \(game.listOfPlayerNames)"
        contentView.backgroundColor = .systemRed
    }
    
    private func setUpActiveGameView(for game: Game?) {
        buttonStackView.isHidden = true
        if let game = game {
            mainTextLabel.text = "You are playing a game with \(game.listOfPlayerNames)"
            secondaryTextLabel.text = game.gameStatusDescription
        } else {
            secondaryTextLabel.isHidden = true
            mainTextLabel.text = "You are not currently playing any games"
        }
    }
}
