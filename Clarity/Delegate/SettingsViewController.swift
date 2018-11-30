//
//  SettingsViewController.swift
//  Clarity
//
//  Created by Celine Pena on 5/14/18.
//  Copyright © 2018 Robert. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

class SettingsViewController: UIViewController, UITextFieldDelegate {

    let defaults                        = UserDefaults.standard
    let db                              = Firestore.firestore()
    let storage                         = Storage.storage()
    
    @IBOutlet weak var logoutButton     : UIButton!
    @IBOutlet weak var userWaterGoal    : UITextField!
    @IBOutlet weak var backBtn          : UIButton!
    @IBOutlet weak var saveBtn          : UIButton!
    
    override func viewWillAppear(_ animated: Bool) {
        swipeToHideKeyboard()
        saveBtn.isHidden = true
        logoutButton.isHidden = true
        
        userRef.getDocument { (document, error) in
            if let document = document {
                if let waterGoal = document.data()?["water_goal"] {
                    let goalAsDouble = waterGoal as! Double
                    self.userWaterGoal.text = String(Int((goalAsDouble)))
                    self.saveBtn.isHidden = true
                    self.logoutButton.isHidden = false
                } else {
                    self.backBtn.isHidden = true
                    self.saveBtn.isHidden = false
                    self.logoutButton.isHidden = true
                }
            } else {
                print("This user does not exist in the database")
            }
        }
    }

    @IBAction func backBtnPressed(_ sender: Any) {
        if (userWaterGoal.text != "") {
            userRef.setData(["water_goal": Double(userWaterGoal.text!) as Any], options: SetOptions.merge())
            self.navigationController?.popViewController(animated: true)
        } else {
            let alert = UIAlertController(title: "Oops!", message: "Please enter a water goal", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            self.present(alert, animated: true)
        }
        self.navigationController?.popViewController(animated: true)
    }

    
    @IBAction func saveBtnPressed(_ sender: Any) {
        if (userWaterGoal.text != "") {
            userRef.setData(["water_goal": Double(userWaterGoal.text!) as Any], options: SetOptions.merge())
            self.navigationController?.popViewController(animated: true)
        } else {
            let alert = UIAlertController(title: "Oops!", message: "Please enter a water goal", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            self.present(alert, animated: true)
        }
        let s = UIStoryboard(name: "Main", bundle: nil)
        let homeViewController = s.instantiateViewController(withIdentifier: "HomeViewController") as! HomeViewController
        navigationController?.viewControllers = [homeViewController]
    }
    
    @IBAction func logoutButtunPressed(_ sender: Any) {
        GIDSignIn.sharedInstance().signOut()
        let s = UIStoryboard(name: "Main", bundle: nil)
        let loginViewController = s.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
        self.navigationController?.viewControllers = [loginViewController]
    }
}

extension UIViewController {
    func tapToHideKeyboard() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(UIViewController.dismissKeyboard))
        
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension UIViewController {
    func swipeToHideKeyboard() {
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        swipeDown.direction = UISwipeGestureRecognizerDirection.down
        self.view.addGestureRecognizer(swipeDown)
    }
}
