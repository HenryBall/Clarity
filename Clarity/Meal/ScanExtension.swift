//
//  ScanExtension.swift
//  Clarity
//
//  Created by henry on 11/9/18.
//  Copyright © 2018 Robert. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import FirebaseStorageUI
import GoogleSignIn
import SwiftyJSON


// ** UNUSED ** extension to handle google api request and JSON parsing for ingredient scanning
extension MealViewController {
    func analyzeResults(_ dataToParse: Data) {
        DispatchQueue.main.async(execute: {
            let json = JSON(data: dataToParse)
            let ingredientSelector = json["responses"][0]["textAnnotations"][0]["description"]
            let destination = self.storyboard?.instantiateViewController(withIdentifier: "addScannedItemViewController") as! AddScannedItemViewController
            destination.ingredientsInMeal = self.ingredientsInMeal
            destination.ingredientsList = ingredientSelector
            destination.mealType = self.mealType
            self.navigationController?.pushViewController(destination, animated: true)
            self.loadingScreenShouldBeActive = false
        })
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            let binaryImageData = base64EncodeImage(pickedImage)
            createRequest(with: binaryImageData)
        }
        loadingView.alpha = 1.0
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

    func base64EncodeImage(_ image: UIImage) -> String {
        var imagedata = UIImagePNGRepresentation(image)
        if ((imagedata?.count)! > 2097152) {
            let oldSize: CGSize = image.size
            let newSize: CGSize = CGSize(width: 800, height: oldSize.height / oldSize.width * 800)
            imagedata = resizeImage(newSize, image: image)
        }
        return imagedata!.base64EncodedString(options: .endLineWithCarriageReturn)
    }
    
    func createRequest(with imageBase64: String) {
        var request = URLRequest(url: googleURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(Bundle.main.bundleIdentifier ?? "", forHTTPHeaderField: "X-Ios-Bundle-Identifier")
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
        guard let data = try? jsonObject.rawData() else {
            return
        }
        request.httpBody = data
        DispatchQueue.global().async { self.runRequestOnBackgroundThread(request) }
    }
    
    func runRequestOnBackgroundThread(_ request: URLRequest) {
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
