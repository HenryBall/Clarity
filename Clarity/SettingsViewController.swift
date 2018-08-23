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

    let defaults = UserDefaults.standard
    let db = Firestore.firestore()
    let storage = Storage.storage()
    
    @IBOutlet weak var saveButton: UIButton!
    
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var userWaterGoal: UITextField!
    @IBOutlet weak var backBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        swipeToHideKeyboard()
        saveButton.layer.borderColor = textColor.cgColor
        logoutButton.layer.borderColor = UIColor.white.cgColor
        let user = db.collection("users").document(defaults.string(forKey: "user_id")!)
        user.getDocument { (document, error) in
            if(document?.exists)!{
                if (document?.data()!["water_goal"]) != nil{
                    self.userWaterGoal.text = String(Int((document?.data()!["water_goal"] as! Double)))
                }else{
                    self.backBtn.isHidden = true
                }
            }else{
                print("This user does not exist in the database")
            }
        }
    }

    @IBAction func backBtnPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onSaveSettingsPressed(_ sender: Any) {
        let user = db.collection("users").document(defaults.string(forKey: "user_id")!)
        
        if (userWaterGoal.text != "") {
            user.setData(["water_goal": Double(userWaterGoal.text!) as Any], options: SetOptions.merge())
            self.navigationController?.popViewController(animated: true)
        } else {
            let alert = UIAlertController(title: "Oops!", message: "Please enter a water goal", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            self.present(alert, animated: true)
        }
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

