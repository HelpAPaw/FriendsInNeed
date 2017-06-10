//
//  FINSignalDetailsStatusChangeCommentCell.swift
//  FriendsInNeed
//
//  Created by Milen on 10/06/17.
//  Copyright © 2017 Milen. All rights reserved.
//

import UIKit

class FINSignalDetailsStatusChangeCommentCell: UITableViewCell, FINSignalDetailsCommentCellProtocol {
    @IBOutlet weak var lbCommentLabel: UILabel!
    @IBOutlet weak var lbDateLabel: UILabel!
    @IBOutlet weak var imgStatusImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setCommentText(_ comment: String){
        lbCommentLabel.text = comment
    }
    
    func setDate(_ date: String) {
        lbDateLabel.text = date
    }
    
    func setStatusImage(_ image: UIImage) {
        imgStatusImageView.image = image
    }
    
}
