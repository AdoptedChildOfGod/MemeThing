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
        case friendRequestResponse = "FRIEND_REQUEST_RESPONSE"
        case newGameInvitation = "NEW_GAME_INVITATION"
        case gameUpdate = "GAME_UPDATE"
        case gameEnded = "GAME_ENDED"
    }
    
    // MARK: - Process Notifications
    
    static func processNotification(withData data: [AnyHashable : Any]) {
        
        // Parse the notification data to find out what type of notification it is and extract any relevant data
        guard let ckNotification = CKQueryNotification(fromRemoteNotificationDictionary: data),
            let category = ckNotification.category,
            let notificationType = NotificationHelper.Category(rawValue: category),
            let recordIDChanged = ckNotification.recordID
//            let recordFields = ckNotification.recordFields // TODO: - uncomment this if using desiredKeys in notifications
            else { return }
        
        print("got here to \(#function) and category is \(category) and recordID is \(recordIDChanged)")
        
        switch notificationType {
        case .newFriendRequest:
            print("received new friend request")
            // TODO: - display an alert if app is open?
            FriendRequestController.shared.receiveFriendRequest(withID: recordIDChanged)
        case .friendRequestResponse:
            print("received response to friend request")
            // TODO: - display an alert if app is open?
            // TODO: - have an alert waiting next time app is opened?
            FriendRequestController.shared.receiveResponseToFriendRequest(withID: recordIDChanged)
        case .newGameInvitation:
            print("received new game invitation")
            // TODO: - display an alert if app is open?
            // TODO: - have an alert waiting next time app is opened?
            GameController.shared.receiveInvitationToGame(withID: recordIDChanged)
        case .gameUpdate:
            print("received update to game")
            // TODO: - display an alert if app is open?
            // TODO: - have an alert waiting next time app is opened?
            GameController.shared.receiveUpdateToGame(withID: recordIDChanged)
        case .gameEnded:
            print("received notification that game ended")
            GameController.shared.receiveNotificationGameEnded(withID: recordIDChanged)
        }
    }
}

// MARK: - Local Notification Names

let friendsUpdate = Notification.Name("friendsUpdate")
let newGameInvitation = Notification.Name("newGameInvitation")
let gameUpdate = Notification.Name("gameUpdate")
