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
    

    @IBOutlet weak var waterGoal: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboard()
    }
    
    @IBAction func getStartedTapped(_ sender: Any) {
        let user = db.collection("users").document(defaults.string(forKey: "user_id")!)
        
        if (waterGoal.text != "") {
            
            user.setData(["water_goal": Double(waterGoal.text!)], options: SetOptions.merge())
            
            let destination = self.storyboard?.instantiateViewController(withIdentifier: "HomeViewController") as! HomeViewController
            self.navigationController?.pushViewController(destination, animated: true)
        } else {
            print ("You must fill all fields")
            let alert = UIAlertController(title: "Water Goal Not Set", message: "Please make sure pick a daily water goal", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
            
            self.present(alert, animated: true)
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
