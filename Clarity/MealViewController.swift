//
//  MealViewController.swift
//  Clarity
//
//  Created by Henry Ball on 5/14/18.
//  Copyright © 2018 Robert. All rights reserved.
//

import UIKit

class MealViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var selectedOption: Int!
    @IBOutlet weak var bannerImage: UIImageView!
    @IBOutlet weak var gallonsInMeal: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
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
    @IBAction func addTapped(_ sender: UIButton) {
        let destination = self.storyboard?.instantiateViewController(withIdentifier: "MealAddItemViewController") as! MealAddItemViewController
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "IngredientCell") as! IngredientCell
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableViewHeight.constant = 10*60.0
        return 10
    }
}
