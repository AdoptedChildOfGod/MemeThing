//
//  InviteFriendsTableViewController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 6/2/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class InviteFriendsTableViewController: UITableViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var startGameButton: UIButton!
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(false, animated: true)
        tableView.backgroundColor = .background
        
        // Load the data if it hasn't been loaded already
        loadData()
        
        // Start off with the button disabled until enough players have been selected for the game
        toggleStartButtonEnabled(to: false)
    }
    
    // MARK: - Helper Methods
    
    func loadData() {
        if UserController.shared.usersFriends == nil {
            UserController.shared.fetchUsersFriends { [weak self] (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        self?.tableView.reloadData()
                    case .failure(let error):
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.presentErrorToUser(error)
                    }
                }
            }
        }
    }
    
    func toggleStartButtonEnabled(to enabled: Bool) {
        startGameButton.isEnabled = enabled
        UIView.animate(withDuration: 0.1) {
            self.startGameButton.backgroundColor = UIColor.greenAccent.withAlphaComponent(enabled ? 1 : 0.5)
        }
    }
    
    // MARK: - Actions
    
    @IBAction func startGameButtonTapped(_ sender: UIButton) {
        // Get the list of selected players
        // TODO: - display an alert if user hasn't selected anything?
        guard let indexPaths = tableView.indexPathsForSelectedRows else { return }
        let friends = indexPaths.compactMap { UserController.shared.usersFriends?[$0.row] }

        // Create the game object, thus saving it to the cloud and automatically alerting the selected players
        GameController.shared.newGame(players: friends) { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let game):
                    // Transition to the waiting view, passing along the reference to the current game
                    print("got here to \(#function) and seems to have created the game successfully")
                    print("SoT is now \(String(describing: GameController.shared.currentGames?.compactMap({$0.debugging})))")
                    self?.transitionToStoryboard(named: StoryboardNames.waitingView, with: game)
                case .failure(let error):
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorToUser(error)
                }
            }
        }
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return UserController.shared.usersFriends?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "friendCell", for: indexPath) as? ThreeLabelsTableViewCell else { return UITableViewCell() }
        
        // Fill in the details of the cell with the friend's information
        if let friends = UserController.shared.usersFriends, friends.count > 0 {
            let friend = friends[indexPath.row]
            cell.setUpUI(firstText: friend.screenName, secondText: "Points: \(friend.points)")
        }
            // Insert a filler row if the user has not added any friends yet
        else { cell.setUpUI(firstText: "You have not added any friends yet") }
        
        return cell
    }
    
    // FIXME: - comment, prettify
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let indexPaths = tableView.indexPathsForSelectedRows, indexPaths.count > 0 { // FIXME: - change to one after done testing
            toggleStartButtonEnabled(to: true)
        }
        else { toggleStartButtonEnabled(to: false) }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let indexPaths = tableView.indexPathsForSelectedRows, indexPaths.count > 0 { // FIXME: - change to one after done testing
            toggleStartButtonEnabled(to: true)
        }
        else { toggleStartButtonEnabled(to: false) }
    }
}
