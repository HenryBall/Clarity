//
//  ViewController.swift
//  Clarity
//
//  Created by Robert on 5/14/18.
//  Copyright © 2018 Robert. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

class HomeViewController: UIViewController {

    let defaults = UserDefaults.standard
    let db = Firestore.firestore()
    
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var userLocation: UILabel!
    
    @IBAction func breakfastTapped(_ sender: Any) {
        let destination = self.storyboard?.instantiateViewController(withIdentifier: "MealViewController") as! MealViewController
        destination.selectedOption = 0
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    @IBAction func lunchTapped(_ sender: Any) {
        let destination = self.storyboard?.instantiateViewController(withIdentifier: "MealViewController") as! MealViewController
        destination.selectedOption = 1
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    @IBAction func dinnerTapped(_ sender: Any) {
        let destination = self.storyboard?.instantiateViewController(withIdentifier: "MealViewController") as! MealViewController
        destination.selectedOption = 2
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    @IBAction func snacksTapped(_ sender: Any) {
        let destination = self.storyboard?.instantiateViewController(withIdentifier: "MealViewController") as! MealViewController
        destination.selectedOption = 3
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    @IBAction func settingsBtnTapped(_ sender: Any) {
          let destination = self.storyboard?.instantiateViewController(withIdentifier: "SettingsViewController") as! SettingsViewController
          self.navigationController?.pushViewController(destination, animated: true)
    }
    
    @IBAction func logoutTapped(_ sender: Any) {
        GIDSignIn.sharedInstance().signOut()
        let s = UIStoryboard(name: "Main", bundle: nil)
        let loginViewController = s.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
        self.navigationController?.viewControllers = [loginViewController]
    }
    
    func fillUserInfo() {
        let user = db.collection("users").document(defaults.string(forKey: "user_id")!)
        
        user.getDocument { (document, error) in
            if let document = document, document.exists {
                self.userName.text = (document.data()!["name"] as! String)
                self.userLocation.text = (document.data()!["location"] as! String)
    
            } else {
                print("Document does not exist")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        fillUserInfo()
    }

}

