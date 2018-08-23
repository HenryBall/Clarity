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
import SDWebImage
import FirebaseStorageUI
import GoogleSignIn
import SwiftyJSON


/** Displays a list of the ingredients for a specific meal and a total number of gallons for the entire meal
 ## Relevant classes: ##
 - IngredientCell.swift : table view cell to display name, image and total gallons of water for each ingredient
 - MealViewControllerDelegateExtension : Contains all functions handling table view delegate */

class MealViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    /* IBOutlets */
    @IBOutlet weak var bannerImageTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var bannerImage: UIImageView!
    @IBOutlet weak var gallonsInMeal: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var addIngredientsView: UIView!
    
    /* Views */
    var spinner : SpinnerView!
    
    /* Class Globals */
    var loadingScreenShouldBeActive = false
    var mealType: String! //"Breakfast", "Lunch", "Dinner" or "Snacks"
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
        
        //Show date as Month, day
        formatter.timeStyle = .none
        formatter.dateStyle = .long
        formatter.string(from: today)
        
        tableView.keyboardDismissMode = .onDrag
        
        //var day holds a reference to today's meal
        day = db.collection("users").document(defaults.string(forKey: "user_id")!).collection("meals").document(formatter.string(from: today))
        
        tableView.delegate = self
        tableView.dataSource = self
        
        setBannerImage()
        
        let rect = CGRect(x: loadingView.bounds.width/2-40, y: loadingView.bounds.height/2-50, width: 75, height: 75)
        spinner = SpinnerView(frame: rect)
        loadingView.addSubview(spinner)
        spinner.isHidden = false
    }
    
    /*
    Each time the view is shown again, query in case something has changed
     */
    override func viewDidAppear(_ animated: Bool) {
        queryIngredients()
    }
    
    /*
     - If the user scans an item, show the loading screen
     */
    override func viewWillAppear(_ animated: Bool) {
        loadingView.isHidden = !loadingScreenShouldBeActive
    }
    
    /**
     Set the header image based on the meal type
     */
    func setBannerImage(){
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
    
    /**
     Called when the user selects one of the buttons on the addIngredientsView.
     Either hides or shows the view and rotates the "x" button
     - Parameter hidden: hide or show addIngredientsView
     - Parameter angle: either pi or -pi, based on whether hiding or showing view */
    func setView(hidden: Bool, angle: CGFloat) {
        UIView.transition(with: addIngredientsView, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.addIngredientsView.isHidden = hidden
            self.closeButton.transform = CGAffineTransform(rotationAngle: angle / 4.0)
        }, completion: nil)
    }
    
    /**
     Creates parallax scrolling effect over the banner image
     */
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.bannerImage.alpha = ((UIScreen.main.bounds.width * 45/100)-self.scrollView.contentOffset.y)/(UIScreen.main.bounds.width*45/100)
        bannerImageTopConstraint?.constant = min(0, -scrollView.contentOffset.y / 2.0)
    }
    
    // -------------------------------- Queries ----------------------------------------------------------
    /**
     Get the ingredients stored in Firebase for this specific meal.
     1. Put all ingredients into "foodInMeal" array
     2. If the item contains a reference, i.e. is an item in water-footprint-data, queries that reference to get the ingredient data.
     3. If the item is not in our database, get the name, water data and
     4. Save the ingredient as type Ingredient
     5. Append to ingredientsInMeal array
     */
    func queryIngredients(){

        day.getDocument { (document, error) in
            if(document?.exists)!{
                
                //Set the "gallons total" label 
                if let gallonsTotal = document?.data()![self.mealType + "_total"] as? Double {
                    self.gallonsInMeal.text = String(Int(gallonsTotal))
                }
                
                //Put ingredients in ingredientsInMeal array
                if let foodInMeal = document?.data()![self.mealType] as? [[String : Any]] {
                    
                    self.ingredientsInMeal = []
                    
                    for ing in foodInMeal {
                        if let ref = ing["reference"] as? DocumentReference {
                            ref.getDocument { (document, error) in
                                if let document = document {
                                    let ingredient = Ingredient(document: document)
                                    ingredient.quantity = ing["quantity"] as? Int
                                    self.ingredientsInMeal.append(ingredient)
                                } else {
                                    print("Document does not exist")
                                }
                            }
                        } else {
                            let ing = Ingredient(name: ing["name"] as! String, type: ing["type"] as! String, waterData: ing["total"] as! Double, description: "", servingSize: 1, category: "", source: "", quantity: ing["quantity"] as? Int, ingredients: ing["ingredients"] as? [DocumentReference], imageName: (ing["image"] as! String))
                            self.ingredientsInMeal.append(ing)
                        }
                        self.tableView.reloadData()
                    }
                }
            }else{
                print("no ingredients")
            }
        }
    }
    
    //------------------------------------------ IBActions --------------------------------------------------
    
    /**
     When the user presses the "x" button, hides the buttons view
     - Parameter sender: "x" button */
    @IBAction func closeTapped(_ sender: UIButton) {
        setView(hidden: true, angle: -CGFloat.pi)
    }
    
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
        setView(hidden: false, angle: CGFloat.pi)
    }
    
    /**
     When the user presses the "search" option, pushes the search screen onto the navigation stack.
     - Parameter sender: "Search USDA" button */
    @IBAction func searchTapped(_ sender: UIButton) {
        let destination = storyboard?.instantiateViewController(withIdentifier: "searchViewController") as! searchViewController
        destination.mealType = mealType
        destination.ingredientsInMeal = ingredientsInMeal
        setView(hidden: true, angle: -CGFloat.pi)
        navigationController?.pushViewController(destination, animated: true)
    }
    
    /**
     When the user presses the "scan" option, opens the image picker.
     The user must be running iOS 11+. If not, an error message is presented.
     - Parameter sender: "Scan Ingredients" button */
    @IBAction func scanTapped(_ sender: UIButton) {
        if #available(iOS 11.0, *) {
            imagePicker.delegate = self
            imagePicker.allowsEditing = false
            imagePicker.sourceType = .camera
            setView(hidden: true, angle: -CGFloat.pi)
            present(imagePicker, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Oops!", message: "You need iOS 11 to access this feature", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            self.present(alert, animated: true)
        }
    }

    /**
     When the user presses the "Search Ingredients" button, pushes the ingredients screen onto the navigation stack.
     - Parameter sender: "Search Ingredients" button */
    @IBAction func firestoreTapped(_ sender: UIButton) {
        let destination = storyboard?.instantiateViewController(withIdentifier: "AddFromDatabase") as! AddFromDatabaseViewController
        destination.mealType = mealType
        destination.ingredientsInMeal = ingredientsInMeal
        setView(hidden: true, angle: -CGFloat.pi)
        navigationController?.pushViewController(destination, animated: true)
    }
    
    // ------------------------------------- text recognition functions ------------------------------------------------------------
    func analyzeResults(_ dataToParse: Data) {
        DispatchQueue.main.async(execute: {
            let json = JSON(data: dataToParse)
            let ingredientSelector = json["responses"][0]["textAnnotations"][0]["description"]
            let destination = self.storyboard?.instantiateViewController(withIdentifier: "addScannedItemViewController") as! addScannedItemViewController
            destination.ingredientsInMeal = self.ingredientsInMeal
            destination.ingredientsList = ingredientSelector
            destination.mealType = self.mealType
            self.navigationController?.pushViewController(destination, animated: true)
            self.loadingScreenShouldBeActive = false
        })
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            // Base64 encode the image and create the request
            let binaryImageData = base64EncodeImage(pickedImage)
            createRequest(with: binaryImageData)
        }
        
        loadingView.isHidden = false
        loadingScreenShouldBeActive = true
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func resizeImage(_ imageSize: CGSize, image: UIImage) -> Data {
        UIGraphicsBeginImageContext(imageSize)
        image.draw(in: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        let resizedImage = UIImagePNGRepresentation(newImage!)
        UIGraphicsEndImageContext()
        return resizedImage!
    }
}

