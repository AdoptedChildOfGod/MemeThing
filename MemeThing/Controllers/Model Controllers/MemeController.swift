//
//  MemeController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 6/3/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import CloudKit
import UIKit.UIImage

class MemeController {
    
    // MARK: - Singleton
    
    static let shared = MemeController()
    
    // MARK: - Properties
    
    typealias resultHandler = (Result<Bool, MemeThingError>) -> Void
    typealias resultHandlerWithObject = (Result<Meme, MemeThingError>) -> Void
    
    // MARK: - CRUD Methods
    
    // Create a new meme
    func createMeme(in game: Game, with photo: UIImage, by author: User, completion: @escaping resultHandlerWithObject) {
        // Create the meme
        let meme = Meme(photo: photo, author: author.reference, game: game.reference)
        
        // Save it to the cloud
        CKService.shared.create(object: meme) { (result) in
            switch result {
            case .success(let meme):
                // Return the success
                return completion(.success(meme))
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
    
    // Read (fetch) a meme from a reference
    func fetchMeme(from reference: CKRecord.Reference, completion: @escaping resultHandlerWithObject) {
        CKService.shared.read(reference: reference) { (result: Result<Meme, MemeThingError>) in
            switch result {
            case .success(let meme):
                // Return the success
                return completion(.success(meme))
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
    
    // Update a meme
    private func update(_ meme: Meme, completion: @escaping resultHandler) {
        // Save the updated meme to the cloud
        CKService.shared.update(object: meme) { (result) in
            switch result {
            case .success(_):
                // Return the success
                return completion(.success(true))
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
    
    // Update a meme with a new caption
    func createCaption(for meme: Meme, by author: User, with text: String, in game: Game, completion: @escaping resultHandler) {
        // Create the caption
        let caption = Caption(text: text, author: author.reference, meme: meme.reference, game: game.reference)
        
        // Save it to the cloud
        CKService.shared.create(object: caption) { [weak self] (result) in
            switch result {
            case .success(let caption):
                // Subscribe to notifications for that caption
//                subscribeToNotifications(for: caption) // FIXME: - figure out proper subscriptionID first
                
                // Add the caption to the list of captions on the meme
                if meme.captions != nil {
                    meme.captions!.append(caption.reference)
                } else {
                    meme.captions = [caption.reference]
                }
                
                // FIXME: - refactor this elsewhere
                // Save the change to the meme
                self?.update(meme) { (result) in
                    switch result {
                    case .success(_):
                        // Return the success
                        return completion(.success(true))
                    case .failure(let error):
                        // Print and return the error
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        return completion(.failure(error))
                    }
                }
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
    
    // Update a meme with a winning caption
    func setWinningCaption(to caption: Caption, for meme: Meme, completion: @escaping resultHandler) {
        // Update the caption's status
        caption.didWin = true
        
        // Save the change to the cloud
        CKService.shared.update(object: caption) { [weak self] (result) in
            switch result {
            case .success(let caption):
                // Update the meme with the with the index of the winning caption
                meme.winningCaptionIndex = meme.captions?.firstIndex(of: caption.reference)
                self?.update(meme, completion: { (result) in
                    switch result {
                    case .success(_):
                        // Return the success
                        return completion(.success(true))
                    case .failure(let error):
                        // Print and return the error
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        return completion(.failure(error))
                    }
                })
            case .failure(let error):
                // Print and return the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                return completion(.failure(error))
            }
        }
    }
    
    // MARK: - Notifications
    
    // Subscribe to notifications for captions you created, in case you won
    // TODO: - use a completion?
    func subscribeToNotifications(for caption: Caption) {
        // Set up the subscription to be alerted of any modification to the caption
        let predicate = NSPredicate(format: "recordID == %@", caption.recordID)
        let subscription = CKQuerySubscription(recordType: CaptionStrings.recordType, predicate: predicate, subscriptionID: caption.recordID.recordName, options: [CKQuerySubscription.Options.firesOnRecordUpdate])
        // FIXME: - proper subscriptionID to use? figure out where to delete
        
        // Configure the display of the notifications
        let notificationInfo = CKQuerySubscription.NotificationInfo()
        notificationInfo.title = "Winner"
        notificationInfo.alertBody = "Your caption won a round in MemeThing!"
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.desiredKeys = [CaptionStrings.gameKey]
        notificationInfo.category = NotificationHelper.Category.captionWon.rawValue
        subscription.notificationInfo = notificationInfo
        
        // Save the subscription to the cloud
        CKService.shared.publicDB.save(subscription) { (sub, error) in
//            print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
//            // TODO: - delete this fluff later
        }
    }
    
    // Receive a notification that the current user's caption has won
    func receiveNotificationCaptionWon(inGame game: CKRecord.Reference) {
        guard let currentUser = UserController.shared.currentUser else { return }

        // Update the user's points and save the change
        UserController.shared.update(currentUser, points: 1) { (result) in
            switch result {
            case .success(_):
                // TODO: - better handling in here
                print("worked")
            case .failure(let error):
                // TODO: - better error handling
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
            }
        }
        
        // FIXME: - get rid of this part
        // if game updates points in itself on the lead player's side when a winner is chosen, then can delete all this, including game reference in caption object
        
        // Fetch the game object from the passed reference
        GameController.shared.fetchGame(from: game.recordID) { (result) in
            switch result {
            case .success(let game):
                // Update the game with the user's points and save the change
                game.updatePoints(of: currentUser)
                GameController.shared.update(game) { (result) in }
            case .failure(let error):
                // TODO: - better error handling
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
            }
        }

    }
    
    // TODO: - remove subscriptions to captions after receiving a response or when the game is over
}
