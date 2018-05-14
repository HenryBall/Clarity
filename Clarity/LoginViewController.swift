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

class LoginViewController: UIViewController, GIDSignInUIDelegate {
    
    @IBOutlet weak var GoogleSignInButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(sender:)))
        GoogleSignInButton.addGestureRecognizer(tap)
        // Do any additional setup after loading the view.
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer? = nil) {
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().signIn()
    }

}
