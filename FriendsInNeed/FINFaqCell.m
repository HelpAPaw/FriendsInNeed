//
//  FINFaqCell.m
//  FriendsInNeed
//
//  Created by Milen on 17/12/16.
//  Copyright © 2016 Milen. All rights reserved.
//

#import "FINFaqCell.h"

@interface FINFaqCell ()
@property (weak, nonatomic) IBOutlet UILabel *questionLabel;
@property (weak, nonatomic) IBOutlet UILabel *answerLabel;

@end

@implementation FINFaqCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setQuestion:(NSString *)question {
    _questionLabel.text = question;
    [_questionLabel sizeToFit];
}

- (void)setAnswer:(NSString *)answer {
    _answerLabel.text = answer;
    [_answerLabel sizeToFit];
}

@end
