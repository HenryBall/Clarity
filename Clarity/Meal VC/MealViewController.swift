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

    let db = Firestore.firestore()
    let storage = Storage.storage()
    var ingredientDB : CollectionReference!
    var invertedIndex : CollectionReference!
    
    let today = Date()
    let formatter = DateFormatter()
    var ingredientsList = [String]()
    var day : DocumentReference!
    
    // Camera stuff
    let imagePicker = UIImagePickerController()
    let session = URLSession.shared
    
    // NLP stuff
    let tagger = NSLinguisticTagger(tagSchemes:[.tokenType, .language, .lexicalClass, .nameType, .lemma], options: 0)
    let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
    
    var googleAPIKey = "AIzaSyBTCGyrnH7vNYfWN8bogL7hcwrF_xv1its"
    
    var googleURL: URL {
        return URL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(googleAPIKey)")!
    }
    
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
        ingredientDB = db.collection("water-footprint-data")
        invertedIndex = db.collection("water-data-inverted-index")
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .camera
        setBannerImage()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        queryIngredients()
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
                    print(foodInMeal)
                }
                
                self.ingredientsInMeal = []
                
                for i in foodInMeal{
                    let ing = Ingredient(name: i["name"] as! String, waterData: i["total"] as! Double, description: "", servingSize: 0.0, category: "", source: "")
                    self.ingredientsInMeal.append(ing)
                    //self.tableView.reloadData()
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
        setView(hidden: true, angle: -CGFloat.pi)
        present(imagePicker, animated: true, completion: nil)
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
}

/*************************************** Scanning Stuff ***************************************/
extension MealViewController {
    
    func tokenizeText(for text: String) -> [String] {
        var arr = [String]()
        tagger.string = text
        let range = NSRange(location: 0, length: text.utf16.count)
        if #available(iOS 11.0, *) {
            tagger.enumerateTags(in: range, unit: .word, scheme: .tokenType, options: options) { tag, tokenRange, stop in
                let word = (text as NSString).substring(with: tokenRange)
                //let lemma = lemmatize(for: word)
                arr.append(word)
            }
            return arr
        } else {
            return []
        }
    }
    
    /*func lemmatize(for text: String) -> String {
        tagger.string = text
        var  lemm : String = ""
        let range = NSRange(location:0, length: text.utf16.count)
        if #available(iOS 11.0, *) {
            tagger.enumerateTags(in: range, unit: .word, scheme: .lemma, options: options) { tag, tokenRange, stop in
                if let lemma = tag?.rawValue {
                    lemm = lemma
                    return lemm
                    print(lemm)
                } else {
                    return ""
                }
            }
        } else {
            return ""
        }
    }*/
    
    func doTextProcessing (text: JSON) {
        if text != JSON.null{
            ingredientsList = text.string!.lowercased().components(separatedBy: ", ")
            for ingredient in ingredientsList {
                matchIngredient (name: ingredient)
            }
        }else{
            print("Sorry, the ingredients for this item are unavailable")
        }
    }
    
    func matchIngredient (name: String) {
        let arr = tokenizeText (for: name)
        var dic : Dictionary<String, DocumentSnapshot> = [String : DocumentSnapshot]()
        print(arr)
        let group = DispatchGroup()
        
        for word in arr {
            group.enter()
            invertedIndex.document(word).getDocument { (document, error) in
                if let document = document, document.exists {
                    let candidentIngredients = document.get("documents") as! [DocumentReference]
                    for ingredient in candidentIngredients {
                        group.enter()
                        ingredient.getDocument(completion: { (doc, err) in
                            dic[ingredient.documentID] = doc
                            group.leave()
                        })
                    }
                } else {
                    print("Document does not exist")
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            var maxScore = 0.0
            var matchedItem : String!
            
            if !dic.isEmpty {
                for (id, snapshot) in dic {
                    
                    let termScores = snapshot.data()!["term_scores"] as! [String : Double]
                    var sum = 0.0
                    
                    for (_, num) in termScores {
                        sum += num
                    }
                    
                    if (sum > maxScore) {
                        maxScore = sum
                        matchedItem = id
                    }
                }
                
                var water = 0.0
                var refArray = [DocumentReference]()
                
                let matchedRef = self.ingredientDB.document(matchedItem!)
                matchedRef.getDocument(completion: { (doc, err) in
                    water = doc?.data()!["gallons_water"] as! Double
                    let ingr = Ingredient(document: doc!)
                    self.ingredientsInMeal.append(ingr)
                    for i in self.ingredientsInMeal{
                        let ref = self.db.document("water-footprint-data/" + i.name.capitalized)
                        refArray.append(ref)
                    }
                    self.waterInMeal = self.waterInMeal + water
                    self.day.setData([self.mealType + "_total" : self.waterInMeal], options: SetOptions.merge())
                    self.day.setData([self.mealType : refArray], options: SetOptions.merge())
                    self.gallonsInMeal.text = String(Int(self.waterInMeal))
                    self.tableView.reloadData()
                })
            }
        }
    }
    
    func analyzeResults(_ dataToParse: Data) {
        
        // Update UI on the main thread
        DispatchQueue.main.async(execute: {
            let json = JSON(data: dataToParse)
            let ingredientSelector = json["responses"][0]["textAnnotations"][0]["description"]
            
            self.doTextProcessing(text: ingredientSelector)
        })
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            // Base64 encode the image and create the request
            let binaryImageData = base64EncodeImage(pickedImage)
            createRequest(with: binaryImageData)
        }
        
        dismiss(animated: true, completion: nil)
        if let destination = self.navigationController?.viewControllers[1] {
            self.navigationController?.popToViewController(destination, animated: true)
        }
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
