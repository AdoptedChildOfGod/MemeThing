//
//  UIViewControllerExtension.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/27/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

extension UIViewController {
    
    // TODO: - find a better place to put this function
    // TODO: - will need to refactor this to take in a game reference
    // TODO: - will need a viewcontroller protocol that has a game property
    func transitionToStoryboard(named: String) {
        let storyboard = UIStoryboard(name: named, bundle: nil)
        guard let initialVC = storyboard.instantiateInitialViewController() else { return }
        initialVC.modalPresentationStyle = .fullScreen
        self.present(initialVC, animated: true)
    }
    
    // Present an alert with a simple dismiss button to display a message to the user
    func presentAlert(title: String, message: String) {
        // Create the alert controller
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Add the dismiss button to the alert
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default))
        
        // Present the alert
        present(alertController, animated: true)
    }
    
    // Present an alert with a text field to get some input from the user
    func presentTextFieldAlert(title: String, message: String, textFieldPlaceholder: String, textFieldText: String? = nil, saveButtonTitle: String = "Save", completion: @escaping (String) -> Void) {
        // Create the alert controller
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Add the text field
        alertController.addTextField { (textField) in
            textField.placeholder = textFieldPlaceholder
            if let textFieldText = textFieldText {
                textField.text = textFieldText
            }
        }
        
        // Create the cancel button
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        // Create the save button
        let saveAction = UIAlertAction(title: saveButtonTitle, style: .default) { (_) in
            // Get the text from the text field
            guard let text = alertController.textFields?.first?.text, !text.isEmpty else { return }
            
            // Pass it to the helper function to handle sending the friend request
            completion(text)
        }
        
        // Add the buttons to the alert and present it
        alertController.addAction(cancelAction)
        alertController.addAction(saveAction)
        present(alertController, animated: true)
    }
    
    // Present an alert at the bottom of the screen to display an error to the user
    func presentErrorToUser(_ localizedError: LocalizedError) {
        // Create the alert controller
        let alertController = UIAlertController(title: "ERROR", message: localizedError.errorDescription, preferredStyle: .actionSheet)
        
        // Add the dismiss button to the alert
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel))
        
        // Present the alert
        present(alertController, animated: true)
    }
}

// TODO: - find a better place to put this
struct StoryboardNames  {
    static let mainMenu = "MainMenu"
    static let drawingView = "Drawing"
    static let captionView = "AddCaption"
    static let resultsView = "ViewResults"
    static let waitingView = "Waiting"
}
