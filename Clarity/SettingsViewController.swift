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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboard()
        let user = db.collection("users").document(defaults.string(forKey: "user_id")!)
        user.getDocument { (document, error) in
            if let document = document, document.exists {
                
                self.userWaterGoal.text = String(Int((document.data()!["water_goal"] as! Double)))
            } else {
                print("Document does not exist")
            }
        }
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func backBtnPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onSaveSettingsPressed(_ sender: Any) {
        let user = db.collection("users").document(defaults.string(forKey: "user_id")!)
        
        if (userWaterGoal.text != "") {
            
            user.setData(["water_goal": Double(userWaterGoal.text!)], options: SetOptions.merge())
            
        } else {
            print ("You must fill all fields")
            let alert = UIAlertController(title: "All information not filled in", message: "Please make sure to fill out all of your information", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
            
            self.present(alert, animated: true)
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        scrollView.setContentOffset(CGPoint(x:0, y:200), animated: true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        scrollView.setContentOffset(CGPoint(x:0, y:0), animated: true)
    }
    @IBAction func logoutButtunPressed(_ sender: Any) {
        GIDSignIn.sharedInstance().signOut()
        let s = UIStoryboard(name: "Main", bundle: nil)
        let loginViewController = s.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
        self.navigationController?.viewControllers = [loginViewController]
    }
}
