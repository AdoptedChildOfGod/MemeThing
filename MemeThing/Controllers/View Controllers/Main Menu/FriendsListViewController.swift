//
//  FriendsListViewController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/27/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class FriendsListViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var friendsTableView: UITableView!
    
    // MARK: - Properties
    
    var refresh = UIRefreshControl()
    
    enum SectionNames: String {
        case pendingFriendRequests = "Pending Friend Requests"
        case outgoingFriendRequests = "Outgoing Friend Requests"
        case friends = "Friends"
    }
    
    var dataSource: [(name: SectionNames, data: [Any])] {
        var arrays = [(SectionNames, [Any])]()
        if let pendingFriendRequests = FriendRequestController.shared.pendingFriendRequests {
            if pendingFriendRequests.count > 0 {
                arrays.append((.pendingFriendRequests, pendingFriendRequests))
            }
        }
        if let outgoingFriendRequests = FriendRequestController.shared.outgoingFriendRequests {
            if outgoingFriendRequests.count > 0 {
                arrays.append((.outgoingFriendRequests, outgoingFriendRequests))
            }
        }
        if var userFriends = UserController.shared.usersFriends {
            userFriends = userFriends.sorted { $1.screenName > $0.screenName }
            arrays.append((.friends, userFriends))
        }
        return arrays
    }
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the UI
        setUpViews()
        
        // Load all the data, if it hasn't been loaded already
        loadAllData()
        
        // Set up the observer to listen for notifications telling the view to reload its data
        NotificationCenter.default.addObserver(self, selector: #selector(updateData), name: .friendsUpdate, object: nil)
        
        // Set up the observers to listen for responses to push notifications
        setUpObservers()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .friendsUpdate, object: nil)
        removeObservers()
    }
    
    // MARK: - Helper Methods
    
    @objc func updateData() {
        DispatchQueue.main.async { self.friendsTableView.reloadData() }
    }
    
    @objc func refreshData() {
        // Check for new pending friend requests
        FriendRequestController.shared.fetchPendingFriendRequests { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    self?.refresh.endRefreshing()
                case .failure(let error):
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorAlert(error)
                }
            }
        }
    }
    
    func setUpViews() {
        friendsTableView.delegate = self
        friendsTableView.dataSource = self
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        friendsTableView.tableFooterView = UIView()
        //friendsTableView.backgroundColor = .background
        
        // Set up the refresh icon to check for updates whenever the user pulls down on the tableview
        refresh.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        friendsTableView.addSubview(refresh)
        
        //Beth added:
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.view.bounds
        gradientLayer.colors = [UIColor.cyan.cgColor, UIColor.blue.cgColor]
        self.view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    func loadAllData() {
        let group = DispatchGroup()
        
        if FriendRequestController.shared.pendingFriendRequests == nil {
            group.enter()
            FriendRequestController.shared.fetchPendingFriendRequests { [weak self] (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        print("Successfully fetched pending friend requests")
                    case .failure(let error):
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.presentErrorAlert(error)
                    }
                }
                group.leave()
            }
        }
        if FriendRequestController.shared.outgoingFriendRequests == nil {
            group.enter()
            FriendRequestController.shared.fetchOutgoingFriendRequests { [weak self] (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        print("Successfully fetched outgoing friend requests")
                    case .failure(let error):
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.presentErrorAlert(error)
                    }
                }
                group.leave()
            }
        }
        if UserController.shared.usersFriends == nil {
            group.enter()
            UserController.shared.fetchUsersFriends { [weak self] (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        print("Successfully fetched current friends")
                    case .failure(let error):
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.presentErrorAlert(error)
                    }
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) { self.friendsTableView.reloadData() }
    }
    
    func blockUser(with ID: String, name: String) {
        guard let currentUser = UserController.shared.currentUser else { return }
        
        // Add the username to the current user's list of blocked people and save the change to the cloud
        UserController.shared.update(currentUser, IDToBlock: ID) { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    self?.presentAlert(title: "Successfully Blocked", message: "You have successfully blocked \(name)")
                case .failure(let error):
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorAlert(error)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func addButtonTapped(_ sender: UIBarButtonItem) {
        // Make sure the user is connected to the internet
        guard Reachability.checkReachable() else {
            presentInternetAlert()
            return
        }
        
        // Present the text field for the user to enter the desired username to friend
        presentTextFieldAlert(title: "Add Friend", message: "Connect with your friends!", textFieldPlaceholder: "Enter email here...", saveButtonTitle: "Send", completion: sendRequest(to:))
    }
    
    // A helper function for when the user clicks to add the friend
    func sendRequest(to email: String) {
        guard let currentUser = UserController.shared.currentUser,
            email != currentUser.email else {
                presentAlert(title: "Invalid Email", message: "You can't send a friend request to yourself")
                return
        }
        
        // Search to see if that email exists as a user of the app
        UserController.shared.searchFor(email) { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let friend):
                    
                    // Make sure that the current user hasn't been blocked by that person
                    guard !friend.blockedIDs.contains(currentUser.recordID) else {
                        self?.presentAlert(title: "Blocked", message: "You have been blocked by \(email)")
                        return
                    }
                    
                    // Make sure the user hasn't already blocked, sent, received, or accepted a request from that person
                    if currentUser.blockedIDs.contains(friend.recordID) {
                        self?.presentAlert(title: "Blocked", message: "You have blocked \(email)")
                        return
                    }
                    if let outgoingFriendRequests = FriendRequestController.shared.outgoingFriendRequests {
                        guard outgoingFriendRequests.filter({ $0.toID == friend.recordID }).count == 0 else {
                            self?.presentAlert(title: "Already Sent", message: "You have already sent a friend request to \(email)")
                            return
                        }
                    }
                    if let pendingFriendRequests = FriendRequestController.shared.pendingFriendRequests {
                        guard pendingFriendRequests.filter({ $0.fromID == friend.recordID }).count == 0 else {
                            self?.presentAlert(title: "Already Received", message: "You have already received a friend request from \(email)")
                            return
                        }
                    }
                    if let userFriends = UserController.shared.usersFriends {
                        guard userFriends.filter({ $0.email == email }).count == 0 else {
                            self?.presentAlert(title: "Already Friends", message: "You are already friends with \(email)")
                            return
                        }
                    }
                    
                    // Send them a friend request
                    FriendRequestController.shared.sendFriendRequest(to: friend) { (result) in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(_):
                                // Display an alert showing the success, and refresh the tableview to show the pending friend request
                                self?.presentAlert(title: "Friend Request Sent", message: "A friend request has been sent to \(friend.email)")
                                self?.friendsTableView.reloadData()
                            case .failure(let error):
                                // Print and display the error
                                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                                self?.presentErrorAlert(error)
                            }
                        }
                    }
                case .failure(let error):
                    // Otherwise, show an alert to the user that the username doesn't exist
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentAlert(title: "Email Not Found", message: "The email \(email) is not a user of MemeThing - make sure to enter the email carefully.")
                }
            }
        }
    }
}

