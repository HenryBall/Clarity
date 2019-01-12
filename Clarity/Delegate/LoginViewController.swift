//
//  LoginViewController.swift
//  Clarity
//
//  Created by Celine Pena on 5/14/18.
//  Copyright © 2018 Robert. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn
import FBSDKLoginKit

class LoginViewController: UIViewController, GIDSignInUIDelegate, FBSDKLoginButtonDelegate {
    
    @IBOutlet weak var GoogleSignInButton: UIButton!
    @IBOutlet weak var fbLoginButton: FBSDKLoginButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(sender:)))
        GoogleSignInButton.addGestureRecognizer(tap)
        
        fbLoginButton.delegate = self
    }
    override func viewDidAppear(_ animated: Bool) {
//        let homeViewController = storyboard?.instantiateViewController(withIdentifier: "HomeViewController") as! HomeViewController
//        if (FBSDKAccessToken.current() != nil) {
//            navigationController?.pushViewController(homeViewController, animated: true)
//        }
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        // ...
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer? = nil) {
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().signIn()
    }
    @IBAction func loginWithFacebook(_ sender: UIButton) {
        let LoginManager = FBSDKLoginManager()
        
        LoginManager.logIn(withReadPermissions: ["public_profile", "email"], from: self) { (result, error) in
            
            if let error = error {
                print("Failed to login: \(error.localizedDescription)")
                return
            }
            guard let accessToken = FBSDKAccessToken.current() else {
                print("Failed to get access token")
                return
            }
            let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.tokenString)
            // Perform login by calling Firebase APIs
            Auth.auth().signIn(with: credential, completion: { (user, error) in
                if let error = error {
                    print("Login error: \(error.localizedDescription)")
                    let alertController = UIAlertController(title: "Login Error", message: error.localizedDescription, preferredStyle: .alert)
                    let okayAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alertController.addAction(okayAction)
                    self.present(alertController, animated: true, completion: nil)
                    return
                }
                let homeViewController = self.storyboard?.instantiateViewController(withIdentifier: "HomeViewController") as! HomeViewController
                self.navigationController?.pushViewController(homeViewController, animated: true)
            })
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        //do nothing pls
    }
}
