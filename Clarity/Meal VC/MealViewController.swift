//
//  MealViewController.swift
//  Clarity
//
//  Created by Henry Ball on 5/14/18.
//  Copyright © 2018 Robert. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import SDWebImage
import FirebaseStorageUI
import GoogleSignIn
import SwiftyJSON

class MealViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var loadingScreenShouldBeActive = false
    
    @IBOutlet weak var bannerImageTopConstraint: NSLayoutConstraint!
    let db = Firestore.firestore()
    let storage = Storage.storage()
    var ingredientDB : CollectionReference!
    var invertedIndex : CollectionReference!
    
    let today = Date()
    let formatter = DateFormatter()
    var ingredientsList = [String]()
    var day : DocumentReference!
    var spinner : SpinnerView!
    
    @IBOutlet weak var addButton: UIButton!
    // Camera stuff
    let imagePicker = UIImagePickerController()
    let session = URLSession.shared
    
    var googleAPIKey = "AIzaSyAzRUSHeNGqtwILEr098EODn14I83j-CQI"
    
    var googleURL: URL {
        return URL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(googleAPIKey)")!
    }
    
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var closeButton: UIButton!
    var mealType: String!
    @IBOutlet weak var bannerImage: UIImageView!
    @IBOutlet weak var gallonsInMeal: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!

    var ingredientsInMeal = [Ingredient]()

    var waterInMeal : Double! = 0.0
    var itemsInMeal = [Food]()
    
    @IBOutlet weak var addIngredientsView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        formatter.timeStyle = .none
        formatter.dateStyle = .long
        formatter.string(from: today)
        day = db.collection("users").document(defaults.string(forKey: "user_id")!).collection("meals").document(formatter.string(from: today))
        
        tableView.delegate = self
        tableView.dataSource = self
        
        setBannerImage()
        
        let rect = CGRect(x: loadingView.bounds.width/2-40, y: loadingView.bounds.height/2-50, width: 75, height: 75)
        spinner = SpinnerView(frame: rect)
        loadingView.addSubview(spinner)
        spinner.isHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        queryIngredients()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if loadingScreenShouldBeActive {
            loadingView.isHidden = false
        } else {
            loadingView.isHidden = true
        }
    }
    
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
    
    func queryIngredients() {
        
        var ingredientReferences = [DocumentReference]()
        var foodInMeal = [[String : Any]]()
        
        day.getDocument { (document, error) in
            if(document?.exists)!{
                //get ingredients
                if(document?.data()?.keys.contains(self.mealType))!{
                    ingredientReferences = document?.data()![self.mealType] as! [DocumentReference]
                }
                
                if(document?.data()?.keys.contains(self.mealType + "_total"))!{
                    self.waterInMeal = document?.data()![self.mealType + "_total"] as! Double
                    self.gallonsInMeal.text = String(Int(self.waterInMeal))
                }
                
                if(document?.data()?.keys.contains(self.mealType + "-meals"))!{
                    foodInMeal = document?.data()![self.mealType + "-meals"] as! [[String : Any]]
                }
                
                self.ingredientsInMeal = []
                
                for i in foodInMeal{
                    let ing = Ingredient(name: i["name"] as! String, waterData: i["total"] as! Double, description: "The water footprint for this item is based on the water footprint for the average serving size of each ingredient. The actual number may be higher or lower depending on how much of each ingredient is actually in this item.", servingSize: 0.0, category: "", source: "")
                    self.ingredientsInMeal.append(ing)
                }
                
                for ref in ingredientReferences {
                    ref.getDocument { (document, error) in
                        if let document = document {
                            self.ingredientsInMeal.append(Ingredient(document: document))
                            self.tableView.reloadData()
                        } else {
                            print("Document does not exist")
                        }
                    }
                }
            } else {
                print("No ingredients")
            }
        }
    }
    
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
    
    @IBAction func searchTapped(_ sender: UIButton) {
        let destination = storyboard?.instantiateViewController(withIdentifier: "searchViewController") as! searchViewController
        destination.mealType = mealType
        setView(hidden: true, angle: -CGFloat.pi)
        navigationController?.pushViewController(destination, animated: true)
    }
    
    @IBAction func closeTapped(_ sender: UIButton) {
        setView(hidden: true, angle: -CGFloat.pi)
    }
    
    func setView(hidden: Bool, angle: CGFloat) {
        UIView.transition(with: addIngredientsView, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.addIngredientsView.isHidden = hidden
            self.closeButton.transform = CGAffineTransform(rotationAngle: angle / 4.0)
        }, completion: nil)
    }
    
    @IBAction func firestoreTapped(_ sender: UIButton) {
        let destination = storyboard?.instantiateViewController(withIdentifier: "AddFromDatabase") as! AddFromDatabaseViewController
        destination.mealType = mealType
        destination.ingredientsInMeal = ingredientsInMeal
        setView(hidden: true, angle: -CGFloat.pi)
        navigationController?.pushViewController(destination, animated: true)
    }
    
    @IBAction func backTapped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func addTapped(_ sender: UIButton) {
        setView(hidden: false, angle: CGFloat.pi)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let destination = storyboard?.instantiateViewController(withIdentifier: "IngredientsDetailsViewController") as! IngredientsDetailsViewController
        destination.ingredientToShow = ingredientsInMeal[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        navigationController?.pushViewController(destination, animated: true)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "IngredientCell") as! IngredientCell
        cell.label.text = ingredientsInMeal[indexPath.row].name.capitalized
        
        cell.gallonsWaterLabel.text = String(Int(ingredientsInMeal[indexPath.row].waterData))
        let imagePath = "food-icons/" + ingredientsInMeal[indexPath.row].name.uppercased() + ".jpg"
        let imageRef = storage.reference().child(imagePath)
        cell.icon.sd_setImage(with: imageRef, placeholderImage: #imageLiteral(resourceName: "Food"))
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableViewHeight.constant = CGFloat(Double(ingredientsInMeal.count)*75.0)
        return ingredientsInMeal.count
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let water = self.ingredientsInMeal[indexPath.row].waterData
            self.waterInMeal = self.waterInMeal - water
            self.gallonsInMeal.text = String(Int(self.waterInMeal))
            self.ingredientsInMeal.remove(at: indexPath.row)
            var refArray = [DocumentReference]()
            for i in self.ingredientsInMeal{
                if(i.source != ""){
                    let ref = self.db.document("water-footprint-data/" + i.name.capitalized)
                    refArray.append(ref)
                }
            }
            self.day.setData([self.mealType : refArray], options: SetOptions.merge())
            self.day.setData([self.mealType + "_total" : self.waterInMeal], options: SetOptions.merge())
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.bannerImage.alpha = ((UIScreen.main.bounds.width * 45/100)-self.scrollView.contentOffset.y)/(UIScreen.main.bounds.width*45/100)
        bannerImageTopConstraint?.constant = min(0, -scrollView.contentOffset.y / 2.0) // only when scrolling down so we never let it be higher than 0
    }
    
    func analyzeResults(_ dataToParse: Data) {
        
        // Update UI on the main thread
        DispatchQueue.main.async(execute: {
            let json = JSON(data: dataToParse)
            let ingredientSelector = json["responses"][0]["textAnnotations"][0]["description"]
            print(json)
            let destination = self.storyboard?.instantiateViewController(withIdentifier: "addScannedItemViewController") as! addScannedItemViewController
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
