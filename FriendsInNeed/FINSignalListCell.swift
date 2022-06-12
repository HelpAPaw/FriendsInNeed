//
//  FINSignalListCell.swift
//  Help A Paw
//
//  Created by Milen Marinov on 4.06.22.
//  Copyright © 2022 Milen. All rights reserved.
//

import UIKit
import SDWebImage

class FINSignalListCell: UITableViewCell {
    @IBOutlet weak var photoImageView: SDAnimatedImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        photoImageView.layer.cornerRadius = 5.0
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setPhotoUrl(_ url: URL?) {
        photoImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "ic_paw"))
    }
    
    func setTitle(_ title: String) {
        titleLabel.text = title
    }
    
    func setDate(_ date: String) {
        dateLabel.text = date
    }
    
}
