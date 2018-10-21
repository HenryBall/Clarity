//
//  searchCell.swift
//  Clarity
//
//  Created by Celine Pena on 5/20/18.
//  Copyright © 2018 Robert. All rights reserved.
//

import UIKit

class SearchCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var quantityTextField: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // update UI
        accessoryType = selected ? .checkmark : .none
    }
}
