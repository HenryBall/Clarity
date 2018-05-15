//
//  GettingStartedViewController.swift
//  Clarity
//
//  Created by Henry Ball on 5/14/18.
//  Copyright © 2018 Robert. All rights reserved.
//

import UIKit
import Firebase

class GettingStartedViewController: UIViewController {

    let defaults = UserDefaults.standard
    let db = Firestore.firestore()
    let storage = Storage.storage()
    
    @IBOutlet weak var userName: UITextField!
    @IBOutlet weak var userLocation: UITextField!
    @IBOutlet weak var waterGoal: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboard()
    }
    
    @IBAction func getStartedTapped(_ sender: Any) {
        let user = db.collection("users").document(defaults.string(forKey: "user_id")!)
        
        if (userName.text != nil && userLocation.text != nil && waterGoal.text != nil) {
            user.setData(["name": userName.text!], options: SetOptions.merge())
            user.setData(["location": userLocation.text!], options: SetOptions.merge())
            user.setData(["waterGoal": waterGoal.text!], options: SetOptions.merge())
            
            let destination = self.storyboard?.instantiateViewController(withIdentifier: "HomeViewController") as! HomeViewController
            self.navigationController?.pushViewController(destination, animated: true)
        } else {
            print ("You must fill all fields")
        }
    }
    
}

extension UIViewController
{
    func hideKeyboard()
    {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(UIViewController.dismissKeyboard))
        
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard()
    {
        view.endEditing(true)
    }
}
