//
//  MealAddItemViewController.swift
//  Clarity
//
//  Created by Celine Pena on 5/14/18.
//  Copyright © 2018 Robert. All rights reserved.
//

import UIKit
import Firebase
import SwiftyJSON

class MealAddItemViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let db = Firestore.firestore()
    let storage = Storage.storage()
    var ingredientDB : CollectionReference!
    var invertedIndex : CollectionReference!
    
    let today = Date()
    let formatter = DateFormatter()
    var mealType: String!
    var ingredientsList = [String]()
    var ingredientsInMeal = [Ingredient]()
    
    // Camera stuff
    let imagePicker = UIImagePickerController()
    let session = URLSession.shared
    
    // NLP stuff
    let tagger = NSLinguisticTagger(tagSchemes:[.tokenType, .language, .lexicalClass, .nameType, .lemma], options: 0)
    let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var labelResults: UITextView!
    @IBOutlet weak var bannerImage: UIImageView!
    
    var googleAPIKey = "AIzaSyBTCGyrnH7vNYfWN8bogL7hcwrF_xv1its"
    
    var googleURL: URL {
        return URL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(googleAPIKey)")!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setBanner()
        
        formatter.timeStyle = .none
        formatter.dateStyle = .long
        formatter.string(from: today)
        
        ingredientDB = db.collection("water-footprint-data")
        invertedIndex = db.collection("water-data-inverted-index")
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .camera
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
    
    @IBAction func scanTapped(_ sender: Any) {
        present(imagePicker, animated: true, completion: nil)
    }
}

extension MealAddItemViewController {
    
    func tokenizeText(for text: String) -> [String] {
        var arr = [String]()
        tagger.string = text
        let range = NSRange(location: 0, length: text.utf16.count)
        if #available(iOS 11.0, *) {
            tagger.enumerateTags(in: range, unit: .word, scheme: .tokenType, options: options) { tag, tokenRange, stop in
                let word = (text as NSString).substring(with: tokenRange)
                arr.append(word)
            }
            return arr
        } else {
            return []
        }
    }
    
    func doTextProcessing (text: JSON) {
        if text != JSON.null{
            ingredientsList = text.string!.lowercased().components(separatedBy: ", ")
            for ingredient in ingredientsList {
                ingredientsList.append(ingredient)
                matchIngredient (name: ingredient)
            }
        }else{
            print("Sorry, the ingredients for this item are unavailable")
        }
    }
    
    func matchIngredient (name: String) {
        let arr = tokenizeText (for: name)
        var dic : Dictionary<String, DocumentSnapshot> = [String : DocumentSnapshot]()
        
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

                let day = self.db.collection("users").document(defaults.string(forKey: "user_id")!).collection("meals").document(self.formatter.string(from: self.today))
                var refArray = [DocumentReference]()
                var water = 0.0
                let matchedRef = self.ingredientDB.document(matchedItem!)
                matchedRef.getDocument(completion: { (doc, err) in
                    water = doc?.data()!["gallons_water"] as! Double
                    for i in self.ingredientsInMeal{
                        let ref = self.db.document("water-footprint-data/" + i.name.capitalized)
                        refArray.append(ref)
                    }
                    refArray.append(matchedRef)
                    let total = (self.ingredientsInMeal.map({$0.waterData}).reduce(0, +)) + water
                    day.setData([self.mealType + "_total" : total], options: SetOptions.merge())
                    day.setData([self.mealType : refArray], options: SetOptions.merge())
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

extension MealAddItemViewController {
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
