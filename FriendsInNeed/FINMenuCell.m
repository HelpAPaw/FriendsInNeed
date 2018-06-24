//
//  FINMenuCell.m
//  FriendsInNeed
//
//  Created by Milen on 28/11/16.
//  Copyright © 2016 Milen. All rights reserved.
//

#import "FINMenuCell.h"
#import "FINGlobalConstants.pch"

@interface FINMenuCell ()
@property (weak, nonatomic) IBOutlet UILabel *label;

@end

@implementation FINMenuCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    
    [UIView animateWithDuration:0.3 animations:^{
        if (highlighted)
        {
            self.backgroundColor = [UIColor whiteColor];
            self.label.textColor = kCustomOrange;//[UIColor lightGrayColor];
        }
        else
        {
            self.backgroundColor = kCustomOrange;
            self.label.textColor = [UIColor whiteColor];
        }
    }];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setTitle:(NSString *)title {
    _label.text = title;
}

@end
