//
//  NotificationHelper.swift
//  MemeThing
//
//  Created by Shannon Draeker on 6/2/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import CloudKit

class NotificationHelper {
    
    // MARK: - Define Custom Notification Types
    
    enum Category: String {
        case newFriendRequest = "NEW_FRIEND_REQUEST"
        case removingFriend = "REMOVING_FRIEND"
        case friendRequestResponse = "FRIEND_REQUEST_RESPONSE"
        case newGameInvitation = "NEW_GAME_INVITATION"
        case gameUpdate = "GAME_UPDATE"
//        case gameEnded = "GAME_ENDED"
    }
    
    // MARK: - Process Notifications
    
    // Handle the notification by calling the relevant function to process it
    static func processNotification(withData data: [AnyHashable : Any], completion: @escaping (UInt) -> Void) {
        
        // Parse the notification data to find out what type of notification it is and extract any relevant data
        guard let ckNotification = CKQueryNotification(fromRemoteNotificationDictionary: data),
            let category = ckNotification.category,
            let notificationType = NotificationHelper.Category(rawValue: category),
            let recordIDChanged = ckNotification.recordID
            else { return }
        
        print("got here to \(#function) and category is \(category) and recordID is \(recordIDChanged)")
        
        // Call the relevant helper method based on the type of notification
        switch notificationType {
        case .newFriendRequest:
            print("received new friend request")
            FriendRequestController.shared.receiveFriendRequest(withID: recordIDChanged, completion: completion)
        case .removingFriend:
            print("received request remove friend")
            FriendRequestController.shared.receiveFriendRemoving(withID: recordIDChanged, completion: completion)
        case .friendRequestResponse:
            print("received response to friend request")
            FriendRequestController.shared.receiveResponseToFriendRequest(withID: recordIDChanged, completion: completion)
        case .newGameInvitation:
            print("received new game invitation")
            GameController.shared.receiveInvitationToGame(withID: recordIDChanged, completion: completion)
        case .gameUpdate:
            print("received update to game")
            GameController.shared.receiveUpdateToGame(withID: recordIDChanged, completion: completion)
//        case .gameEnded:
//            print("received notification that game ended")
//            GameController.shared.receiveNotificationGameEnded(withID: recordIDChanged, completion: completion)
        }
    }
    
    // Decide if the notification should be presented to the user
    static func shouldPresentNotification(withData data: [AnyHashable : Any]) -> Bool {
        guard let ckNotification = CKQueryNotification(fromRemoteNotificationDictionary: data),
            let category = ckNotification.category,
            let notificationType = NotificationHelper.Category(rawValue: category)
//            let recordIDChanged = ckNotification.recordID
            else { return false }
        
        // Present all the notifications except for certain updates to the game
        if notificationType != .gameUpdate { return true }
        
        // TODO: - need to fetch the game and look at it to determine what sort of change happened, or else include desired keys in notification?
        return false
    }
}

// MARK: - Local Notification Names

let friendsUpdate = Notification.Name("friendsUpdate")
let closeLeaderboard = Notification.Name("closeLeaderboard")
let updateListOfGames = Notification.Name("updateListOfGames")
let updateWaitingView = Notification.Name("updateWaitingView")
let toCaptionsView = Notification.Name("toCaptionsView")
let toResultsView = Notification.Name("toResultsView")
let toNewRound = Notification.Name("toNewRound")
let toGameOver = Notification.Name("toGameOver")
