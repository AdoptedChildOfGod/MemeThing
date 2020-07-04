//
//  LoginViewController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/27/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet weak var signUpToggleButton: UIButton!
    @IBOutlet weak var loginToggleButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var screenNameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var buttonsStackView: UIStackView!
    @IBOutlet weak var textFieldsStackView: UIStackView!
    @IBOutlet weak var stackViewHeightLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var keyboardHeightLayoutConstraint: NSLayoutConstraint!
    
    // MARK: - Properties
    
    var signingUp = true
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Make sure that the user is connected to the internet
        guard Reachability.checkReachable() else {
            presentInternetAlert()
            return
        }
        
        // Try to automatically log the user in
        autoLogin()
        
        // Set up the UI
        setUpViews()
        
        // Add an observer for when the keyboard appears or disappears
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardNotification(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        // Add an observer for if the user denies permission to receive remote notifications
        NotificationCenter.default.addObserver(self, selector: #selector(deniedNotifications), name: notificationsDenied, object: nil)
    }
    
    // MARK: - Respond to Notifications
    
    @objc func deniedNotifications() {
        DispatchQueue.main.async {
            // Present an alert to the user asking them to reconsider allowing notifications
            self.presentAlert(title: "Notifications Will Not Display", message: "MemeThing uses notifications to alert you of new friend requests, invitations to games, and updates to games you're playing. Please consider enabling notifications in your phone's settings for a richer gaming experience.", completion: { self.autoLogin() })
        }
    }
    
    // MARK: - Actions
    
    @IBAction func signUpToggleButtonTapped(_ sender: UIButton) {
        toggleToSignUp()
    }
    
    @IBAction func loginToggleButtonTapped(_ sender: UIButton) {
        toggleToLogin()
    }
    
    @IBAction func doneButtonTapped(_ sender: UIButton) {
        // Make sure there is valid text in the email and password fields
        guard let email = emailTextField.text, !email.isEmpty else {
            presentAlert(title: "Invalid Email", message: "Email cannot be blank")
            return
        }
        guard let password = passwordTextField.text, !password.isEmpty else {
            presentAlert(title: "Invalid Password", message: "Password cannot be blank")
            return
        }
        
        // Either sign up or login
        if signingUp { signUp(with: email, password: password) }
        else { login(with: email, password: password) }
    }
    
    @IBAction func tappedScreen(_ sender: UITapGestureRecognizer) {
        // Close the keyboard for each text field
        screenNameTextField.resignFirstResponder()
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        confirmPasswordTextField.resignFirstResponder()
    }
    
    // MARK: - Set Up UI
    
    func setUpViews() {
        view.backgroundColor = .background
        // TODO: - need to test this in other device sizes
        stackViewHeightLayoutConstraint.constant = buttonsStackView.frame.height + textFieldsStackView.frame.height + 20
        
        screenNameTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self
        confirmPasswordTextField.delegate = self
    }
    
    // Move the text fields out of the way if the keyboard is going to block them
    @objc func keyboardNotification(_ sender: NSNotification) {
        guard let userInfo = sender.userInfo else { return }
        
        let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        let endFrameY = endFrame?.origin.y ?? 0
        let duration:TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
        let animationCurveRawNSN = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
        let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
        let animationCurve:UIView.AnimationOptions = UIView.AnimationOptions(rawValue: animationCurveRaw)
        if endFrameY >= UIScreen.main.bounds.size.height {
            self.keyboardHeightLayoutConstraint?.constant = 0.0
        } else {
            if let endFrame = endFrame {
                // Calculate the correct height to shift the text fields up by
                let currentHeight = (view.frame.height - stackViewHeightLayoutConstraint.constant) / 2
                self.keyboardHeightLayoutConstraint?.constant = -1 * (endFrame.size.height - currentHeight + 10)
            }
        }
        
        UIView.animate(withDuration: duration, delay: TimeInterval(0), options: animationCurve, animations: { self.view.layoutIfNeeded() }, completion: nil)
    }
    
    func toggleToLogin() {
        UIView.animate(withDuration: 0.2) {
            // Toggle which of the buttons is highlighted
            self.loginToggleButton.tintColor = .purpleAccent
            self.loginToggleButton.backgroundColor = .systemGray4
            self.signUpToggleButton.tintColor = .lightGray
            self.signUpToggleButton.backgroundColor = .clear
            
            // Hide all but the necessary text fields
            self.screenNameTextField.isHidden = true
            self.emailTextField.isHidden = true
            self.confirmPasswordTextField.isHidden = true
            self.passwordTextField.returnKeyType = .done
            
            // Change the text of the done button
            self.doneButton.setTitle("Log In", for: .normal)
        }
        signingUp = false
    }
    
    func toggleToSignUp() {
        UIView.animate(withDuration: 0.2) {
            // Toggle which of the buttons is highlighted
            self.loginToggleButton.tintColor = .lightGray
            self.loginToggleButton.backgroundColor = .clear
            self.signUpToggleButton.tintColor = .purpleAccent
            self.signUpToggleButton.backgroundColor = .systemGray4
            
            // Show all the text fields
            self.screenNameTextField.isHidden = false
            self.emailTextField.isHidden = false
            self.confirmPasswordTextField.isHidden = false
            self.passwordTextField.returnKeyType = .next
            
            // Change the text of the done button
            self.doneButton.setTitle("Sign Up", for: .normal)
        }
        signingUp = true
    }
    
    // MARK: - Helper Methods
    
    // Try to log the user in
    func autoLogin() {
        // Show the loading icon
        view.startLoadingIcon()
        
        if let user = Auth.auth().currentUser {
            // If the user's email account has not yet been verified, don't sign in
            guard user.isEmailVerified else { return }
            
            UserController.shared.fetchUser { [weak self] (result) in
                DispatchQueue.main.async {
                    // Hide the loading icon
                    self?.view.stopLoadingIcon()
                    
                    switch result {
                    case .success(_):
                        self?.transitionToStoryboard(named: .MainMenu, direction: .fromRight)
                    case .failure(let error):
                        // Print and display the error
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.presentErrorAlert(error)
                    }
                }
            }
        }
    }
    
    // Present an alert prompting the user to verify their email address
    func presentVerifyEmailAlert(with email: String) {
        // FIXME: - allow user to edit email address
        // FIXME: - refactor to elsewhere
        
        // Create the alert controller
        let alertController = UIAlertController(title: "Verify Email Address", message: "Please check your email \(email) to verify your email address", preferredStyle: .alert)
        
        // Create the button to resend the email
        let resendAction = UIAlertAction(title: "Resend Email", style: .cancel) { [weak self] (_) in
            Auth.auth().currentUser?.sendEmailVerification(completion: { (error) in
                if let error = error {
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    DispatchQueue.main.async { self?.presentErrorAlert(error) }
                }
                
                // Present the same alert telling them to check their email
                self?.presentVerifyEmailAlert(with: email)
            })
        }
        
        // Create the button to continue and check for verification
        let continueAction = UIAlertAction(title: "Log In", style: .default) { [weak self] (_) in
            self?.toggleToLogin()
            self?.emailTextField.text = email
        }
        
        // Add the buttons and present the alert
        alertController.addAction(resendAction)
        alertController.addAction(continueAction)
        present(alertController, animated: true)
    }
    
    // Check that all the fields are valid and create a new user
    func signUp(with email: String, password: String) {
        // Make sure the screen name contains an actual string
        guard screenNameTextField.text == nil || screenNameTextField.text != "" else {
            presentAlert(title: "Invalid Screen Name", message: "Your screen name can't be blank")
            return
        }
        
        // Make sure the passwords match
        guard confirmPasswordTextField.text == password else {
            presentAlert(title: "Passwords Do Not Match", message: "The passwords do not match - make sure to enter passwords carefully")
            return
        }
        
        // Show the loading icon
        view.startLoadingIcon()
        
        // Create the user and send the notification email
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] (authResult, error) in
            
            guard authResult?.user != nil, error == nil else {
                // Print and display the error
                print("Error in \(#function) : \(error!.localizedDescription) \n---\n \(error!)")
                DispatchQueue.main.async {
                    self?.view.stopLoadingIcon()
                    self?.presentErrorAlert(error!)
                }
                return
            }
            
            // Send an email to verify the user's email address
            Auth.auth().currentUser?.sendEmailVerification(completion: { (error) in
                DispatchQueue.main.async {
                    // Hide the loading icon
                    self?.view.stopLoadingIcon()
                    
                    if let error = error {
                        // Print and display the error
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                       self?.presentErrorAlert(error)
                    }
                    
                    // Present an alert asking them to check their email
                    self?.presentVerifyEmailAlert(with: email)
                }
            })
        }
    }
    
    // Once a user has verified their email, finish completing their account
    func setUpUser(with email: String) {
        // FIXME: - maybe create this earlier, so that name originally entered by user is saved as is
        UserController.shared.createUser(with: email, screenName: screenNameTextField.text) { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    // Navigate to the main screen of the app
                    self?.transitionToStoryboard(named: .MainMenu, direction: .fromRight)
                case .failure(let error):
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorAlert(error)
                }
            }
        }
    }
    
    // Check that the username and password are valid and fetch the user
    func login(with email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] (authResult, error) in
            if let error = error {
                // Print and display the error
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                DispatchQueue.main.async { self?.presentErrorAlert(error) }
                return
            }
            
            // Make sure the email is verified
            if Auth.auth().currentUser?.isEmailVerified ?? false {
                // Try to fetch the current user
                UserController.shared.fetchUser { (result) in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(_):
                            // Navigate to the main screen of the app
                            self?.transitionToStoryboard(named: .MainMenu, direction: .fromRight)
                        case .failure(let error):
                            // If the error is that the user doesn't exist yet, then create it
                            if case MemeThingError.noUserFound = error {
                                self?.setUpUser(with: email)
                                return
                            }
                            // Print and display the error
                            print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                            self?.presentErrorAlert(error)
                        }
                    }
                }
            } else {
                // Present the alert asking the user to check their email
                self?.presentVerifyEmailAlert(with: email)
            }
        }
    }
    
    // MARK: - Text Field Controls
    
    // TODO: - make "return" of last text field say "sign up" or "login" as appropriate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if signingUp {
            if let nextField = textField.superview?.viewWithTag(textField.tag + 1) as? UITextField {
                // If there's another text field, move the editing view to that text field
                nextField.becomeFirstResponder()
            } else {
                // Otherwise, remove the keyboard
                textField.resignFirstResponder()
            }
        }
            // Increment different in the login view where there are fewer text fields
        else {
            if let nextField = textField.superview?.viewWithTag(textField.tag + 3) as? UITextField {
                nextField.becomeFirstResponder()
            } else {
                // Otherwise, remove the keyboard
                textField.resignFirstResponder()
            }
        }
        
        return true
    }
}
