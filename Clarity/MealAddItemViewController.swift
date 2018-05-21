//
//  MealAddItemViewController.swift
//  Clarity
//
//  Created by Celine Pena on 5/14/18.
//  Copyright © 2018 Robert. All rights reserved.
//

import UIKit

class MealAddItemViewController: UIViewController {

    var mealType: String!
    var ingredientsInMeal = [Ingredient]()
    @IBOutlet weak var bannerImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setBanner()
    }
    
    func setBanner(){
        switch mealType {
        case "breakfast":
            bannerImage.image = #imageLiteral(resourceName: "breakfastBanner")
        case "lunch":
            bannerImage.image = #imageLiteral(resourceName: "lunchBanner")
        case "dinner":
            bannerImage.image = #imageLiteral(resourceName: "dinnerBanner")
        case "snacks":
            bannerImage.image = #imageLiteral(resourceName: "snacksBanner")
        default:
            print("error")
        }
    }

    @IBAction func backTapped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func addFromDatabase(_ sender: UIButton) {
        let destination = storyboard?.instantiateViewController(withIdentifier: "AddFromDatabase") as! AddFromDatabaseViewController
        destination.mealType = mealType
        destination.ingredientsInMeal = ingredientsInMeal
        navigationController?.pushViewController(destination, animated: true)
    }
    
    @IBAction func search(_ sender: UIButton) {
        let destination = storyboard?.instantiateViewController(withIdentifier: "searchViewController") as! searchViewController
        destination.mealType = mealType
        navigationController?.pushViewController(destination, animated: true)
    }
    
}
