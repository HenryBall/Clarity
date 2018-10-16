//
//  IngredientCell.swift
//  Clarity
//
//  Created by Celine Pena on 5/14/18.
//  Copyright © 2018 Robert. All rights reserved.
//

import UIKit

class IngredientCell: UITableViewCell {

    @IBOutlet weak var shadowView: UIView!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var point: UIView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var gallonsWaterLabel: UILabel!
    @IBOutlet weak var gallonsPerServing: UILabel!
    
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
}
