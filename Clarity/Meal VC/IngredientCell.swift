//
//  IngredientCell.swift
//  Clarity
//
//  Created by Celine Pena on 5/14/18.
//  Copyright © 2018 Robert. All rights reserved.
//

import UIKit

class IngredientCell: UITableViewCell {

    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var gallonsWaterLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
