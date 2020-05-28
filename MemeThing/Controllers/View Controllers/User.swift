//
//  User.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/27/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import CloudKit

// MARK: - String Constants

struct UserStrings {
    fileprivate static let recordType = "User"
    static let usernameKey = "username"
    fileprivate static let passwordKey = "password"
    fileprivate static let screenNameKey = "screenName"
    fileprivate static let emailKey = "email"
    fileprivate static let pointsKey = "points"
    fileprivate static let numberOfFriends = "numberOfFriends"
    fileprivate static let friendsReferenceKey = "friendsReference"
    static let appleUserReferenceKey = "appleUserReference"
}

class User: CKCompatible {
    
    // MARK: - Properties
    
    // User properties
    let username: String
    var password: String
    var screenName: String
    var email: String
    var points: Int
    var numberOfFriends: Int { friendsReferences.count }
    
    // CloudKit Properties
    var friendsReferences: [CKRecord.Reference]
    let appleUserReference: CKRecord.Reference
    static var recordType: CKRecord.RecordType { UserStrings.recordType }
    var ckRecord: CKRecord { createCKRecord() }
    var recordID: CKRecord.ID
    
    // MARK: - Initializer
    
    init(username: String, password: String, screenName: String?, email: String, points: Int = 0, friendsReferences: [CKRecord.Reference] = [], appleUserReference: CKRecord.Reference, recordID: CKRecord.ID = CKRecord.ID(recordName: UUID().uuidString)) {
        self.username = username
        self.password = password
        if let screenName = screenName {
            self.screenName = screenName
        } else {
            self.screenName = username
        }
        self.email = email
        self.points = points
        self.friendsReferences = friendsReferences
        self.appleUserReference = appleUserReference
        self.recordID = recordID
    }
    
    // MARK: - Convert from CKRecord
    
    required convenience init?(ckRecord: CKRecord) {
        guard let username = ckRecord[UserStrings.usernameKey] as? String,
            let password = ckRecord[UserStrings.passwordKey] as? String,
            let screenName = ckRecord[UserStrings.screenNameKey] as? String,
            let email = ckRecord[UserStrings.emailKey] as? String,
            let points = ckRecord[UserStrings.pointsKey] as? Int,
            let numberOfFriends = ckRecord[UserStrings.numberOfFriends] as? Int,
            let appleUserReference = ckRecord[UserStrings.appleUserReferenceKey] as? CKRecord.Reference
            else { return nil }
        
        var friendsReferences: [CKRecord.Reference] = []
        for i in 0..<numberOfFriends {
            if let friendReference = ckRecord["\(UserStrings.friendsReferenceKey)\(i)"] as? CKRecord.Reference {
                friendsReferences.append(friendReference)
            }
        }
        
        self.init(username: username, password: password, screenName: screenName, email: email, points: points, friendsReferences: friendsReferences, appleUserReference: appleUserReference, recordID: ckRecord.recordID)
    }
    
    // MARK: - Convert to CKRecord
    
    func createCKRecord() -> CKRecord {
        let record = CKRecord(recordType: UserStrings.recordType, recordID: recordID)
        
        record.setValuesForKeys([
            UserStrings.usernameKey : username,
            UserStrings.passwordKey : password,
            UserStrings.screenNameKey : screenName,
            UserStrings.emailKey : email,
            UserStrings.pointsKey : points,
            UserStrings.numberOfFriends : numberOfFriends,
            UserStrings.appleUserReferenceKey : appleUserReference
        ])
        
        for i in 0..<numberOfFriends {
            record.setValue(friendsReferences[i], forKey: "\(UserStrings.friendsReferenceKey)\(i)")
        }
        
        return record
    }
}
