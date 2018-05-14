//
//  MealViewController.swift
//  Clarity
//
//  Created by Henry Ball on 5/14/18.
//  Copyright © 2018 Robert. All rights reserved.
//

import UIKit

class MealViewController: UIViewController {

    var selectedOption: Int!
    @IBOutlet weak var bannerImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpView()
        // Do any additional setup after loading the view.
    }
    
    func setUpView(){
        switch selectedOption {
        case 0:
            bannerImage.image = #imageLiteral(resourceName: "breakfastBanner")
        case 1:
            bannerImage.image = #imageLiteral(resourceName: "breakfastBanner")
        case 2:
            bannerImage.image = #imageLiteral(resourceName: "breakfastBanner")
        case 3:
            bannerImage.image = #imageLiteral(resourceName: "breakfastBanner")
        default:
            print("error")
        }
    }
    @IBAction func backTapped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
}
