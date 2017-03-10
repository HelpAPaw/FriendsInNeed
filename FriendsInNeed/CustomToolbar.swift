//
//  CustomToolbar.swift
//  FriendsInNeed
//
//  Created by Mehmed Kadir on 3/10/17.
//  Copyright © 2017 Milen. All rights reserved.
//

import UIKit

class CustomToolbar: UIToolbar {
    /**
     removes the hair line from toolbar
     */
    override func layoutSubviews() {
        for single in self.subviews {
            for s in single.subviews {
                if s.isKind(of: UIImageView.self) && s.frame.height < 2 {
                    s.isHidden = true
                }
            }
        }
    }
}
