//
//  DrawingViewController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/28/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class DrawingViewController: UIViewController, HasAGameObject {
    
    // MARK: - Outlets
    
    @IBOutlet weak var canvasView: CanvasView!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    // MARK: - Properties
    
    var gameID: String?
    var game: Game? { GameController.shared.currentGames?.first(where: { $0.recordID.recordName == gameID }) }
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .background
        loadingIndicator.isHidden = true
        
        // Set up the observer to transition to the game over view in case the game ends prematurely
        NotificationCenter.default.addObserver(self, selector: #selector(transitionToNewPage(_:)), name: toGameOver, object: nil)
    }
    
    // MARK: - Respond to Notifications
    
    @objc func transitionToNewPage(_ sender: NSNotification) {
        print("got here to \(#function) in drawingview and \(sender.name)")
        // Only change the view if the update is for the game that the user currently has open
        guard let game  = game, let gameID = sender.userInfo?["gameID"] as? String,
            gameID == game.recordID.recordName else { return }
        
        // Transition to the relevant view based on the type of update
        DispatchQueue.main.async {
            if sender.name == toGameOver {
                print("should be going to game over view now")
                self.transitionToStoryboard(named: StoryboardNames.gameOverView, with: game.recordID.recordName)
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func mainMenuButtonTapped(_ sender: UIBarButtonItem) {
        transitionToStoryboard(named: StoryboardNames.mainMenu)
    }
    
    @IBAction func dotsButtonTapped(_ sender: UIBarButtonItem) {
        guard let game = game else { return }
        presentPopoverStoryboard(named: StoryboardNames.leaderboardView, with: game.recordID.recordName)
    }
    
    @IBAction func undoButtonTapped(_ sender: UIButton) {
        canvasView.undoDraw()
    }
    
    @IBAction func sendButtonTapped(_ sender: UIButton) {
        guard let game = game, let currentUser = UserController.shared.currentUser else { return }
        
        // Create the image from the canvas (hide the undo button first so that it isn't saved in the screenshot)
        undoButton.isHidden = true
        let image = canvasView.getImage()
        
        // Display the loading icon while the image saves
        loadingIndicator.startAnimating()
        loadingIndicator.isHidden = false
        
        // Don't allow the user to continue drawing or resubmit the drawing while the image saves
        canvasView.isUserInteractionEnabled = false
        sendButton.deactivate()
        
        // Create the meme object and save it to the cloud
        MemeController.shared.createMeme(in: game, with: image, by: currentUser) { [weak self] (result) in
            switch result {
            case .success(let meme):
                // Add the meme to the game
                if var memes = game.memes {
                    memes.append(meme.reference)
                    game.memes = memes
                } else {
                    game.memes = [meme.reference]
                }
                
                // Update the game's status
                game.gameStatus = .waitingForCaptions
                // FIXME: - Make sure this change is reflected in the game in the SoT too
                
                // Update the player's status
                game.updateStatus(of: currentUser, to: .sentDrawing)
                
                // Save the game to the cloud
                // TODO: - better way than nested completions??
                GameController.shared.saveChanges(to: game) { (result) in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(_):
                            // Transition back to the waiting view until all the captions have been submitted
                            self?.transitionToStoryboard(named: StoryboardNames.waitingView, with: game.recordID.recordName)
                        case .failure(let error):
                            // Print and display the error
                            print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                            self?.presentErrorAlert(error)
                            
                            // Reset the UI
                            // FIXME: - refactor to helper method
                            self?.loadingIndicator.stopAnimating()
                            self?.undoButton.isHidden = false
                            self?.canvasView.isUserInteractionEnabled = true
                            self?.sendButton.activate()
                        }
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorAlert(error)
                    
                    // Reset the UI
                    // FIXME: - refactor to helper method
                    self?.loadingIndicator.stopAnimating()
                    self?.undoButton.isHidden = false
                    self?.canvasView.isUserInteractionEnabled = true
                    self?.sendButton.activate()
                }
            }
        }
    }
}
