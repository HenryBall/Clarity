//
//  addDatabaseIngredientCell.swift
//  Clarity
//
//  Created by Celine Pena on 5/18/18.
//  Copyright © 2018 Robert. All rights reserved.
//

import UIKit

class addDatabaseIngredientCell: UITableViewCell {
    let grayTextColor = UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1)
    let grayBackgroundColor = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1)
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var count: UITextField!
    @IBOutlet weak var gallonsWaterLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var gal: UILabel!
    @IBOutlet weak var subtractButton: UIButton!
    @IBOutlet weak var quantityTextField: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        selected ? textToWhite() : textToGray()
    }
    
    func textToWhite() {
        self.backgroundColor = grayBackgroundColor
        self.label.textColor = UIColor.white
        self.gallonsWaterLabel.textColor = UIColor.white
        self.gal.textColor = UIColor.white
        self.addButton.setTitleColor(UIColor.white, for: [])
        self.subtractButton.setTitleColor(UIColor.white, for: [])
    }
    
    func textToGray() {
        self.backgroundColor = UIColor.white
        self.label.textColor = grayTextColor
        self.gallonsWaterLabel.textColor = grayTextColor
        self.gal.textColor = grayTextColor
        self.addButton.setTitleColor(grayTextColor, for: [])
        self.subtractButton.setTitleColor(grayTextColor, for: [])
    }
}
