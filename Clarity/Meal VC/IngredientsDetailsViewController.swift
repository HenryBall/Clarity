//
//  IngredientsDetailsViewController.swift
//  Clarity
//
//  Created by Celine Pena on 5/27/18.
//  Copyright © 2018 Robert. All rights reserved.
//

import UIKit
import FirebaseStorage
import SDWebImage
import FirebaseStorageUI
import Charts

class IngredientsDetailsViewController: UIViewController {
    var ingredientToShow: Ingredient!
    @IBOutlet weak var gallonsWaterLabel: UILabel!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var ingredientDescription: UITextView!
    @IBOutlet weak var compareLabel: UILabel!
    @IBOutlet weak var sourceLabel: UITextView!
    @IBOutlet weak var barChart: BarChartView!
    @IBOutlet weak var servingSizeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        name.text = ingredientToShow.name.capitalized
        gallonsWaterLabel.text = String(Int(ingredientToShow.waterData))
        let imagePath = "food-icons/" + ingredientToShow.name.uppercased() + ".jpg"
        let imageRef = storage.reference().child(imagePath)
        icon.sd_setImage(with: imageRef, placeholderImage: #imageLiteral(resourceName: "Food"))
        ingredientDescription.text = ingredientToShow.description
        if(ingredientToShow.category == "other"){
            compareLabel.text = "How does this compare to other food?"
        }else{
            compareLabel.text = "How does this compare to other " + ingredientToShow.category! + "?"
        }
        
        sourceLabel.text = "Source: " + ingredientToShow.source!
        servingSizeLabel.text = String(ingredientToShow.servingSize!) + " oz"
        
        switch(ingredientToShow.category){
        case "protein":
            updateChartWithData(dataToShow: proteins)
        case "fruit":
            updateChartWithData(dataToShow: fruits)
        case "vegetable":
            updateChartWithData(dataToShow: vegetables)
        case "dairy":
            updateChartWithData(dataToShow: dairy)
        case "drinks":
            updateChartWithData(dataToShow: drinks)
        case "other":
            updateChartWithData(dataToShow: other)
        default:
            print("other")
        }
    }

    func updateChartWithData(dataToShow: [Ingredient]) {
        var data = dataToShow
        data.sort(by: { $0.waterData < $1.waterData })
        var dataEntries: [BarChartDataEntry] = []
        
        for i in 0..<dataToShow.count {
            let dataEntry = BarChartDataEntry(x: Double(i), y: Double(data[i].waterData))
            dataEntries.append(dataEntry)
        }
        let chartDataSet = BarChartDataSet(values: dataEntries, label: "Gallons of water per serving")
        let color = UIColor(red: 0/255, green: 188/255, blue: 205/255, alpha: 1.0)
        var colors = Array(repeating: color, count: data.count)
        
        if let index = data.index(where: { $0.name == ingredientToShow.name }) {
            colors[index] = UIColor(red: 1/255, green: 225/255, blue: 180/255, alpha: 1.0)
        }
    
        chartDataSet.colors = colors
        chartDataSet.drawValuesEnabled = false
        let chartData = BarChartData(dataSet: chartDataSet)
        barChart.chartDescription?.text = ""
        barChart.isUserInteractionEnabled = false
        barChart.xAxis.drawGridLinesEnabled = false
        barChart.rightAxis.drawGridLinesEnabled = false
        barChart.leftAxis.drawLabelsEnabled = false
        barChart.leftAxis.drawGridLinesEnabled = false
        barChart.noDataTextColor = UIColor.black
        barChart.xAxis.drawLabelsEnabled = false
        barChart.xAxis.axisLineColor = UIColor.clear
        barChart.drawValueAboveBarEnabled = false
        barChart.leftAxis.drawAxisLineEnabled = false
        barChart.rightAxis.drawAxisLineEnabled = false
        barChart.drawBordersEnabled = false
        barChart.legend.enabled = false
        barChart.data = chartData
    }
    
    @IBAction func backTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
}