// MARK: - Tableview Methods

extension FriendsListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return dataSource[section].name.rawValue
    }
    
    //Beth added:
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60.0
    }
    
    //Beth added:
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int){
        view.tintColor = UIColor.clear
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.textColor = UIColor.purpleAccent
        header.textLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        //header.textLabel?.frame = header.frame
        //header.textLabel?.textAlignment = .center
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Add a placeholder row if the user has no friends
        if dataSource[section].name == .friends && dataSource[section].data.count == 0 { return 1 }
        return dataSource[section].data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "friendCell", for: indexPath) as? FriendTableViewCell else { return UITableViewCell() }
        cell.delegate = self
        
        let sectionName = dataSource[indexPath.section].name
        let data = dataSource[indexPath.section].data
        
        switch sectionName {
        case .pendingFriendRequests:
            guard let friendRequest = data[indexPath.row] as? FriendRequest else { return cell }
            cell.setUpViews(section: sectionName, name: friendRequest.fromName)
        case .outgoingFriendRequests:
            guard let friendRequest = data[indexPath.row] as? FriendRequest else { return cell }
            cell.setUpViews(section: sectionName, name: friendRequest.toName)
        case .friends:
            // Add a placeholder row if the user has no friends
            if data.count == 0 { cell.setUpViews(section: sectionName, name: nil) }
            else {
                guard let friend = data[indexPath.row] as? User else { return cell }
                cell.setUpViews(section: sectionName, name: friend.screenName, points: friend.points, photo: friend.photo)
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Enable swipe-to-delete functionality only for friends, not friend requests
        if dataSource[indexPath.section].name == .friends && dataSource[indexPath.section].data.count > 0 { return true }
        return false
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Get the reference to the friend
            guard let friend = dataSource[indexPath.section].data[indexPath.row] as? User else { return }
            
            // Present an alert to confirm the user really wants to remove the friend
            presentConfirmAlert(title: "Are you sure?", message: "Are you sure you want to unfriend \(friend.screenName)?") {
                
                // Don't allow the user to interact with the view while the change is being processed
                tableView.isUserInteractionEnabled = false
                
                // If the user clicks "confirm," remove the friend and update the tableview
                FriendRequestController.shared.sendRequestToRemove(friend) { [weak self] (result) in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(_):
                            // Give the user an opportunity to block the unwanted friend
                            self?.presentConfirmAlert(title: "Friend Removed", message: "Do you want to block \(friend.screenName) from sending you any more friend requests?", cancelText: "No", confirmText: "Yes, block \(friend.screenName)", completion: {
                                
                                // If the user clicks "confirm," add that user to their blocked list
                                self?.blockUser(with: friend.recordID, name: friend.screenName)
                            })
                            print("got here to \(#function) and \(String(describing: self?.dataSource))")
                            // Update the tableview
                            self?.updateData()
                        case .failure(let error):
                            // Print and present the error
                            print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                            self?.presentErrorAlert(error)
                        }
                        // Turn user interaction back on
                        self?.friendsTableView.isUserInteractionEnabled = true
                    }
                }
            }
        }
    }
}

