//
//  addDatabaseIngredientCell.swift
//  Clarity
//
//  Created by Celine Pena on 5/18/18.
//  Copyright © 2018 Robert. All rights reserved.
//

import UIKit

class addDatabaseIngredientCell: UITableViewCell {
    let grayTextColor = UIColor(red: 117/255, green: 117/255, blue: 117/255, alpha: 1)
    let grayBackgroundColor = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1)
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var count: UITextField!
    @IBOutlet weak var gallonsWaterLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var subtractButton: UIButton!
    @IBOutlet weak var quantityTextField: UITextField!
    @IBOutlet weak var shadowView: UIView!
    @IBOutlet weak var point: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = UIColor.clear
        shadowView.layer.shadowColor = UIColor(red: 218/255, green: 218/255, blue: 218/255, alpha: 1.0).cgColor
        shadowView.layer.shadowOffset = CGSize(width: 1, height: 3)
        shadowView.layer.shadowOpacity = 1.0
        shadowView.layer.shadowRadius = 2.0
        shadowView.layer.masksToBounds = false
        shadowView.layer.shadowPath = UIBezierPath(roundedRect: shadowView.bounds, cornerRadius: 4).cgPath
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        selected ? textToWhite() : textToGray()
    }
    
    func textToWhite() {
        //self.backgroundColor = grayTextColor
        self.shadowView.backgroundColor = grayTextColor
        self.quantityTextField.textColor = UIColor.white
        self.label.textColor = UIColor.white
        self.gallonsWaterLabel.textColor = UIColor.white
        self.addButton.setTitleColor(UIColor.white, for: [])
        self.subtractButton.setTitleColor(UIColor.white, for: [])
    }
    
    func textToGray() {
        //self.backgroundColor = UIColor.white
        self.shadowView.backgroundColor = UIColor.white
        self.quantityTextField.textColor = grayTextColor
        self.label.textColor = grayTextColor
        self.gallonsWaterLabel.textColor = grayTextColor
        self.addButton.setTitleColor(grayTextColor, for: [])
        self.subtractButton.setTitleColor(grayTextColor, for: [])
    }
}
