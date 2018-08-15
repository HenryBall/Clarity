//
//  scannedItemCell.swift
//  Clarity
//
//  Created by henry on 8/14/18.
//  Copyright © 2018 Robert. All rights reserved.
//

import UIKit

class scannedItemCell: UITableViewCell {

    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var icon: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        accessoryType = selected ? .checkmark : .none
    }
}
