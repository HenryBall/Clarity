//
//  MealViewController.swift
//  Clarity
//
//  Created by Henry Ball on 5/14/18.
//  Copyright © 2018 Clarity. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import FirebaseStorageUI
import GoogleSignIn
import SwiftyJSON


/** Displays a list of the ingredients for a specific meal and a total number of gallons for the entire meal
 ## Relevant classes: ##
 - IngredientCell.swift : table view cell to display name, image and total gallons of water for each ingredient
 - MealViewControllerDelegateExtension : Contains all functions handling table view delegate */

class MealViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    /* IBOutlets */
    @IBOutlet weak var mealName: UILabel!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var bannerImage: UIImageView!
    @IBOutlet weak var gallonsInMeal: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addIngredientsView: UIView!
    
    /* Views */
    var spinner : SpinnerView!
    
    /* Class Globals */
    var loadingScreenShouldBeActive = false
    var mealType: String!
    let db = Firestore.firestore()
    let storage = Storage.storage()
    let today = Date()
    let formatter = DateFormatter()
    var ingredientsList = [String]()
    var day : DocumentReference!
    var ingredientsInMeal = [Ingredient]()
    let imagePicker = UIImagePickerController()
    let session = URLSession.shared
    var googleAPIKey = "AIzaSyAzRUSHeNGqtwILEr098EODn14I83j-CQI"
    var googleURL: URL {
        return URL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(googleAPIKey)")!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        formatter.timeStyle = .none
        formatter.dateStyle = .long
        formatter.string(from: today)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .onDrag
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        day = db.collection("users").document(defaults.string(forKey: "user_id")!).collection("meals").document(formatter.string(from: today))
        setBannerImage(mealType: mealType, imageView: bannerImage, label: mealName)
        initSpinner()
    }
    
    /**
     Each time the view is shown again, query in case something has changed */
    override func viewDidAppear(_ animated: Bool) {
        queryIngredients()
    }
    
    /**
     If the user scans an item, show the loading screen */
    override func viewWillAppear(_ animated: Bool) {
        loadingView.isHidden = !loadingScreenShouldBeActive
    }
    
    /** UNUSED **
     Initialize loading view with spinner */
    func initSpinner() {
        let rect = CGRect(x: loadingView.bounds.width/2-40, y: loadingView.bounds.height/2-50, width: 75, height: 75)
        spinner = SpinnerView(frame: rect)
        loadingView.addSubview(spinner)
        spinner.isHidden = false
    }
    
    /**
     Called when the user selects one of the buttons on the addIngredientsView.
     Either hides or shows the view and rotates the "x" button
     - Parameter hidden: hide or show addIngredientsView
     - Parameter angle: either pi or -pi, based on whether hiding or showing view */
    func setView(alpha: CGFloat, angle: CGFloat) {
        UIView.animate(withDuration: 0.3, animations: {
            self.addIngredientsView.alpha = alpha
            self.closeButton.transform = CGAffineTransform(rotationAngle: angle / 4.0)
        })
    }
    
    /**
     Creates parallax scrolling effect over the banner image */
    /*func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.bannerImage.alpha = ((UIScreen.main.bounds.width * 45/100)-self.scrollView.contentOffset.y)/(UIScreen.main.bounds.width*45/100)
        bannerImageTopConstraint?.constant = min(0, -scrollView.contentOffset.y / 2.0)
    }*/

    /**
     Get the ingredients stored in Firebase for this specific meal.
     1. Put all ingredients into "foodInMeal" array
     2. If the item contains a reference, i.e. is an item in water-footprint-data, queries that reference to get the ingredient data.
     3. If the item is not in our database, get the name, water data and
     4. Save the ingredient as type Ingredient
     5. Append to ingredientsInMeal array */
    func queryIngredients(){
        day.getDocument { (document, error) in
            if(document?.exists)!{
                if let gallonsTotal = document?.data()![self.mealType + "_total"] as? Double {
                    self.gallonsInMeal.text = String(Int(gallonsTotal)) + " gal"
                } else {
                    self.gallonsInMeal.text = "0 gal"
                }

                if let foodInMeal = document?.data()![self.mealType] as? [[String : Any]] {
                    self.ingredientsInMeal = []
                    for ing in foodInMeal {
                        if let ref = ing["reference"] as? DocumentReference {
                            ref.getDocument { (document, error) in
                                if let document = document {
                                    let ingredient = Ingredient(document: document)
                                    ingredient.quantity = ing["quantity"] as? Int
                                    ingredient.measurement = ing["measure"] as? String
                                    self.ingredientsInMeal.append(ingredient)
                                    self.tableView.reloadData()
                                } else {
                                    print("Document does not exist")
                                }
                            }
                        } else {
                            let ing = Ingredient(name: ing["name"] as! String, type: ing["type"] as! String, waterData: ing["total"] as! Double, description: "", servingSize: 1, category: "", source: "", quantity: ing["quantity"] as? Int, ingredients: ing["ingredients"] as? [DocumentReference], measurement: ing["measure"] as? String)
                            self.ingredientsInMeal.append(ing)
                            self.tableView.reloadData()
                        }
                    }
                }
            }else{
                print("no ingredients")
            }
        }
    }
    
    // ***** IBActions ***** //
    
    /**
     When the user presses the "<" button, returns to the home screen
     - Parameter sender: "<" back button */
    @IBAction func backTapped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    /**
     When the user presses the "+" button, unhides the buttons view to reveal the 3 methods to add ingredients
     - Parameter sender: "+" button */
    @IBAction func addTapped(_ sender: UIButton) {
        //setView(alpha: 1.0, angle: CGFloat.pi)
        let destination = storyboard?.instantiateViewController(withIdentifier: "AddFromDatabase") as! AddFromDatabaseViewController
        destination.mealType = mealType
        destination.ingredientsInMeal = ingredientsInMeal
        setView(alpha: 0.0, angle: -CGFloat.pi)
        navigationController?.pushViewController(destination, animated: true)
    }
    
    /** UNUSED **
     When the user presses the "x" button, hides the buttons view
     - Parameter sender: "x" button */
    @IBAction func closeTapped(_ sender: UIButton) {
        setView(alpha: 0.0, angle: -CGFloat.pi)
    }
    
    /** UNUSED **
     When the user presses the "search" option, pushes the search screen onto the navigation stack.
     - Parameter sender: "Search USDA" button */
    @IBAction func searchTapped(_ sender: UIButton) {
        let destination = storyboard?.instantiateViewController(withIdentifier: "searchViewController") as! SearchViewController
        destination.mealType = mealType
        destination.ingredientsInMeal = ingredientsInMeal
        setView(alpha: 0.0, angle: -CGFloat.pi)
        navigationController?.pushViewController(destination, animated: true)
    }
    
    /** UNUSED **
     When the user presses the "scan" option, opens the image picker.
     The user must be running iOS 11+. If not, an error message is presented.
     - Parameter sender: "Scan Ingredients" button */
    @IBAction func scanTapped(_ sender: UIButton) {
        if #available(iOS 11.0, *) {
            imagePicker.delegate = self
            imagePicker.allowsEditing = false
            imagePicker.sourceType = .camera
            setView(alpha: 0.0, angle: -CGFloat.pi)
            present(imagePicker, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Oops!", message: "You need iOS 11 to access this feature", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            self.present(alert, animated: true)
        }
    }
    
    /** UNUSED **
     When the user presses the "Search Ingredients" button, pushes the ingredients screen onto the navigation stack.
     - Parameter sender: "Search Ingredients" button */
    @IBAction func firestoreTapped(_ sender: UIButton) {
        let destination = storyboard?.instantiateViewController(withIdentifier: "AddFromDatabase") as! AddFromDatabaseViewController
        destination.mealType = mealType
        destination.ingredientsInMeal = ingredientsInMeal
        setView(alpha: 0.0, angle: -CGFloat.pi)
        navigationController?.pushViewController(destination, animated: true)
    }
}

extension UIViewController {
    /** Set the header image based on the meal type */
    func setBannerImage(mealType: String, imageView: UIImageView, label: UILabel){
        switch mealType {
        case "Breakfast":
            view.backgroundColor = UIColor.mealBackgrounds.breakfast
        case "Lunch":
            view.backgroundColor = UIColor.mealBackgrounds.lunch
        case "Dinner":
            view.backgroundColor = UIColor.mealBackgrounds.dinner
        case "Snacks":
            view.backgroundColor = UIColor.mealBackgrounds.snacks
        default:
            print("error")
        }
        
        imageView.image = UIImage(named: mealType)
        label.text = mealType
    }
}
    