extension MealViewController {
    func base64EncodeImage(_ image: UIImage) -> String {
        var imagedata = UIImagePNGRepresentation(image)
        
        // Resize the image if it exceeds the 2MB API limit
        if ((imagedata?.count)! > 2097152) {
            let oldSize: CGSize = image.size
            let newSize: CGSize = CGSize(width: 800, height: oldSize.height / oldSize.width * 800)
            imagedata = resizeImage(newSize, image: image)
        }
        
        return imagedata!.base64EncodedString(options: .endLineWithCarriageReturn)
    }
    
    func createRequest(with imageBase64: String) {
        // Create our request URL
        
        var request = URLRequest(url: googleURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(Bundle.main.bundleIdentifier ?? "", forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        
        // Build our API request
        let jsonRequest = [
            "requests": [
                "image": [
                    "content": imageBase64
                ],
                "features": [
                    [
                        "type": "TEXT_DETECTION"
                    ]
                ]
            ]
        ]
        let jsonObject = JSON(jsonRequest)
        
        // Serialize the JSON
        guard let data = try? jsonObject.rawData() else {
            return
        }
        
        request.httpBody = data
        
        // Run the request on a background thread
        DispatchQueue.global().async { self.runRequestOnBackgroundThread(request) }
    }
    
    func runRequestOnBackgroundThread(_ request: URLRequest) {
        // run the request
        
        let task: URLSessionDataTask = session.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "")
                return
            }
            
            self.analyzeResults(data)
        }
        
        task.resume()
    }
}
