//
//  addDatabaseIngredientCell.swift
//  Clarity
//
//  Created by Celine Pena on 5/18/18.
//  Copyright © 2018 Robert. All rights reserved.
//

import UIKit

class addDatabaseIngredientCell: UITableViewCell {

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
}
