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
    
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var userWaterGoal: UITextField!
    @IBOutlet weak var backBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboard()
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
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        scrollView.setContentOffset(CGPoint(x:0, y: 190), animated: true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        scrollView.setContentOffset(CGPoint(x:0, y:-20), animated: true)
    }
    @IBAction func logoutButtunPressed(_ sender: Any) {
        GIDSignIn.sharedInstance().signOut()
        let s = UIStoryboard(name: "Main", bundle: nil)
        let loginViewController = s.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
        self.navigationController?.viewControllers = [loginViewController]
    }
}

extension UIViewController {
    func hideKeyboard() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(UIViewController.dismissKeyboard))
        
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
