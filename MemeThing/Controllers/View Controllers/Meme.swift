//
//  Meme.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/29/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import CloudKit
import UIKit.UIImage

// MARK: - String Constants

struct MemeStrings {
    fileprivate static let recordType = "Meme"
    fileprivate static let photoKey = "photo"
    fileprivate static let authorKey = "author"
    fileprivate static let winningCaptionKey = "winningCaptionKey"
    fileprivate static let gameKey = "game"
}

class Meme: CKCompatible, CKPhotoAsset {

    // MARK: - Properties
    
    // Meme properties
    var photo: UIImage?
    let author: CKRecord.Reference
    var winningCaption: CKRecord.Reference?
    var game: CKRecord.Reference
    
    // CloudKit properties
    var reference: CKRecord.Reference { CKRecord.Reference(recordID: recordID, action: .deleteSelf) }
    static var recordType: CKRecord.RecordType { MemeStrings.recordType }
    var ckRecord: CKRecord { createCKRecord() }
    var recordID: CKRecord.ID
    
    // MARK: - Initializer
    
    init(photo: UIImage, author: CKRecord.Reference, winningCaption: CKRecord.Reference? = nil, game: CKRecord.Reference, recordID: CKRecord.ID = CKRecord.ID(recordName: UUID().uuidString)) {
        self.photo = photo
        self.author = author
        self.winningCaption = winningCaption
        self.game = game
        self.recordID = recordID
    }
    
    // MARK: - Convert from CKRecord
    
    required convenience init?(ckRecord: CKRecord) {
        guard let author = ckRecord[MemeStrings.authorKey] as? CKRecord.Reference,
            let game = ckRecord[MemeStrings.gameKey] as? CKRecord.Reference
            else { return nil }
        let winningCaption = ckRecord[MemeStrings.winningCaptionKey] as? CKRecord.Reference
        
        var photo: UIImage?
        if let photoAsset = ckRecord[MemeStrings.photoKey] as? CKAsset {
            do {
                let data = try Data(contentsOf: photoAsset.fileURL!)
                photo = UIImage(data: data)
            } catch {
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
            }
        }
        guard let unwrappedPhoto = photo else { return nil }
        
        self.init(photo: unwrappedPhoto, author: author, winningCaption: winningCaption, game: game, recordID: ckRecord.recordID)
    }
    
    // MARK: - Convert to CKRecord
    
    func createCKRecord() -> CKRecord {
        let record = CKRecord(recordType: MemeStrings.recordType, recordID: recordID)
        
        if let photoAsset = photoAsset { record.setValue(photoAsset, forKey: MemeStrings.photoKey) }
        record.setValue(author, forKey: MemeStrings.authorKey)
        if let winningCaption = winningCaption { record.setValue(winningCaption, forKey: MemeStrings.winningCaptionKey) }
        record.setValue(game, forKey: MemeStrings.gameKey)
        
        return record
    }
}