// MARK: - TableViewCell Button Delegate

extension FriendsListViewController: FriendTableViewCellButtonDelegate {
    
    func respondToFriendRequest(from cell: FriendTableViewCell, accept: Bool) {
        // Make sure the user is connected to the internet
        guard Reachability.checkReachable() else {
            presentInternetAlert()
            return
        }
        
        // Get the reference to the friend request that was responded to
        guard let indexPath = friendsTableView.indexPath(for: cell),
            dataSource[indexPath.section].name == .pendingFriendRequests,
            let friendRequest = dataSource[indexPath.section].data[indexPath.row] as? FriendRequest
            else { return }
        
        // Respond to the friend request
        FriendRequestController.shared.respondToFriendRequest(friendRequest, accept: accept) { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    // Show an alert that the friend request has been accepted
                    if accept {
                        self?.presentAlert(title: "Friend Added", message: "You have successfully added \(friendRequest.fromName) as a friend!")
                    } else {
                        // Give the user an opportunity to block the unwanted friend request
                        self?.presentConfirmAlert(title: "Friend Request Denied", message: "Do you want to block \(friendRequest.fromName) from sending you any more friend requests?", cancelText: "No", confirmText: "Yes, block", completion: {
                            
                            // If the user clicks "confirm," add that user to their blocked list
                            self?.blockUser(with: friendRequest.fromID, name: friendRequest.fromName)
                        })
                    }
                    
                    // Refresh the tableview to reflect the changes
                    cell.contentView.stopLoadingIcon()
                    self?.friendsTableView.reloadData()
                case .failure(let error):
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorAlert(error)
                    cell.contentView.stopLoadingIcon()
                }
            }
        }
    }
}
